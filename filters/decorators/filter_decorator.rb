class FilterDecorator
  def initialize(filter)
    @filter = filter
  end
  
  # Delegate unknown methods to the wrapped filter
  def method_missing(method_name, *args, &block)
    @filter.send(method_name, *args, &block)
  end
end 