require 'json'
require 'open-uri'
require 'erb'
require 'sass'

require_relative 'book'
require_relative 'edition'

class Bookshelf
  attr_reader :books, :publishers, :incompletes, :strays

  def self.check_book_data(shelf_folder)
    folders = get_folders(shelf_folder)
    folders.each do |folder_name|
      # check the contents of the subfolder(s)
      # if there are any (a parent folder is not expected to have metadata)
      if contains_book_folders(folder_name)
        check_book_data(folder_name)
      else
        unless File.exist?("#{folder_name}/_meta/info.js")
          puts "no info.js file for #{folder_name}"
        end
        unless File.exist?("#{folder_name}/_meta/cover.jpg")
          puts "no cover image for #{folder_name}"
        end
      end
    end
  end

  def initialize(shelf_folder)
    @books = []
    @publishers = []
    @incompletes = []
    @strays = []
    @shelf_folder = shelf_folder

    generate_css(File.dirname(__FILE__) + "/style.scss")

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

  protected

  def populate_shelves(folders)
    book_titles = folders.map { |title| title.gsub(/^..\//, "")}

    book_titles.each_with_index do |title, idx|
      begin
        folder_name = folders[idx]

        # single book in the folder
        if File.exist?("#{folder_name}/_meta/info.js")
          list_book(folder_name)
        # multiple editions of book in the folder
        elsif Bookshelf.contains_book_folders(folder_name)
          list_editions(folder_name)
        elsif File.directory?(folder_name)
          @incompletes << folder_name
        # stray files
        else
          @strays << folder_name
        end
      rescue => e
        puts e.message
        return # something went wrong, stop
      end

      @publishers.uniq!
    end
  end

  def list_book(folder_name)
    info = JSON.parse(File.read("#{folder_name}/_meta/info.js"))
    book = create_book(folder_name, info)
    @publishers << book.publisher unless book.publisher.empty?
    @books << book
  end

  def list_editions(folder_name)
    subfolders = Dir.glob("#{folder_name}/*")
    editions = []

    subfolders.each do |subfolder_name|
      ident_no = 1
      if File.exist?("#{subfolder_name}/_meta/info.js")
        info = JSON.parse(File.read("#{subfolder_name}/_meta/info.js"))
        ident = ""

        if editions.collect{ |x| x.ident }.include?(info["ISBN"])
          ident = info["ISBN"] + "_#{ident_no}"
          ident_no += 1
        end

        book = create_book(subfolder_name, info)
        book.ident = ident unless ident == ""
        editions << book
      else
        puts "Info not found for #{subfolder_name}"
      end
    end

    unless editions.empty?
      book_bundle = Book.new
      book_bundle.title = folder_name.split("/").last
      book_bundle.link = folder_name
      book_bundle.editions = editions
      @books << book_bundle
      @publishers << editions.first.publisher unless editions.first.publisher.empty?
    end
  end

  def generate_css(sass_file)
    target_dir =
      if ENV["RACK_ENV"] == "test"
        "#{File.dirname(__FILE__)}/test/assets"
      else
        "#{File.dirname(__FILE__)}/../assets"
      end

    css = Sass::Engine.for_file(sass_file, {:style => :compressed}).render
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

  def self.contains_book_folders(folder_name)
    folder_contents = Dir.glob("#{folder_name}/*")
    folder_contents.each do |subfolder|
      return true if File.exists?("#{subfolder}/_meta/info.js")
    end
    false
  end

  def create_book(folder_name, info)
    Book.new(
      folder_name: folder_name,
      title: info["title"],
      authors: info["authors"],
      publisher: info["publisher"],
      isbn: info["ISBN"],
      ident: info["ISBN"],
      notes: info["notes"]
     )
  end
end
