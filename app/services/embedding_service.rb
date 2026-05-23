class EmbeddingService
  OLLAMA_URL = ENV.fetch('OLLAMA_URL', 'http://localhost:11434')
  MODEL      = "nomic-embed-text"

  def self.generate(text)
    new.generate(text)
  end

  def generate(text)
    uri     = URI("#{OLLAMA_URL}/api/embeddings")
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate({ model: MODEL, prompt: text })

    response = Net::HTTP.start(uri.hostname, uri.port, read_timeout: 30) do |http|
      http.request(request)
    end

    JSON.parse(response.body)['embedding']
  rescue => e
    Rails.logger.error "EmbeddingService error: #{e.message}"
    nil
  end
end