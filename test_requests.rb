require 'net/http'
require 'json'
require 'zlib'
require 'stringio'

def test_server
  base_uri = URI('http://localhost:3000')

  # Test 1: Basic JSON API request
  puts "\nTest 1: JSON API Request"
  uri = URI(base_uri.to_s + '/api/data')
  req = Net::HTTP::Post.new(uri)
  req['Content-Type'] = 'application/json'
  req['Accept'] = 'application/json'
  req.body = { name: 'Serhii', age: 20 }.to_json

  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end
  puts "Response: #{response.body}"
  puts "Headers: #{response.to_hash}"

  # Test 2: Test Compression with larger payload
  puts "\nTest 2: Compression Test"
  uri = URI(base_uri.to_s + '/api/large-data')
  req = Net::HTTP::Post.new(uri)
  req['Content-Type'] = 'application/json'
  req['Accept-Encoding'] = 'gzip'

  # Create a large payload that would benefit from compression
  large_data = {
    data: Array.new(100) { |i| 
      {
        id: i,
        title: "Item #{i}",
        description: "Test #{i} Test Test Test Test Test Test Test Test Test Test . " * 3,
        tags: ["test1", "test2", "test3"],
        metadata: {
          created_at: Time.now.to_s,
          updated_at: Time.now.to_s,
          status: "active"
        }
      }
    }
  }

  req.body = large_data.to_json
  puts "Request body size: #{req.body.bytesize} bytes"

  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end
  puts "Content-Encoding: #{response['Content-Encoding']}"

  if response['Content-Encoding'] == 'gzip'
    sio = StringIO.new(response.body)
    gz = Zlib::GzipReader.new(sio)
    decompressed_body = gz.read
    gz.close
    puts "Original Size: #{decompressed_body.bytesize} bytes"
    puts "Compressed Size: #{response.body.bytesize} bytes"
    puts "Compression Ratio: #{((1 - response.body.bytesize.to_f / decompressed_body.bytesize) * 100).round(2)}%"
  end

  # Test 3: Test Caching
  puts "\nTest 3: Caching Test"
  uri = URI(base_uri.to_s + '/static/data.json')
  2.times do |i|
    response = Net::HTTP.get_response(uri)
    puts "Request #{i + 1} - X-Cache: #{response['X-Cache']}"
  end
end

test_server 