class FilterChain
  def initialize
    @filters = []
    @current_position = 0
  end

  def add_filter(filter)
    @filters << filter
  end

  def execute(request, response)
    if @current_position < @filters.length
      current_filter = @filters[@current_position]
      @current_position += 1
      current_filter.process(request, response, self)
    end
  end

  def reset
    @current_position = 0
  end
end 