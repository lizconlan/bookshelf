require_relative 'book'

class Edition < Book
  attr_reader :ident, :isbn, :authors, :editors, :notes, :formats, :book,
              :title, :link, :publisher

  def initialize(book, ident: nil, isbn: nil, authors: nil, notes: nil, formats: nil, title: nil, folder_name: nil)
    @book = book
    @folder_name = folder_name
    @isbn = isbn || book.isbn
    @ident = ident || @isbn
    @authors = authors || book.authors
    @notes = notes || book.notes
    @formats = get_formats
    @title =
      if title
        "#{book.title} - #{title}"
      else
        book.title
      end
    @publisher = book.publisher
  end

  def editions?
    false
  end

  undef editions
  undef append_edition
end
