require_relative "test_helper"
require_relative "../lib/bookshelf"

class TestBookshelf < Minitest::Test

  describe '.new' do
    let(:shelf_folder) { 'bin/test/test-shelf' }
    let(:stylesheet) { "#{shelf_folder}/../assets/style.css" }
    let(:bookshelf) { Bookshelf.new(shelf_folder) }

    before do
      File.delete(stylesheet) if File.exist?(stylesheet)
    end

    after do
      File.delete(stylesheet) if File.exist?(stylesheet)
    end

    it 'should create a style.css file' do
      Bookshelf.new(shelf_folder)
      assert_equal(true, File.exist?(stylesheet))
    end

    it { assert_equal(3, bookshelf.books.count) }
    it { assert_equal(1, bookshelf.publishers.count) }
    it { assert_equal(1, bookshelf.strays.count) }
    it { assert_equal(1, bookshelf.incompletes.count) }
  end

end
