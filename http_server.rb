require 'socket'
require_relative 'filter_chain'
require_relative 'filter_factory'
require_relative 'request_builder'
require_relative 'response_builder'

class HTTPServer
  def initialize(port = 3000)
    @port = port
    @filter_chain = FilterChain.new
  end

  def start
    require 'socket'
    server = TCPServer.new(@port)
    puts "\n=== HTTP Server Started ==="
    puts "Listening on port #{@port}"
    puts "=" * 25 + "\n\n"

    loop do
      puts "Waiting for connections..."
      client = server.accept
      puts "\n=== New Connection ==="
      handle_request(client)
  rescue => e
      puts "\n!!! Error !!!"
      puts "#{e.message}"
      puts e.backtrace
    end
  end

  private

  def handle_request(client)
    request = parse_request(client)
    puts "-" * 50
    puts "Processing #{request.method} #{request.path}"
    puts "-" * 50
    content_type = case request.path
                   when /\.html$/ then 'text/html'
                   when /\.js$/ then 'application/javascript'
                   when /\.css$/ then 'text/css'
                   when /^\/api\// then 'application/json'
                   else 'text/plain'
                   end

    response_body = if request.path.start_with?('/api/')
      request.body || { message: "Hello World" }
    else
      "Hello World"
    end

    response = ResponseBuilder.new
      .set_status_code(200)
      .add_header("Content-Type", content_type)
      .set_body(response_body)
      .build

    setup_filters(request.path)
    @filter_chain.reset
    @filter_chain.execute(request, response)

    send_response(client, response)
    puts "Response sent"
  rescue => e
    handle_error(client, e)
  ensure
    client.close
  end

  def parse_request(client)
    first_line = client.gets
    puts "Received request: #{first_line}"
    return unless first_line

    method, path, _ = first_line.strip.split(' ')
    builder = RequestBuilder.new
      .set_method(method)
      .set_path(path)

    content_length = 0
    while (line = client.gets.strip) && !line.empty?
      key, value = line.split(': ', 2)
      builder.add_header(key, value)
      content_length = value.to_i if key.downcase == 'content-length'
    end

    if content_length > 0
      body = client.read(content_length)
      builder.set_body(body)
    end

    builder.build
  end

  def setup_filters(path)
    @filter_chain = FilterChain.new
    FilterFactory.create_filters(path).each do |filter|
      @filter_chain.add_filter(filter)
      puts "Added filter: #{filter.class}"
    end
  end

  def send_response(client, response)
    response.body ||= "Empty response"
    
    client.puts "HTTP/1.1 #{response.status_code} OK"
    
    response.headers['Content-Length'] ||= response.body.bytesize.to_s
    
    response.headers.each do |key, value|
      client.puts "#{key}: #{value}"
    end
    
    client.puts ""
    
    client.puts response.body
    client.flush
  end

  def handle_error(client, error)
    puts "Error: #{error.message}"
    puts error.backtrace.join("\n")
    
    response = ResponseBuilder.new
      .set_status_code(500)
      .add_header('Content-Type', 'text/plain')
      .add_header('Content-Length', '21')
      .set_body("Internal Server Error\n")
      .build
    
    send_response(client, response)
  end

  def cacheable_response?(response)
    return false unless (200..299).include?(response.status_code)
    
    cache_control = response.headers['Cache-Control']
    return false if cache_control && 
      (cache_control.include?('no-store') || cache_control.include?('private'))
    
    response.headers['X-Cache'] = 'MISS'
    
    true
  end

  def compress_response(request, response)
    return unless response.body

    body_string = response.body.is_a?(Hash) ? response.body.to_json : response.body.to_s

    output = StringIO.new
    gz = Zlib::GzipWriter.new(output)
    gz.write(body_string)
    gz.close

    response.body = output.string
    response.headers['Content-Encoding'] = 'gzip'
    response.headers['Content-Length'] = response.body.bytesize.to_s
    response.headers['Vary'] = 'Accept-Encoding'
  end
end

puts "Starting server with filters from FilterFactory..."
server = HTTPServer.new
server.start