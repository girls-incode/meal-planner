module CategorySerializer
  def self.as_json(category)
    return nil if category.nil?

    { id: category.id, name: category.name }
  end

  def self.collection_as_json(categories)
    categories.map { |category| as_json(category) }
  end
end
