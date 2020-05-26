class Editions < Array
  def count
    return 1 if empty?
    super
  end
end
