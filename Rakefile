require 'rake'
require 'csv'
require './bin/bookshelf.rb'

task :default => "features"

desc "Describe features"
task :features do
  puts "
  * Target folder: #{ENV['shelf'] || ".."}
  * Change target: 'rake generate_index_file shelf=\"/my/target/folder/.\"'
  * All tasks: 'rake -T'
  "
end

desc "Check for data files"
task :check_for_book_data do
  target_folder = ENV['shelf'] || ".."
  Bookshelf.check_book_data(target_folder)
end

desc "Generate index.html"
task :generate_index_file do
  target_folder = ENV['shelf'] || ".."
  shelf = Bookshelf.new(target_folder)
  begin
    @uniq = 0
    index = File.open("index.html", 'w+')
    @books = shelf.books.sort{ |a, b| a.sort_title.downcase <=> b.sort_title.downcase }
    @html = []
    @books.each_with_index do |book, idx|
      @uniq = idx
      if book.class.to_s == "Book"
        @html << output_book(book)
      else
        @html << create_bundle(book)
      end
    end

    @book_html = @html.join("\n")
    renderer = ERB.new(File.read("bin/index.html.erb"))

    index.write(renderer.result)
    index.close
    puts "File generated: " + File.absolute_path(index)
  rescue => e
    puts e.message
  end
  
end

def create_bundle(book)
  html = []
  html << "<article class='book_bundle'>"
  html << "  <h2 class='title'><a href='#{book.link}'>#{book.title}</a></h2>"
  @uniq += 8000
  book.books.each do |edition|
    html << output_book(edition, "BookBundle")
    @uniq += 1
  end
  html << "</article>"
  html.join("\n")
end

def output_book(book, book_class = "Book")
  @book = book
  @book_class = book_class
  @colours = {"pdf" => "green", "mobi" => "green", "epub" => "green"}
  ERB.new(File.read("bin/_book.html.erb")).result
end

def output_csv(book)
  @book = book
  ERB.new(File.read("_book.csv.erb")).result
end