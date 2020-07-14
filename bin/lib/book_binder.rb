require 'json'
require_relative 'book'
require_relative 'edition'

# borrowed from Rails::ActiveSupport
class Hash
  def symbolize_keys
    transform_keys { |key| key.to_sym rescue key }
  end
end

module BookBinder
  def self.create_book(folder_name)
    info = read_info(folder_name)
    make_book(folder_name, info)
  end

  def self.create_book_with_editions(folder_name)
    subfolders = edition_folders(folder_name)
    return unless subfolders.count > 0

    book_info, editions = traverse_dirs(subfolders, folder_name)
    book = make_book(folder_name, book_info)

    editions.each do |edition_info|
      edition = Edition.new(book, edition_info)
      book.append_edition(edition)
    end

    book
  end

  def self.check_book_data(shelf_folder)
    folders = get_folders(shelf_folder)
    folders.each do |folder_name|
      if contains_book_folders(folder_name)
        check_book_data(folder_name)
      else
        unless File.exist?("#{folder_name}/_meta/info.js")
          puts "no info.js file for #{folder_name}"
        end
        unless File.exist?("#{folder_name}/_meta/cover.jpg")
          puts "no cover image for #{folder_name}"
        end
      end
    end
  end

  def self.get_book_data(target_folder)
    get_folders(target_folder)
  end

  private

  def self.read_info(path)
    JSON.parse(File.read("#{path}/_meta/info.js")).symbolize_keys
  end

  def self.edition_folders(folder_name)
    Dir.glob("#{folder_name}/*").reverse
  end

  def self.book_template(folder_name)
    {
      title: folder_name.split("/").last,
      folder_name: folder_name
    }
  end

  def self.traverse_dirs(subfolders, folder_name)
    book_info = book_template(folder_name)
    ident_no = 1
    editions = []

    subfolders.each do |subfolder_name|
      if File.exist?("#{subfolder_name}/_meta/info.js")
        edition_info = JSON.parse(File.read("#{subfolder_name}/_meta/info.js")).symbolize_keys
        book_info[:isbn] = edition_info[:isbn] if edition_info[:isbn] && !book_info[:isbn]
        edition_info.delete(:ISBN)
        book_info[:publisher] = edition_info.delete(:publisher)
        ident = "#{book_info[:isbn]}_#{ident_no}"
        ident_no += 1
        edition_info[:ident] = ident
        edition_info[:folder_name] = "#{folder_name}/#{subfolder_name}"
        editions << edition_info.symbolize_keys
      else
        puts "Info not found for #{subfolder_name}"
      end
    end
    [book_info, editions]
  end

  def self.make_book(folder_name, info)
    Book.new(
      folder_name: folder_name,
      title: info[:title],
      authors: info[:authors],
      publisher: info[:publisher],
      isbn: info[:ISBN],
      ident: info[:ISBN],
      notes: info[:notes]
    )
  end

  # check the contents of the subfolder(s)
  # if there are any (a parent folder is not expected to have metadata)
  def self.contains_book_folders(folder_name)
    folder_contents = Dir.glob("#{folder_name}/*")
    folder_contents.each do |subfolder|
      return true if File.exist?("#{subfolder}/_meta/info.js")
    end
    false
  end

  def self.get_folders(target_folder)
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
end
