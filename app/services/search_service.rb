class SearchService
  def self.call(query)
    new(query).call
  end

  def initialize(query)
    @query = query
  end

  def call
    query_embedding = EmbeddingService.generate(@query)
    return fallback_results if query_embedding.nil?

    products = Product.vector_search(query_embedding, limit: 8)
    return fallback_results if products.empty?

    llm_rerank(products)
  end

  private

  def llm_rerank(products)
    client = OpenAI::Client.new(
      access_token: ENV['GROQ_API_KEY'],
      uri_base: "https://api.groq.com/openai/v1"
    )

    products_json = products.map do |p|
      {
        id:          p.id,
        name:        p.name,
        category:    p.category,
        price:       p.price.to_f,
        description: p.description
      }
    end

    system_prompt = <<~PROMPT
      You are a smart product search assistant for SmartShop, an Indian e-commerce store.
      Given a user search query and a list of products, you must:
      1. Re-rank products by relevance to the query
      2. Detect if the user mentioned a budget (e.g. "under 2000", "below 5000")
      3. For each product add a price note if relevant:
         - "Within your budget" if within budget
         - "Slightly over your budget" if within 20% over
         - null if no budget mentioned

      Return ONLY valid JSON. No explanation, no markdown, no backticks.
      Format:
      {
        "query_understanding": "brief interpretation of what user wants",
        "detected_budget": 2000 or null,
        "results": [
          {
            "id": 1,
            "relevance_reason": "why this product matches",
            "price_note": "Within your budget" or null
          }
        ]
      }
    PROMPT

    response = client.chat(
      parameters: {
        model:       "llama-3.3-70b-versatile",
        temperature: 0.2,
        max_tokens:  1024,
        messages: [
          { role: "system", content: system_prompt },
          { role: "user",   content: "Query: #{@query}\n\nProducts: #{products_json.to_json}" }
        ]
      }
    )

    raw    = response.dig("choices", 0, "message", "content")
    parsed = JSON.parse(raw)

    {
      query_understanding: parsed['query_understanding'],
      detected_budget:     parsed['detected_budget'],
      products: parsed['results'].map do |r|
        product = products.find { |p| p.id == r['id'] }
        next unless product
        {
          id:               product.id,
          name:             product.name,
          category:         product.category,
          price:            product.price.to_f,
          relevance_reason: r['relevance_reason'],
          price_note:       r['price_note']
        }
      end.compact
    }
  rescue => e
    Rails.logger.error "SearchService LLM error: #{e.message}"
    {
      query_understanding: "Showing closest matches for: #{@query}",
      detected_budget:     nil,
      products: products.map do |p|
        {
          id:       p.id,
          name:     p.name,
          category: p.category,
          price:    p.price.to_f,
          relevance_reason: nil,
          price_note:       nil
        }
      end
    }
  end

  def fallback_results
    { query_understanding: @query, detected_budget: nil, products: [] }
  end
end