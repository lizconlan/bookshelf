#encoding: utf-8

require 'json'

class BookIndex
  attr_reader :books

  def initialize
    @books = []

    folders = get_folders
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
              p "Info not found for #{subfolder_name}"
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
          p "Info not found for #{folder_name}"
        end
      rescue => e
        p e.message
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

  def get_folders
    folders = Dir.glob('../*')
    folders.delete_if { |folder| folder =~ /(^..\/_)|(\r$)/ }
  end

  def get_formats(folder_name)
    book_files = Dir.glob(folder_name + "/*")
    formats = []
    book_files.each do |file_name|
      format = {}
      if !File.directory?("#{file_name}")
        format_name = file_name[file_name.rindex(".")+1..-1]
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
    if File.exist?("#{folder_name}/_meta/cover.jpg")
      book.cover_pic = "#{folder_name}/_meta/cover.jpg"
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


def output_book(html, book, book_type, suppress_hr = false)
  if book_type == "bundle"
    block = "section"
    title_class = "h3"
  else
    block = "article"
    title_class = "h2"
  end
  html << "<#{block} class='book'>"
  html << "  <#{title_class} class='title'><a href='#{book.link}'>#{book.title}</a></#{title_class}>"
  html << "  <img src='#{book.cover_pic}' height='160' border='0' alt=''/>" if book.cover_pic
  html << "  <section class='about'>"
  html << "    <span class='notes'>#{book.notes}</span> <br /><br />" unless book.notes.nil?
  html << "    <span class='authors'>#{book.authors.join(", ")}</span> <br />"
  html << "    <span class='publisher'>#{book.publisher}</span> <br />"
  html << "    <span class='isbn'>#{book.isbn}</span> " unless book.isbn.empty?
  html << "    <ul class='formats'>"
  book.formats.each do |format|
    html << "      <li><a href='#{format[:link]}'>#{format[:name]}</a></li>"
  end
  html << "    </ul>"
  html << "  </section>"
  html << "</#{block}>"
  html << "<hr />" unless suppress_hr
end

indexer = BookIndex.new

begin
  index = File.open("index.html", 'w+')
  books = indexer.books.sort{ |a, b| a.sort_title.downcase <=> b.sort_title.downcase }
  html = []
  books.each do |book|
    if book.class.to_s == "Book"
      output_book(html, book, "book", book == books.last)
    else
      html << "<article class='book_bundle'>"
      html << "  <h2 class='title'><a href='#{book.link}'>#{book.title}</a></h2>"
      book.books.each do |edition|
        output_book(html, edition, "bundle", edition == book.books.last)
      end
      html << "</article>"
      html << "<hr />" unless book == books.last
    end
  end
  index.write(%Q|<html><head><meta charset="utf-8" /><head><body><h1>Bookshelf</h1>#{html.join("\n")}</body></html>|)
  index.close
rescue => e
  p e.message
end