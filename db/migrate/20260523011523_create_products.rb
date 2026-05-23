class CreateProducts < ActiveRecord::Migration[8.1]
  def up
    execute "CREATE EXTENSION IF NOT EXISTS vector"

    create_table :products do |t|
      t.string  :name,        null: false
      t.text    :description, null: false
      t.string  :category
      t.decimal :price, precision: 10, scale: 2
      t.column  :embedding, :vector, limit: 768
      t.timestamps
    end

    execute "CREATE INDEX ON products USING ivfflat (embedding vector_cosine_ops) WITH (lists = 1)"
  end

  def down
    drop_table :products
    execute "DROP EXTENSION IF EXISTS vector"
  end
end