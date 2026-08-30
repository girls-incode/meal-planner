module AuthorSerializer
  def self.as_json(author)
    return nil if author.nil?

    { id: author.id, name: author.name }
  end
end
