class Product < ApplicationRecord
  has_neighbors :embedding, dimensions: 768

  def self.vector_search(query_embedding, limit: 8)
    nearest_neighbors(:embedding, query_embedding, distance: "cosine")
      .limit(limit)
  end
end