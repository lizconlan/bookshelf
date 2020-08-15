require_relative 'publication'

class Edition < Publication
  attr_reader :ident, :isbn, :authors, :editors, :notes, :formats, :book,
              :title, :link, :publisher, :number

  def initialize(book, ident: nil, isbn: nil, authors: nil, notes: nil, formats: nil, title: nil, folder_name: nil)
    @book = book
    @folder_name = folder_name
    @isbn = isbn || book.isbn || ""
    @number = edition_offset(book)
    @ident = generate_ident(ident)
    @authors = authors || book.authors
    @notes = notes || book.notes
    @formats = get_formats
    @title = title || book.title
    @publisher = book.publisher
  end

  def editions?
    false
  end

  private

  def edition_offset(book)
    if book.editions.empty?
      1
    else
      book.editions.count + 1
    end
  end

  def base_ident(ident, number)
    return book.isbn unless book.isbn == ""
    ident || isbn
  end

  def generate_ident(ident)
    return "" if base_ident(ident, number) == ""
    "#{base_ident(ident, number)}_#{number}"
  end
end
