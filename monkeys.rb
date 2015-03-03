class String
  def purify
    path = self.sub(%r{^/+}, '')
    path = path.sub(%r{/+$}, '')
  end
end
