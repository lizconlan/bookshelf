#encoding: utf-8

require 'json'
require 'open-uri'

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

  def get_folders
    folders = Dir.glob(ARGV[0] || '../*')
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


def output_book(html, book, book_type)
  if book_type == "bundle"
    block = "section"
    title_class = "h3"
  else
    block = "article"
    title_class = "h2"
  end
  html << "<#{block} class='book' itemscope='' itemtype='http://schema.org/Book'>"
  html << "  <#{title_class} class='title'><a href='#{book.link}'>#{book.title}</a></#{title_class}>"
  html << "  <img itemprop='image' src='#{book.cover_pic}' alt=''/>" if book.cover_pic
  html << "  <section class='about'>"
  html << "    <span class='notes'>#{book.notes}</span> <br /><br />" unless book.notes.nil?
  html << "    <span class='authors'>#{book.authors.join(", ")}</span> <br />"
  html << "    <span class='publisher'>#{book.publisher}</span> <br />"
  unless book.isbn.empty?
      html << "    <span class='isbn isbn_#{book.isbn}'>#{book.isbn}</span> " 
      targeturl = "https://openlibrary.org/api/books?bibkeys=ISBN:" + book.isbn.tr(' ','') + "&jscmd=data&format=json"
      html << "<script>$.getJSON('#{targeturl}', function(openLibJson){
                    if (_.isEmpty(openLibJson)) {
                    console.log('No OpenLibrary data for ISBN: #{book.isbn}');
                    } else {
                    console.log(openLibJson);
                    var isbn_key = _.keys(openLibJson)[0];
                    $('span.isbn_#{book.isbn}').append('<br><time>Published: ' + openLibJson[isbn_key].publish_date + '</time>');
                    $('span.isbn_#{book.isbn}').append('<br><span>' + openLibJson[isbn_key].number_of_pages + 'pp.</span>');
                    $('span.isbn_#{book.isbn}').append('<br><span><img itemprop=\"image\" src=\"' + openLibJson[isbn_key].cover.medium + '\"></span>');
                    }
                    
                })</script>"
      
  end
  html << "    <ul class='formats'>"
  book.formats.each do |format|
    html << "      <li><a href='#{format[:link]}'>#{format[:name]}</a></li>"
  end
  html << "    </ul>"
  html << "  </section>"
  html << "</#{block}>"
end

indexer = BookIndex.new

begin
  index = File.open("index.html", 'w+')
  books = indexer.books.sort{ |a, b| a.sort_title.downcase <=> b.sort_title.downcase }
  html = []
  books.each do |book|
    if book.class.to_s == "Book"
      output_book(html, book, "book")
    else
      html << "<article class='book_bundle'>"
      html << "  <h2 class='title'><a href='#{book.link}'>#{book.title}</a></h2>"
      book.books.each do |edition|
        output_book(html, edition, "bundle")
      end
      html << "</article>"
    end
  end
  index.write(%Q|<html>
                    <head>
                        <meta charset="utf-8" />
                        <title>Bookshelf</title>
                        <script src="http://cdnjs.cloudflare.com/ajax/libs/zepto/1.1.3/zepto.min.js"></script>
                        <script src="http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.6.0/underscore-min.js"></script>
                        <style>
                            body {width:50%;margin:1em auto;font-family:sans-serif;}
                            a {text-decoration:none;}
                            img[itemprop="image"] {float:right;}
                            article.book{height:300px;box-shadow:10px 10px 10px 5px gray;padding:20px;border:1pt solid gray;margin:20px;}
                            article.book:last-of-type{}
                        </style>
                    <head>
                    <body>
                    <script>console.clear();</script>
                        #{html.join("\n")}
                    </body>
                </html>|)
  index.close
rescue => e
  puts e.message
end
