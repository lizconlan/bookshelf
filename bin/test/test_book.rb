require_relative "test_helper"
require_relative "../book"

class TestBook < Minitest::Test

  describe '.new' do
    let(:book) { Book.new }

    describe 'sensible defaults' do
      it { assert_nil(book.title) }
      it { assert_equal([], book.authors) }
      it { assert_empty(book.publisher) }
      it { assert_empty(book.isbn) }
      it { assert_empty(book.ident) }
      it { assert_empty(book.notes) }
    end

    describe 'passing in attributes' do
      let(:book) do
        Book.new(
          title: "Test Book",
          authors: ["Donald Duck", "Mickey Mouse"],
          publisher: "TestBooks Inc",
          isbn: "0-2642-9355-X",
          ident: "1234",
          notes: "this book does not exist"
        )
      end

      it { assert_equal("Test Book", book.title) }
      it { assert_equal(["Donald Duck", "Mickey Mouse"], book.authors) }
      it { assert_equal("TestBooks Inc", book.publisher) }
      it { assert_equal("0-2642-9355-X", book.isbn)}
      it { assert_equal("1234", book.ident) }
      it { assert_equal("this book does not exist", book.notes) }
    end
  end

  describe '#sort_title' do
    describe 'sortable titles' do
      let(:book) { Book.new(title: "My New Book") }

      it { assert_equal(book.title, book.sort_title) }
    end

    describe 'sortable title beginning with "a"' do
      let(:book) { Book.new(title: "Another New Book") }

      it { assert_equal(book.title, book.sort_title) }
    end

    describe 'titles beginning with "the"' do
      let(:book) { Book.new(title: "The New Book") }

      it { assert_equal("New Book, The", book.sort_title) }
    end

    describe 'titles beginning with "a"' do
      let(:book) { Book.new(title: "A New Book") }

      it { assert_equal("New Book, A", book.sort_title) }
    end
  end

  describe '#cover_pic' do
    let(:book) { Book.new }
    let(:example_folder) { "bin/test/test-shelf/book1" }

    describe 'no image was assigned' do
      it { assert_nil(book.cover_pic) }
    end

    describe 'a default image exists in the book folder' do
      let(:book) { Book.new(folder_name: example_folder) }

      it { assert_equal("#{example_folder}/_meta/cover.jpg", book.cover_pic) }
    end

    describe 'no default image but one was manually assigned' do
      before { book.cover_pic = "#{example_folder}/_meta/cover2.jpg" }

      it { assert_equal("#{example_folder}/_meta/cover2.jpg", book.cover_pic) }
    end
  end

  describe '#editions?' do
    let(:book) { Book.new }

    it { assert_equal(false, book.editions?) }

    it 'returns true if is at least one appended edition' do
      book.editions << {}
      assert_equal(true, book.editions?)
    end
  end

end
