require 'rake'
require './bookshelf.rb'

desc "Generate index.html"
task :generate_index_file do
  target_folder = ENV['shelf'] || ".."
  shelf = Bookshelf.new(target_folder)
  begin
    index = File.open("index.html", 'w+')
    @books = shelf.books.sort{ |a, b| a.sort_title.downcase <=> b.sort_title.downcase }
    @html = []
    @books.each do |book|
      if book.class.to_s == "Book"
        @html << output_book(book)
      else
        @html << create_bundle(book)
      end
    end

    @book_html = @html.join("\n")
    renderer = ERB.new(File.read("index.html.erb"))

    index.write(renderer.result)
    index.close
  rescue => e
    puts e.message
  end
end

def create_bundle(book)
  html = []
  html << "<article class='book_bundle'>"
  html << "  <h2 class='title'><a href='#{book.link}'>#{book.title}</a></h2>"
  book.books.each do |edition|
    html << output_book(edition)
  end
  html << "</article>"
  html.join("\n")
end

def output_book(book)
  @book = book
  ERB.new(File.read("_book.html.erb")).result
end