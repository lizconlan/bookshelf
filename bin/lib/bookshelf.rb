require 'open-uri'
require 'erb'
require 'sass'

require_relative 'book'
require_relative 'edition'
require_relative 'book_binder'

class Bookshelf
  attr_reader :books, :publishers, :incompletes, :strays

  def initialize(shelf_folder)
    @books = []
    @publishers = []
    @incompletes = []
    @strays = []
    @shelf_folder = shelf_folder

    generate_css(File.dirname(__FILE__) + "/../style/style.scss")

    folders = Bookshelf.get_folders(shelf_folder)

    populate_shelves(folders)
    show_book_report(books, @incompletes, @strays, shelf_folder) unless ENV["RACK_ENV"] == "test"
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
    puts "  #{File.absolute_path(shelf)}/index.html"
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

  def populate_shelves(folders)
    book_titles = folders.map { |title| title.gsub(/^..\//, "")}

    book_titles.each_with_index do |title, idx|
      begin
        folder_name = folders[idx]

        # single book in the folder
        if valid_book_folder(folder_name)
          list_book(folder_name, Bookshelf.contains_book_folders(folder_name))
        else
          if File.directory?(folder_name)
            @incompletes << folder_name
          else
            @strays << folder_name
          end
        end
      rescue => e
        puts e.message
        return # something went wrong, stop
      end

      @publishers.uniq!
    end
  end

  def list_book(folder_name, editions = false)
    book =
      if editions
        BookBinder.create_book_with_editions(folder_name)
      else
        BookBinder.create_book(folder_name)
      end

    @publishers << book.publisher if book.publisher
    @books << book
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

  def self.get_folders(target_folder)
    case target_folder
    when /\/$/
      target_folder = "#{target_folder}*"
    when /\*$/
      #yay, leave it alone
    else
      target_folder = "#{target_folder}/*"
    end
    folders = Dir.glob(target_folder)
    folders.delete_if { |folder| folder =~ /(^..\/_)|(\r$)/ }
  end

  # check the contents of the subfolder(s)
  # if there are any (a parent folder is not expected to have metadata)
  def self.contains_book_folders(folder_name)
    folder_contents = Dir.glob("#{folder_name}/*")
    folder_contents.each do |subfolder|
      return true if File.exist?("#{subfolder}/_meta/info.js")
    end
    false
  end

  def valid_book_folder(folder_name)
    File.exist?("#{folder_name}/_meta/info.js") || Bookshelf.contains_book_folders(folder_name)
  end
end
