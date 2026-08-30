class ResizeRecipeEmbeddings < ActiveRecord::Migration[8.1]
  def change
    remove_column :recipe_embeddings, :embedding, :vector
    add_column :recipe_embeddings, :embedding, "vector(768)", null: false
  end
end
