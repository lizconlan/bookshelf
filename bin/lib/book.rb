require_relative 'publication'
require_relative 'editions'

class Book < Publication
  attr_accessor :title, :link, :ident, :publisher, :editions

  def initialize(folder_name: nil, title: nil, authors: [], publisher: "", isbn: "", ident: "", notes: "")
    @folder_name, @link = folder_name
    @title = title
    @authors = authors
    @publisher = publisher
    @isbn = isbn
    @ident = ident
    @notes = notes
    @formats = get_formats
    @editions = Editions.new
  end

  def editions?
    !editions.empty?
  end

  def append_edition(edition)
    unless edition.is_a?(Edition)
      raise ArgumentError.new("Expected 'Edition', got '#{edition.class}'")
    end

    unless self == edition.book
      raise ArgumentError.new("#{edition.to_s} does not belong to #{self.to_s}")
    end

    if editions.include?(edition)
      false
    else
      editions << edition
      true
    end
  end

  def sort_title
    case title.downcase
    when /^a /, /^the /
      words = title.split(" ").reverse
      first_word = words.pop
      "#{words.reverse.join(" ")}, #{first_word}"
    else
      title
    end
  end
end
