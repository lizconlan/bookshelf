require_relative "test_helper"
require_relative "../lib/book_binder"

class TestBookBinder < Minitest::Test

  describe '.create_book' do
    let(:example_folder) { "bin/test/test-shelf/book1" }
    let(:subject) { BookBinder.create_book(example_folder) }
    let(:book) { subject }

    it { assert_equal(Book, book.class) }
    it { assert_equal("Test Book", book.title) }
    it { assert_equal("0-2642-9355-X", book.isbn) }
    it { assert_equal("TestBooks Inc", book.publisher )}
    it { assert_equal(["Donald Duck", "Mickey Mouse"], book.authors)}
    it { assert_equal(false, book.editions?) }
  end

  describe '.create_book_with_editions' do
    let(:example_folder) { "bin/test/test-shelf/edition" }
    let(:subject) { BookBinder.create_book_with_editions(example_folder) }
    let(:book) { subject }
    let(:edition) { book.editions.first }

    it { assert_equal(Book, book.class) }
    it { assert_equal("edition", book.title) }
    it { assert_equal("TestBooks Inc", book.publisher) }
    it { assert_equal(true, book.editions?) }
    it { assert_equal(["Ann Author"], edition.authors) }
    it { assert_equal("0-2642-9358-X", edition.isbn) }
  end

end
