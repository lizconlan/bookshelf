require_relative "test_helper"
require_relative "../lib/edition"

class TestEdition < Minitest::Test

  describe '.new' do
    let(:book) { Book.new }
    let(:edition) { Edition.new(book) }

    let(:detailed_book) do
      Book.new(
        isbn: "8601404204708",
        authors: ["William Shakespeare"],
        notes: "2007 version",
        title: "The Complete Works"
      )
    end

    describe 'sensible defaults' do
      it { assert_equal(book, edition.book) }
      it { assert_equal([], edition.authors) }
      it { assert_empty(edition.publisher) }
      it { assert_empty(edition.isbn) }
      it { assert_empty(edition.ident) }
      it { assert_empty(edition.notes) }
      it { assert_nil(edition.title) }
    end

    describe 'no book passed in' do
      it { assert_raises(ArgumentError) { Edition.new } }
    end

    describe 'values inherited from book' do
      let(:edition) { Edition.new(detailed_book) }
      let(:expected_ident) { "#{detailed_book.isbn}_1" }

      it { assert_equal(detailed_book.isbn, edition.isbn) }
      it { assert_equal(detailed_book.authors, edition.authors) }
      it { assert_equal(detailed_book.notes, edition.notes) }
      it { assert_equal(detailed_book.title, edition.title) }
      it { assert_equal(expected_ident, edition.ident) }
    end

    describe 'inherited values can be overridden by data passed in' do
      let(:edition) { Edition.new(detailed_book, notes: "2nd printing", title: "2008 edit") }

      it { assert_equal(detailed_book.isbn, edition.isbn) }
      it { assert_equal("2nd printing", edition.notes) }
      it { assert_equal("2008 edit", edition.title) }
    end
  end

  describe '#editions?' do
    let(:book) { Book.new }
    let(:edition) { Edition.new(book) }

    it { assert_equal(false, edition.editions?) }
  end

end
