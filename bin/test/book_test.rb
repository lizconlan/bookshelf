require_relative "test_helper"
require_relative "../lib/book"
require_relative "../lib/edition"

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
      it { assert_equal(1, book.editions.count) }
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

    describe 'attributes passed as nil instead of "" by json' do
      let(:book) do
        Book.new(
          title: "Test Book",
          authors: nil,
          publisher: nil,
          isbn: nil,
        )
      end

      it { assert_equal("Test Book", book.title) }
      it { assert_equal([], book.authors) }
      it { assert_equal("", book.publisher) }
      it { assert_equal("", book.isbn)}
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

    describe 'the edition has its own image' do
      let(:example_folder) { "bin/test/test-shelf/edition" }
      let(:book) { Book.new(folder_name: example_folder) }
      let(:edition) { Edition.new(book, folder_name: "#{example_folder}/v1") }

      before { book.append_edition(edition) }

      it { assert_equal(edition.cover_pic, book.cover_pic) }
    end
  end

  describe '#editions?' do
    let(:book) { Book.new }

    it { assert_equal(false, book.editions?) }

    it 'returns true if is at least one appended edition' do
      book.append_edition(Edition.new(book))
      assert_equal(true, book.editions?)
    end
  end

  describe '#append_edition' do
    let(:book) { Book.new }
    let(:edition) { Edition.new(book) }

    describe 'success' do
      it 'adds a new edition to the book' do
        book.append_edition(edition)
        assert_equal(1, book.editions.count)
        assert_equal([edition], book.editions)
      end

      it { assert_equal(true, book.append_edition(edition)) }
    end

    describe 'trying to add the same edition twice' do
      before { book.append_edition(edition) }

      it 'does not add the duplicate' do
        book.append_edition(edition)
        assert_equal(1, book.editions.count)
      end

      it { assert_equal(false, book.append_edition(edition)) }
    end

    describe 'trying to add an object which is not an Edition' do
      it 'raises an error' do
        err = assert_raises(ArgumentError) { book.append_edition(Hash.new) }
        assert_equal("Expected 'Edition', got 'Hash'", err.message)
      end
    end

    describe 'trying to add an edition that belongs to a different book' do
      let(:wrong_book) { Book.new }
      let(:edition) { Edition.new(wrong_book) }

      it 'raises an error' do
        err = assert_raises(ArgumentError) { book.append_edition(edition) }
        assert_match(/#<Edition.* does not belong to #<Book/, err.message)
      end
    end

    describe 'multiple editions with their own isbns' do
      let!(:book) { Book.new(title: 'Test') }

      let!(:edition1) do
        _edition = Edition.new(book, isbn: '1234')
        book.append_edition(_edition)
        _edition
      end

      let!(:edition2) do
        _edition = Edition.new(book, isbn: '5678')
        book.append_edition(_edition)
        _edition
      end

      it { assert_equal('Test', book.title) }
      it { assert_equal(2, book.editions.count) }
      it { assert_equal(book.editions[0], edition1) }
      it { assert_equal(book.editions[1], edition2) }
      it { assert_equal('1234', edition1.isbn) }
      it { assert_equal('5678', edition2.isbn) }
      it { assert_equal('1234', book.isbn) }
      it { assert_equal('1234_1', edition1.ident) }
      it { assert_equal('1234_2', edition2.ident) }
    end
  end

  describe '#self_published?' do
    let(:self_published_book) { Book.new }
    let(:trad_published_book) { Book.new(publisher: 'test') }

    it { assert_equal(self_published_book.self_published?, true) }
    it { assert_equal(trad_published_book.self_published?, false) }
  end

end
