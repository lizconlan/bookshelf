require 'sinatra'
require 'json'
require 'base64'
require 'fileutils'
require 'net/http'
require 'uri'
require 'open-uri'
require 'open3'
require 'shellwords'

$LOAD_PATH.unshift File.expand_path('../app/lib', __dir__)
require 'book_binder'

SHELF = ENV.fetch('BOOKSHELF_PATH', File.expand_path('../../', __dir__))
# Dir.glob treats [ ] { } * ? as pattern characters; escape for BookBinder
SHELF_GLOB = SHELF.gsub(/[\[\]\{\}\*\?\\]/) { |c| "\\#{c}" }

_config_file = File.join(File.dirname(__FILE__), 'config.json')
EXCLUDE = File.exist?(_config_file) ? (JSON.parse(File.read(_config_file))['exclude'] || []) : []

enable :sessions
enable :method_override

set :root, File.dirname(__FILE__)
set :views, File.join(File.dirname(__FILE__), 'views')

helpers do
  def encode_id(path)
    Base64.urlsafe_encode64(path.to_s)
  end

  def decode_id(id)
    Base64.urlsafe_decode64(id)
  end

  def book_folder(book)
    book.instance_variable_get(:@folder_name)
  end

  def glob_escape(path)
    path.gsub(/[\[\]\{\}\*\?\\]/) { |c| "\\#{c}" }
  end

  # Returns subfolders of a multi-edition book that have their own _meta/info.js
  def edition_subfolders(folder_path)
    Dir.glob("#{glob_escape(folder_path)}/*")
       .select { |sub| File.exist?("#{sub}/_meta/info.js") }
  end

  # Builds a Book+Edition object graph for a folder that has no top-level
  # info.js but does have edition subfolders (bypasses BookBinder's Dir.glob
  # calls, which fail when the shelf path contains [ ] characters).
  def load_edition_book(folder_path)
    subs = edition_subfolders(folder_path)
    return nil if subs.empty?

    first = JSON.parse(File.read("#{subs.first}/_meta/info.js"))
    book  = Book.new(
      folder_name: folder_path,
      title:       File.basename(folder_path),
      authors:     first['authors'],
      publisher:   first['publisher'],
      isbn:        first['ISBN'] || first['isbn']
    )

    subs.each do |sub|
      info = JSON.parse(File.read("#{sub}/_meta/info.js"))
      book.append_edition(Edition.new(book,
        folder_name: sub,
        isbn:        info['ISBN'] || info['isbn'],
        authors:     info['authors'],
        notes:       info['notes']
      ))
    end

    book
  end

  def cover_exists?(folder_path)
    return true if File.exist?("#{folder_path}/_meta/cover.jpg")
    edition_subfolders(folder_path).any? { |sub| File.exist?("#{sub}/_meta/cover.jpg") }
  end

  def read_info(folder_path)
    path = "#{folder_path}/_meta/info.js"
    return {} unless File.exist?(path)
    JSON.parse(File.read(path))
  end

  def sanitize_folder_name(title)
    title.strip.gsub(/[\/\\:*?"<>|]/, '').gsub(/\s+/, ' ')
  end

  def build_info(title, authors, publisher, isbn, notes)
    info = {}
    info['title'] = title unless title.empty?
    info['authors'] = authors unless authors.empty?
    info['publisher'] = publisher
    info['ISBN'] = isbn unless isbn.empty?
    info['notes'] = notes unless notes.empty?
    info
  end

  def fetch_and_resize_cover(url, dest_path)
    URI.open(url, 'rb') do |image|
      File.open(dest_path, 'wb') { |f| f.write(image.read) }
    end
    resize_cover(dest_path)
  end

  def resize_cover(path)
    require 'mini_magick'
    image = MiniMagick::Image.open(path)
    image.resize 'x160'
    image.write path
  end
end

# ── Book listing ────────────────────────────────────────────────────────────

get '/' do
  result = BookBinder.get_book_data(SHELF_GLOB)

  # BookBinder misses multi-edition books when the shelf path contains glob
  # special characters (like [LC]): partition them out of incompletes and
  # build the Book objects ourselves using glob-escaped paths.
  edition_folders, genuine_incompletes = result[:incompletes].partition do |f|
    !edition_subfolders(f).empty?
  end

  @books = (result[:books] + edition_folders.map { |f| load_edition_book(f) }.compact)
    .reject { |b| EXCLUDE.include?(File.basename(book_folder(b))) }
    .sort_by { |b| b.sort_title.downcase }
  @incompletes = genuine_incompletes
    .reject { |f| EXCLUDE.include?(File.basename(f)) }
  erb :index
end

get '/covers/:id' do
  folder_path = decode_id(params[:id])
  cover_path  = "#{folder_path}/_meta/cover.jpg"

  # Fall back to first edition's cover for multi-edition books
  unless File.exist?(cover_path)
    first_edition = edition_subfolders(folder_path).first
    cover_path = "#{first_edition}/_meta/cover.jpg" if first_edition
  end

  halt 404 unless cover_path && File.exist?(cover_path)
  send_file cover_path, type: 'image/jpeg'
end

# ── Add book ─────────────────────────────────────────────────────────────────

get '/books/new' do
  erb :new
end

post '/isbn_lookup' do
  isbn = params[:isbn].to_s.gsub(/[^0-9Xx]/, '').upcase
  halt 400, { error: 'ISBN required' }.to_json if isbn.length < 10

  content_type :json
  begin
    url = URI("https://openlibrary.org/api/books?bibkeys=ISBN:#{isbn}&format=json&jscmd=data")
    response = Net::HTTP.get(url)
    data = JSON.parse(response)
    key = "ISBN:#{isbn}"

    if data[key]
      book_data = data[key]
      {
        title:     book_data['title'],
        authors:   (book_data['authors']   || []).map { |a| a['name'] },
        publishers:(book_data['publishers'] || []).map { |p| p['name'] },
        cover_url: book_data.dig('cover', 'large') ||
                   book_data.dig('cover', 'medium') ||
                   book_data.dig('cover', 'small')
      }.to_json
    else
      { error: 'Book not found on OpenLibrary' }.to_json
    end
  rescue => e
    { error: "Lookup failed: #{e.message}" }.to_json
  end
end

post '/books' do
  title     = params[:title].to_s.strip
  authors   = params[:authors].to_s.split(',').map(&:strip).reject(&:empty?)
  publisher = params[:publisher].to_s.strip
  isbn      = params[:isbn].to_s.strip
  notes     = params[:notes].to_s.strip
  cover_url = params[:cover_url].to_s.strip

  if title.empty?
    session[:flash_error] = 'Title is required'
    redirect '/books/new'
    return
  end

  folder_name = sanitize_folder_name(title)
  folder_path = File.join(SHELF, folder_name)

  if File.exist?(folder_path)
    session[:flash_error] = "A folder named \u2018#{folder_name}\u2019 already exists"
    redirect '/books/new'
    return
  end

  FileUtils.mkdir_p("#{folder_path}/_meta")
  info = build_info(title, authors, publisher, isbn, notes)
  File.write("#{folder_path}/_meta/info.js", JSON.pretty_generate(info))

  unless cover_url.empty?
    begin
      fetch_and_resize_cover(cover_url, "#{folder_path}/_meta/cover.jpg")
    rescue => e
      session[:flash_error] = "Book created but cover fetch failed: #{e.message}"
    end
  end

  session[:flash_success] = "\u2018#{title}\u2019 added to the library"
  redirect '/'
end

# ── Add metadata to existing folder ──────────────────────────────────────────

get '/books/:id/init' do
  @folder_path = decode_id(params[:id])
  halt 404, 'Folder not found' unless File.directory?(@folder_path)
  @id          = params[:id]
  @folder_name = File.basename(@folder_path)
  erb :init
end

post '/books/:id/init' do
  folder_path = decode_id(params[:id])
  halt 404, 'Folder not found' unless File.directory?(folder_path)

  title     = params[:title].to_s.strip
  authors   = params[:authors].to_s.split(',').map(&:strip).reject(&:empty?)
  publisher = params[:publisher].to_s.strip
  isbn      = params[:isbn].to_s.strip
  notes     = params[:notes].to_s.strip
  cover_url = params[:cover_url].to_s.strip

  FileUtils.mkdir_p("#{folder_path}/_meta")
  info = build_info(title, authors, publisher, isbn, notes)
  File.write("#{folder_path}/_meta/info.js", JSON.pretty_generate(info))

  unless cover_url.empty?
    begin
      fetch_and_resize_cover(cover_url, "#{folder_path}/_meta/cover.jpg")
    rescue => e
      session[:flash_error] = "Metadata saved but cover fetch failed: #{e.message}"
    end
  end

  session[:flash_success] = "\u2018#{title}\u2019 metadata saved"
  redirect "/books/#{params[:id]}/edit"
end

# ── Edit book ─────────────────────────────────────────────────────────────────

get '/books/:id/edit' do
  @folder_path = decode_id(params[:id])
  halt 404, 'Book not found' unless File.exist?("#{@folder_path}/_meta/info.js")

  @id       = params[:id]
  @info     = read_info(@folder_path)
  @has_cover = cover_exists?(@folder_path)
  erb :edit
end

patch '/books/:id' do
  folder_path = decode_id(params[:id])
  halt 404, 'Book not found' unless File.exist?("#{folder_path}/_meta/info.js")

  title     = params[:title].to_s.strip
  authors   = params[:authors].to_s.split(',').map(&:strip).reject(&:empty?)
  publisher = params[:publisher].to_s.strip
  isbn      = params[:isbn].to_s.strip
  notes     = params[:notes].to_s.strip

  info = build_info(title, authors, publisher, isbn, notes)
  File.write("#{folder_path}/_meta/info.js", JSON.pretty_generate(info))

  session[:flash_success] = "\u2018#{title}\u2019 updated"
  redirect '/'
end

# ── Cover image ───────────────────────────────────────────────────────────────

post '/books/:id/cover' do
  folder_path = decode_id(params[:id])
  halt 404, 'Book not found' unless File.exist?("#{folder_path}/_meta")

  dest = "#{folder_path}/_meta/cover.jpg"

  begin
    if params[:cover_file] && params[:cover_file][:tempfile]
      FileUtils.cp(params[:cover_file][:tempfile].path, dest)
      resize_cover(dest)
      session[:flash_success] = 'Cover image uploaded and resized'
    elsif params[:cover_url] && !params[:cover_url].to_s.strip.empty?
      fetch_and_resize_cover(params[:cover_url].strip, dest)
      session[:flash_success] = 'Cover image fetched and resized'
    else
      session[:flash_error] = 'No file or URL provided'
    end
  rescue => e
    session[:flash_error] = "Cover update failed: #{e.message}"
  end

  redirect "/books/#{params[:id]}/edit"
end

# ── Rebuild static viewer ─────────────────────────────────────────────────────

post '/rebuild' do
  project_root = File.expand_path('..', __dir__)
  @output, status = Open3.capture2e(
    'bundle', 'exec', 'rake', 'generate_index_file',
    chdir: project_root
  )
  @success = status.success?
  erb :rebuild
end
