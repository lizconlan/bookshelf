require 'rake'
require './bookshelf.rb'

desc "Generate index.html"
task :generate_index_file do
  target_folder = ENV['shelf'] || ".."
  shelf = Bookshelf.new(target_folder)
  begin
    index = File.open("index.html", 'w+')
    books = shelf.books.sort{ |a, b| a.sort_title.downcase <=> b.sort_title.downcase }
    html = []
    books.each do |book|
      if book.class.to_s == "Book"
        output_book(html, book, "book")
      else
        create_bundle(html, book)
      end
    end
    index.write(%Q|<html>
                      <head>
                          <meta charset="utf-8" />
                          <title>#{books.length} books</title>
                          <script src="http://cdnjs.cloudflare.com/ajax/libs/zepto/1.1.3/zepto.min.js"></script>
                          <script src="http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.6.0/underscore-min.js"></script>
                          <style>
                              body {width:50%;margin:1em auto;font-family:sans-serif;}
                              a {text-decoration:none;}
                              img[itemprop="image"] {float:right;}
                              article.book_bundle{min-height:300px;box-shadow:10px 10px 10px 5px gray;padding:20px;border:1pt solid gray;margin:20px;}
                              section.book{height:300px;padding:20px;border:1pt solid gray;margin:20px; width: 90%}
                              article.book{height:300px;box-shadow:10px 10px 10px 5px gray;padding:20px;border:1pt solid gray;margin:20px;}
                              article.book:last-of-type{}
                          </style>
                      <head>
                      <body>

                          #{html.join("\n")}

                      </body>
                  </html>|)
    index.close
  rescue => e
    puts e.message
  end
end

def create_bundle(html, book)
  html << "<article class='book_bundle'>"
  html << "  <h2 class='title'><a href='#{book.link}'>#{book.title}</a></h2>"
  book.books.each do |edition|
    output_book(html, edition, "bundle")
  end
  html << "</article>"
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
                    }

                })</script>"

  end
  html << "    <ul class='formats'>"
  book.formats.each do |format|
    html << "      <li><a href='ibooks://#{format[:link]}'>#{format[:name]}</a></li>"
  end
  html << "    </ul>"
  html << "  </section><br clear='all'>"
  html << "</#{block}>"
end