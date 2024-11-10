class LoggingDecorator < FilterDecorator
  def process(request, response, chain)
    start_time = Time.now
    
    puts "\nFilter Execution Log:"
    puts "-------------------"
    puts "Starting #{@filter.class} at #{start_time}"
    
    @filter.process(request, response, chain)
    
    end_time = Time.now
    duration = ((end_time - start_time) * 1000).round(2)
    puts "Completed #{@filter.class} in #{duration}ms"
    puts
  end
end 