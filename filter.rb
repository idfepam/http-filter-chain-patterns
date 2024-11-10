class Filter
  def process(request, response, chain)
    raise NotImplementedError, "#{self.class} must implement process method"
  end
end 