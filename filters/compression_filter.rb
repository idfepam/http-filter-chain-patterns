require_relative '../filter'
require 'zlib'
require 'stringio'

class CompressionFilter < Filter
  def process(request, response, chain)
    chain.execute(request, response)
    
    if should_compress?(request, response)
      puts "\nCompression:"
      puts "------------"
      original_body = response.body.is_a?(Hash) ? response.body.to_json : response.body.to_s
      original_size = original_body.bytesize
      puts "Original Size: #{original_size} bytes"
      
      # Only compress if content is large enough to benefit from compression
      if original_size > 150  # minimum size threshold
        response.body = original_body
        compress_response(request, response)
        
        compressed_size = response.body.bytesize
        compression_ratio = ((original_size - compressed_size).to_f / original_size * 100).round(2)
        puts "Compressed Size: #{compressed_size} bytes"
        puts "Compression Ratio: #{compression_ratio}%"
      else
        puts "Content too small for effective compression (< 150 bytes)"
      end
      puts
    end
  end

  private

  def should_compress?(request, response)
    # Check if client accepts gzip encoding
    accept_encoding = request.headers['Accept-Encoding']
    return false unless accept_encoding
    
    accept_encoding.include?('gzip') && 
      response_compressible?(response)
  end

  def response_compressible?(response)
    return false unless response.body

    # Don't compress if content is already compressed
    return false if response.headers['Content-Encoding']

    # Only compress text-based content types
    content_type = response.headers['Content-Type']
    return false unless content_type

    content_type.match?(/^text\/|application\/(json|xml|javascript)/)
  end

  def compress_response(request, response)
    return unless response.body

    # Compress the response body
    output = StringIO.new
    gz = Zlib::GzipWriter.new(output)
    gz.write(response.body.to_s)  # Convert to string in case it's a hash
    gz.close

    # Update response with compressed content
    response.body = output.string
    response.headers['Content-Encoding'] = 'gzip'
    response.headers['Content-Length'] = response.body.bytesize.to_s
    response.headers['Vary'] = 'Accept-Encoding'
  end
end 