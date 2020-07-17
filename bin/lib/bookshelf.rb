require 'open-uri'
require 'erb'
require 'sass'

require_relative 'book'
require_relative 'edition'
require_relative 'book_binder'

class Bookshelf
  attr_reader :books, :publishers, :incompletes, :strays

  SELFPUB_NAME = "Self published".freeze

  def initialize(shelf_folder)
    @books = []
    @publishers = []
    @incompletes = []
    @strays = []
    @shelf_folder = shelf_folder

    generate_css(File.dirname(__FILE__) + "/../style/style.scss")
    populate_shelves(BookBinder.get_book_data(shelf_folder))
    show_book_report(@books, @incompletes, @strays, shelf_folder) unless ENV["RACK_ENV"] == "test"
  end

  def show_book_report(folders, incompletes, strays, shelf)
    puts ""
    puts "Book Report"
    puts "==========="
    puts ""

    puts "Your shelves contain #{folders.count} books…"
    puts ""

    unless incompletes.empty?
      puts "Metadata not found for: "
      incompletes.each do |folder_name|
        puts "  #{folder_name.sub("../", "")}"
      end
      puts ""
    end

    unless strays.empty?
      puts "Misfiled book(s) detected:"
      strays.each do |file_name|
        puts "  #{file_name.sub("../", "")}"
      end
    end
    puts ""

    puts "Admire your books here: "
    puts "  #{File.absolute_path(shelf.sub("..", ""))}/index.html"
    puts ""
  end

  def find_by_title(text)
    @books.select { |book| book.title == text }
  end

  def find_by_publisher(text)
    @books.select { |book| book.publisher == text }
  end

  def find_by_author(text)
    @books.select { |book| book.authors.join("|").include?(text) }
  end

  def sort_by_title
    books.sort{ |a, b| a.sort_title.downcase <=> b.sort_title.downcase }
  end

  private

  def populate_shelves(book_data)
    @books = book_data[:books]
    @incompletes = book_data[:incompletes]
    @strays = book_data[:strays]
    @publishers = sort_publishers(book_data[:publishers].uniq)
  end

  def sort_publishers(pubs)
    self_published = pubs.delete("")
    sorted = pubs.sort
    if self_published
      sorted << SELFPUB_NAME
    end
    sorted
  end

  def generate_css(sass_file)
    target_dir =
      if ENV["RACK_ENV"] == "test"
        "#{File.dirname(__FILE__)}/../test/assets"
      else
        "#{File.dirname(__FILE__)}/../../assets"
      end

    css = Sass::Engine.for_file(sass_file, {:style => :compressed, :cache => false}).render
    File.open("#{target_dir}/style.css", "wb") do |f|
      f.write(css)
    end
  end
end
