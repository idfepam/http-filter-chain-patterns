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
      
      if original_size > 150  
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
    accept_encoding = request.headers['Accept-Encoding']
    return false unless accept_encoding
    
    accept_encoding.include?('gzip') && 
      response_compressible?(response)
  end

  def response_compressible?(response)
    return false unless response.body

    return false if response.headers['Content-Encoding']

    content_type = response.headers['Content-Type']
    return false unless content_type

    content_type.match?(/^text\/|application\/(json|xml|javascript)/)
  end

  def compress_response(request, response)
    return unless response.body

    output = StringIO.new
    gz = Zlib::GzipWriter.new(output)
    gz.write(response.body.to_s)  
    gz.close

    response.body = output.string
    response.headers['Content-Encoding'] = 'gzip'
    response.headers['Content-Length'] = response.body.bytesize.to_s
    response.headers['Vary'] = 'Accept-Encoding'
  end
end 