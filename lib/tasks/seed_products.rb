require 'net/http'
require 'json'
require 'pg'
require 'dotenv/load'

DB = PG.connect(
  dbname:   'smartshop_dev',
  user:     'ashwin',
  password: 'ashwin',
  host:     'localhost'
)
DB.exec("SET ivfflat.probes = 1")

def get_embedding(text)
  uri     = URI("#{ENV.fetch('OLLAMA_URL', 'http://localhost:11434')}/api/embeddings")
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = JSON.generate({ model: "nomic-embed-text", prompt: text })
  response = Net::HTTP.start(uri.hostname, uri.port, read_timeout: 60) do |http|
    http.request(request)
  end
  JSON.parse(response.body)['embedding']
rescue => e
  puts "  ⚠️  Embedding failed: #{e.message}"
  nil
end

json_path = File.join(__dir__, '../../db/products_generated.json')
products  = JSON.parse(File.read(json_path))
unique    = products.uniq { |p| p['name'].downcase.strip }

puts "📦 Loaded #{unique.size} unique products"
DB.exec("TRUNCATE TABLE products RESTART IDENTITY")
puts "🗑️  Cleared existing products\n\n"

success = 0
fail_count = 0

unique.each_with_index do |product, index|
  embedding = get_embedding("#{product['name']}. #{product['description']}")

  if embedding.nil?
    fail_count += 1
    next
  end

  DB.exec_params(
    "INSERT INTO products (name, description, category, price, embedding, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, NOW(), NOW())",
    [product['name'], product['description'], product['category'],
     product['price'].to_f, "[#{embedding.join(',')}]"]
  )

  success += 1
  puts "⚡ [#{success}/#{unique.size}] #{product['name']}" if success % 10 == 0
end

puts "\n✅ Seeding complete!"
puts "✅ Seeded  : #{success} products"
puts "❌ Failed  : #{fail_count} products"