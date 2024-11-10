require_relative 'filters/decorators/filter_decorator'
require_relative 'filters/decorators/logging_decorator'
require_relative 'filters/data_transformation_filter'
require_relative 'filters/caching_filter'
require_relative 'filters/compression_filter'

class FilterFactory
  def self.create_filters(path)
    filters = []
    
    # Add filters based on path
    case path
    when /^\/api\//
      filters << LoggingDecorator.new(DataTransformationFilter.new)
    when /\.(html|css|js|json)$/
      filters << LoggingDecorator.new(CachingFilter.new)
    end

    # Always add compression with logging
    unless filters.any? { |f| f.is_a?(LoggingDecorator) && f.instance_variable_get(:@filter).is_a?(CompressionFilter) }
      filters << LoggingDecorator.new(CompressionFilter.new)
    end
    
    puts "\nFilter Chain:"
    puts "------------"
    filters.each_with_index do |filter, index|
      puts "#{index + 1}. #{filter.class} (#{filter.instance_variable_get(:@filter).class})"
    end
    puts
    
    filters
  end
end 