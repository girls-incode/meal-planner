class CreateRecipeEmbeddings < ActiveRecord::Migration[8.1]
  VECTOR_DIMENSION = 1536

  def change
    enable_extension "vector"

    create_table :recipe_embeddings, id: false do |t|
      t.uuid :recipe_id, null: false, primary_key: true
      t.column :embedding, "vector(#{VECTOR_DIMENSION})", null: false
      t.string :embedding_model, null: false
      t.string :content_hash, null: false
      t.timestamps
    end

    add_foreign_key :recipe_embeddings, :recipes
    add_index :recipe_embeddings, :embedding, using: :hnsw, opclass: :vector_cosine_ops
    add_index :recipe_embeddings, :content_hash
  end
end
