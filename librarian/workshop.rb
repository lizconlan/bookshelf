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

  def edition_folder(edition)
    edition.instance_variable_get(:@folder_name)
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

  # Moves all top-level items from folder_path into dest_path, skipping:
  #   - the dest_path itself
  #   - hidden files/dirs (e.g. .DS_Store)
  #   - existing edition subfolders (dirs that already have _meta/info.js)
  def wrap_top_level_into(folder_path, dest_path)
    Dir.glob("#{glob_escape(folder_path)}/*").each do |item|
      next if item == dest_path
      next if File.basename(item).start_with?('.')
      next if File.directory?(item) && File.exist?("#{item}/_meta/info.js")
      FileUtils.mv(item, File.join(dest_path, File.basename(item)))
    end
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

# ── Editions overview (for bundle/multi-edition books) ───────────────────────

get '/books/:id/editions' do
  @folder_path = decode_id(params[:id])
  halt 404, 'Folder not found' unless File.directory?(@folder_path)

  @id    = params[:id]
  @title = File.basename(@folder_path)
  @editions = edition_subfolders(@folder_path).map do |sub|
    info = JSON.parse(File.read("#{sub}/_meta/info.js")) rescue {}
    { path: sub, id: encode_id(sub),
      title:      info['title']     || File.basename(sub),
      folder_name: File.basename(sub),
      has_cover:  File.exist?("#{sub}/_meta/cover.jpg") }
  end

  erb :editions
end

# ── Edit book ─────────────────────────────────────────────────────────────────

get '/books/:id/edit' do
  @folder_path = decode_id(params[:id])
  halt 404, 'Book not found' unless File.exist?("#{@folder_path}/_meta/info.js")

  @id        = params[:id]
  @info      = read_info(@folder_path)
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

# ── Rename folder ────────────────────────────────────────────────────────────

post '/books/:id/rename' do
  folder_path = decode_id(params[:id])
  new_name    = sanitize_folder_name(params[:new_name].to_s)

  halt 404, 'Folder not found' unless File.directory?(folder_path)

  if new_name.empty?
    session[:flash_error] = 'New name cannot be blank'
    redirect "/books/#{params[:id]}/edit"
    return
  end

  new_path = File.join(File.dirname(folder_path), new_name)

  if File.exist?(new_path)
    session[:flash_error] = "\u2018#{new_name}\u2019 already exists"
    redirect "/books/#{params[:id]}/edit"
    return
  end

  FileUtils.mv(folder_path, new_path)
  session[:flash_success] = "Folder renamed to \u2018#{new_name}\u2019"
  redirect "/books/#{encode_id(new_path)}/edit"
end

# ── Wrap top-level content of a folder into a named edition subfolder ─────────

post '/books/:id/wrap' do
  folder_path  = decode_id(params[:id])
  edition_name = params[:edition_name].to_s.strip

  halt 404, 'Folder not found' unless File.directory?(folder_path)

  if edition_name.empty?
    session[:flash_error] = 'Edition name is required'
    redirect "/books/#{params[:id]}/edit"
    return
  end

  edition_path = File.join(folder_path, edition_name)

  if File.exist?(edition_path)
    session[:flash_error] = "\u2018#{edition_name}\u2019 already exists inside this folder"
    redirect "/books/#{params[:id]}/edit"
    return
  end

  FileUtils.mkdir_p(edition_path)
  wrap_top_level_into(folder_path, edition_path)

  session[:flash_success] = "Top-level content wrapped into \u2018#{edition_name}\u2019"
  redirect '/'
end

# ── Move book to become an edition of another book ───────────────────────────

post '/books/:id/move' do
  folder_path  = decode_id(params[:id])
  parent_name  = params[:parent_name].to_s.strip
  parent_path  = File.join(SHELF, sanitize_folder_name(parent_name))

  halt 404, 'Book not found' unless File.directory?(folder_path)

  unless File.directory?(parent_path)
    session[:flash_error] = "No folder named \u2018#{parent_name}\u2019 found on the shelf"
    redirect "/books/#{params[:id]}/edit"
    return
  end

  # If the target is still a standalone book, wrap its content first
  if File.exist?("#{parent_path}/_meta/info.js")
    existing_name = params[:existing_edition_name].to_s.strip

    if existing_name.empty?
      session[:flash_error] = "\u2018#{File.basename(parent_path)}\u2019 is a standalone book. " \
        "Provide a name for its existing content (e.g. \u20181st Edition\u2019) so it can be wrapped first."
      redirect "/books/#{params[:id]}/edit"
      return
    end

    existing_path = File.join(parent_path, existing_name)

    if File.exist?(existing_path)
      session[:flash_error] = "\u2018#{existing_name}\u2019 already exists inside \u2018#{File.basename(parent_path)}\u2019"
      redirect "/books/#{params[:id]}/edit"
      return
    end

    FileUtils.mkdir_p(existing_path)
    wrap_top_level_into(parent_path, existing_path)
  end

  dest = File.join(parent_path, File.basename(folder_path))

  if File.exist?(dest)
    session[:flash_error] = "\u2018#{File.basename(folder_path)}\u2019 already exists inside \u2018#{File.basename(parent_path)}\u2019"
    redirect "/books/#{params[:id]}/edit"
    return
  end

  FileUtils.mv(folder_path, dest)
  session[:flash_success] = "\u2018#{File.basename(folder_path)}\u2019 moved into \u2018#{File.basename(parent_path)}\u2019"
  redirect '/'
end

# ── Delete book ───────────────────────────────────────────────────────────────

delete '/books/:id' do
  folder_path = decode_id(params[:id])
  halt 404, 'Book not found' unless File.directory?(folder_path)

  title = File.basename(folder_path)

  # Check for real content (anything outside _meta/)
  real_files = Dir.glob("#{glob_escape(folder_path)}/**/*")
    .reject { |f| File.directory?(f) }
    .reject { |f| f.start_with?("#{folder_path}/_meta/") }

  if real_files.empty?
    FileUtils.rm_rf(folder_path)
    session[:flash_success] = "\u2018#{title}\u2019 deleted"
  else
    FileUtils.rm_f("#{folder_path}/_meta/info.js")
    FileUtils.rm_f("#{folder_path}/_meta/cover.jpg")
    session[:flash_success] = "Metadata removed from \u2018#{title}\u2019 — folder kept (contains book files)"
  end

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
