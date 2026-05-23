require 'openai'
require 'json'
require 'dotenv/load'

client = OpenAI::Client.new(
  access_token: ENV['GROQ_API_KEY'],
  uri_base:     "https://api.groq.com/openai/v1"
)

CATEGORIES = [
  "Electronics", "Footwear", "Toys & Games",
  "Books", "Home & Kitchen", "Sports & Fitness",
  "Fashion", "Beauty & Health"
]

TARGET_PER_CATEGORY = 37
all_products = []
output_path  = File.join(__dir__, '../../db/products_generated.json')

puts "🚀 Generating ~300 products across #{CATEGORIES.size} categories...\n\n"

CATEGORIES.each do |category|
  puts "📦 Generating #{TARGET_PER_CATEGORY} products for #{category}..."
  retries = 0

  begin
    response = client.chat(
      parameters: {
        model:       "llama-3.3-70b-versatile",
        temperature: 0.8,
        max_tokens:  3000,
        messages: [{
          role: "user",
          content: <<~PROMPT
            Generate #{TARGET_PER_CATEGORY} realistic Indian e-commerce products for category "#{category}".
            Rules:
            - Realistic brand + model names (mix Indian and international brands)
            - Descriptions 15-25 words, specific and searchable
            - Prices in Indian Rupees, realistic for Indian market
            - Mix of budget, mid-range and premium products
            Return ONLY a valid JSON array. No explanation, no markdown, no backticks.
            Format: [{"name": "...", "description": "...", "category": "#{category}", "price": 1999.00}]
          PROMPT
        }]
      }
    )

    raw   = response.dig("choices", 0, "message", "content")
    clean = raw.gsub(/```json|```/, '').strip
    batch = JSON.parse(clean)
    all_products.concat(batch)
    puts "  ✅ Got #{batch.size} products | Total: #{all_products.size}"
    File.write(output_path, JSON.pretty_generate(all_products))
    puts "  ⏳ Waiting 20s...\n\n"
    sleep(20)

  rescue => e
    retries += 1
    if retries <= 3
      wait = retries * 20
      puts "  ❌ Failed (attempt #{retries}): #{e.message} — waiting #{wait}s\n\n"
      sleep(wait)
      retry
    else
      puts "  ❌ Skipping #{category} after 3 attempts\n\n"
    end
  end
end

puts "✅ Done! #{all_products.size} products saved to db/products_generated.json"