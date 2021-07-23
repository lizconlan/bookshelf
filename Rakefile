require 'rake'
require 'csv'
require './app/lib/bookshelf.rb'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "app/test/*_test.rb"
  t.warning = false
end

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
  BookBinder.check_book_data(target_folder)
end

desc "Installs the dev tools required to build the project"
task :install do
  if `which npm` == ""
    puts "You need to install npm on your machine, please run: npm install -g npm"
    puts "More details here: https://docs.npmjs.com/downloading-and-installing-node-js-and-npm"
    return
  end

  puts "Installing npm modules…"
  `npm install`
  puts ""

  puts "Updating ruby gems…"
  `bundle install`
  puts ""

  puts "Done!"
end

desc "Generate index.html"
task :generate_index_file do
  target_folder = ENV['shelf'] || ".."
  shelf = Bookshelf.new(target_folder)
  begin
    @uniq = 0
    index = File.open("index.html", 'w+')
    @books = shelf.sort_by_title
    @publishers = shelf.publishers

    @html = []
    @books.each_with_index do |book, idx|
      @uniq = idx
      if book.editions?
        @html << create_bundle(book)
      else
        @html << output_book(book)
      end
    end

    @book_html = @html.join("\n")
    renderer = ERB.new(File.read("app/views/index.html.erb"), trim_mode: "<>")

    index.write(renderer.result)
    index.close

    `gulp build`
  rescue => e
    puts e.message
  end

end

def create_bundle(book)
  @colours = {"pdf" => "green", "mobi" => "green", "epub" => "green"}
  @tabs = []
  book.editions.each do |edition|
    @book = edition
    @tabs << ERB.new(File.read("app/views/_detail.html.erb"), trim_mode: "<>").result
  end

  @book = book
  ERB.new(File.read("app/views/_book.html.erb"), trim_mode: "<>").result
end

def output_book(book)
  @book = book
  @colours = {"pdf" => "green", "mobi" => "green", "epub" => "green"}
  @content = ERB.new(File.read("app/views/_detail.html.erb"), trim_mode: "<>").result
  ERB.new(File.read("app/views/_book.html.erb"), trim_mode: "<>").result
end

def output_csv(book)
  @book = book
  @editions = nil
  ERB.new(File.read("_book.csv.erb"), trim_mode: "<>").result
end
