#encoding: utf-8

require 'json'
require 'open-uri'
require 'erb'
require 'sass'

class Bookshelf
  attr_reader :books, :publishers

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

    sass_filename = File.dirname(__FILE__) + "/style.scss"
    css = Sass::Engine.for_file(sass_filename, {:style => :compressed}).render
    File.open("#{File.dirname(__FILE__)}/../assets/style.css", "wb") {|f| f.write(css) }

    folders = Bookshelf.get_folders(shelf_folder)
    book_titles = folders.map { |title| title.gsub(/^..\//, "")}

    book_titles.each_with_index do |title, idx|
      begin
        folder_name = folders[idx]
        if File.exist?("#{folder_name}/_meta/info.js")
          info = JSON.parse(File.read("#{folder_name}/_meta/info.js"))
          book = create_book(folders[idx], info)
          @publishers << book.publisher unless book.publisher.empty?
          @books << book
        elsif Bookshelf.contains_book_folders(folder_name)
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
          unless books.empty?
            bundle = Book.new
            bundle.isbn = ""
            bundle.title = folder_name.split("/").last
            bundle.link = folder_name
            bundle.editions = editions
            @books << bundle
          end
        else
          puts "Info not found for #{folder_name}"
        end
      rescue => e
        puts e.message
      end
      @publishers.uniq!
    end
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

  def get_formats(folder_name)
    book_files = Dir.glob(folder_name + "/*")
    formats = []

    book_files.delete_if { |file| File.directory?("#{file}") }

    if book_files.count > 1
      # determine which are most likely to be the book files
      # (as opposed to supporting materials such as READMEs)
      # based on there being multiple occurences of the same
      # base filename with different file extensions
      filenames = book_files.map { |name| name[name.rindex("/")+1..-1].split(".").first }
      tally = Hash.new(0)
      filenames.each do |candidate|
        tally[candidate] += 1
      end
      book_filename = Hash[tally.sort_by{|key, val| val}.reverse].first.first

      book_files.delete_if { |name| name[name.rindex("/")+1..-1].split(".").first != book_filename }
    end

    book_files.each do |file_name|
      format = {}
      format_name = file_name[file_name.rindex("/")+1..-1]
      format[:name] = format_name
      format[:link] = "#{file_name}"
      format[:extension] = format_name.split(".").last
      formats << format
    end

    formats
  end

  def self.contains_book_folders(folder_name)
    folder_contents = Dir.glob("#{folder_name}/*")
    folder_contents.each do |subfolder|
      return true if File.exists?("#{subfolder}/_meta/info.js")
    end
    false
  end

  def create_book(folder_name, info)
    book = Book.new(folder_name: folder_name)
    book.title = info["title"]
    book.link = folder_name
    book.authors = info["authors"]
    book.publisher = info["publisher"]
    book.editions = []
    book.isbn = info["ISBN"] || ""
    book.ident = book.isbn
    book.notes = info["notes"] if info["notes"]
    book.formats = get_formats(folder_name)
    book
  end
end

class Book
  attr_accessor :ident, :title, :link, :publisher, :isbn, :authors,
                :editors, :notes, :formats, :editions, :formats

  def initialize(folder_name: nil)
    @folder_name = folder_name
  end

  def cover_pic=(path)
    @edition_cover_pic = path
  end

  def cover_pic
    if @folder_name
      path = "#{@folder_name}/_meta/cover.jpg"
      return path if File.exist?(path)
    elsif defined?(@edition_cover_pic)
      return @edition_cover_pic
    end
  end

  def sort_title
    case title.downcase
    when /^a /, /^the /
      words = title.split(" ").reverse
      first_word = words.pop
      "#{words.reverse.join(" ")}, #{first_word}"
    else
      title
    end
  end
end
