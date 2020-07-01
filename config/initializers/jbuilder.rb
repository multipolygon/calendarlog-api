class Jbuilder
  def target!
    ::JSON.pretty_generate(@attributes)
  end
end
