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

  def cover_exists?(folder_path)
    File.exist?("#{folder_path}/_meta/cover.jpg")
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
  result = BookBinder.get_book_data(SHELF)
  @books = result[:books].sort_by { |b| b.sort_title.downcase }
  @incompletes = result[:incompletes]
  erb :index
end

get '/covers/:id' do
  folder_path = decode_id(params[:id])
  cover_path = "#{folder_path}/_meta/cover.jpg"
  halt 404 unless File.exist?(cover_path)
  send_file cover_path, type: 'image/jpeg'
end
