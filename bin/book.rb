require_relative 'editions'

class Book
  attr_reader :isbn, :authors, :editors, :notes, :formats
  attr_accessor :title, :link, :ident, :publisher, :editions

  def initialize(folder_name: nil, title: nil, authors: [], publisher: "", isbn: "", ident: "", notes: "")
    @folder_name, @link = folder_name
    @title = title
    @authors = authors
    @publisher = publisher
    @isbn = isbn
    @ident = ident
    @notes = notes
    @formats = get_formats
    @editions = Editions.new
  end

  def editions?
    !editions.empty?
  end

  def cover_pic=(path)
    @edition_cover_pic = path
  end

  def cover_pic
    if @folder_name
      path = "#{@folder_name}/_meta/cover.jpg"
      return path if File.exist?(path)
    elsif defined?(@edition_cover_pic)
      return @edition_cover_pic
    end
  end

  def append_edition(edition)
    unless edition.is_a?(Edition)
      raise ArgumentError.new("Expected 'Edition', got '#{edition.class}'")
    end

    unless self == edition.book
      raise ArgumentError.new("#{edition.to_s} does not belong to #{self.to_s}")
    end

    if editions.include?(edition)
      false
    else
      editions << edition
      true
    end
  end

  def sort_title
    case title.downcase
    when /^a /, /^the /
      words = title.split(" ").reverse
      first_word = words.pop
      "#{words.reverse.join(" ")}, #{first_word}"
    else
      title
    end
  end

  protected

  def get_formats
    _formats = []

    files = get_book_files

    files.each do |file_name|
      format = {}
      format_name = file_name[file_name.rindex("/")+1..-1]
      format[:name] = format_name
      format[:link] = "#{file_name}"
      format[:extension] = format_name.split(".").last
      _formats << format
    end

    _formats
  end

  def get_book_files
    return [] unless @folder_name

    files = Dir.glob(@folder_name + "/*")

    # remove directory names
    files.delete_if { |file| File.directory?("#{file}") }

    if files.count > 1
      # determine which are most likely to be the book files
      # (as opposed to supporting materials such as READMEs)
      # based on there being multiple occurences of the same
      # base filename with different file extensions
      filenames = files.map { |name| name[name.rindex("/")+1..-1].split(".").first }

      tally = filenames.inject(Hash.new(0)) { |total, e| total[e] += 1 ; total }
      winner = Hash[tally.sort_by { |key, val| val }.reverse].first.first

      files.delete_if { |name| name[name.rindex("/")+1..-1].split(".").first != winner }
    end

    files
  end
end
