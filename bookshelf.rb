#encoding: utf-8

require 'json'
require 'open-uri'

class Bookshelf
  attr_reader :books

  def initialize(shelf_folder)
    @books = []

    folders = get_folders(shelf_folder)
    book_titles = folders.map { |title| title.gsub(/^..\//, "")}

    book_titles.each_with_index do |title, idx|
      begin
        folder_name = folders[idx]
        if File.exist?("#{folder_name}/_meta/info.js")
          info = JSON.parse(File.read("#{folder_name}/_meta/info.js"))
          book = create_book(folders[idx], info)
          @books << book
        elsif contains_book_folders(folder_name)
          subfolders = Dir.glob("#{folder_name}/*")
          books = []
          subfolders.each do |subfolder_name|
            if File.exist?("#{subfolder_name}/_meta/info.js")
              info = JSON.parse(File.read("#{subfolder_name}/_meta/info.js"))
              book = create_book(subfolder_name, info)
              books << book
            else
              puts "Info not found for #{subfolder_name}"
            end
          end
          unless books.empty?
            bundle = BookBundle.new
            bundle.title = folder_name.split("/").last
            bundle.link = folder_name
            bundle.books = books
            @books << bundle
          end
        else
          puts "Info not found for #{folder_name}"
        end
      rescue => e
        puts e.message
      end
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

  protected

  def get_folders(target_folder)
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
    book_files.each do |file_name|
      format = {}
      if !File.directory?("#{file_name}")
        format_name = file_name[file_name.rindex("/")+1..-1]
        format[:name] = format_name
        format[:link] = "#{file_name}"
        formats << format
      end
    end
    formats
  end

  def contains_book_folders(folder_name)
    folder_contents = Dir.glob("#{folder_name}/*")
    folder_contents.each do |subfolder|
      return true if File.exists?("#{subfolder}/_meta/info.js")
    end
    false
  end

  def create_book(folder_name, info)
    formats = get_formats(folder_name)

    book = Book.new
    book.title = info["title"]
    book.link = folder_name
    book.authors = info["authors"]
    book.publisher = info["publisher"]
    book.isbn = info["ISBN"]
    cover_pic_path = "#{folder_name}/_meta/cover.jpg"
    if File.exist?(cover_pic_path)
      book.cover_pic = cover_pic_path
    end
    book.notes = info["notes"] if info["notes"]
    book.formats = formats
    book
  end
end

class Book
  attr_accessor :title, :cover_pic, :link, :publisher, :isbn, :authors, :editors, :notes, :formats

  def sort_title
    case title.downcase
    when /^a /, /^the /
      words = title.split(" ")
      words.reverse!
      first_word = words.pop
      "#{words.reverse.join(" ")}, #{first_word}"
    else
      title
    end
  end
end

class BookBundle < Book
  attr_accessor :books
end