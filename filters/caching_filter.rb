require_relative '../filter'
require 'digest'

class CachingFilter < Filter
  @cache = {}  # Class-level cache
  @cache_ttl = 600  # 10 minutes default TTL for testing

  class << self
    attr_accessor :cache, :cache_ttl
  end

  def process(request, response, chain)
    return unless cacheable_request?(request)

    cache_key = generate_cache_key(request)
    puts "\nCache Status:"
    puts "------------"
    puts "Key: #{cache_key}"
    puts "Current Keys in Cache: #{self.class.cache.keys.join(', ')}"

    if cached_response = get_cached_response(cache_key)
      puts "Result: Cache HIT"
      copy_cached_response(cached_response, response)
    else
      puts "Result: Cache MISS"
      response.headers['X-Cache'] = 'MISS'
      chain.execute(request, response)
      if cacheable_response?(response)
        cache_response(cache_key, response)
        puts "Action: Response cached"
      end
    end
    puts
  end

  private

  def cacheable_request?(request)
    return false unless request.method == 'GET'
    
    cache_control = request.headers['Cache-Control']
    return false if cache_control && cache_control.include?('no-store')
    
    true
  end

  def cacheable_response?(response)
    return false unless (200..299).include?(response.status_code)
    
    cache_control = response.headers['Cache-Control']
    return false if cache_control && 
      (cache_control.include?('no-store') || cache_control.include?('private'))
    
    response.headers['X-Cache'] = 'MISS'
    
    true
  end

  def generate_cache_key(request)
    components = [
      request.method,
      request.path,
      request.headers['Accept'],
      request.headers['Accept-Encoding']
    ]
    
    Digest::MD5.hexdigest(components.compact.join('|'))
  end

  def get_cached_response(key)
    cached = self.class.cache[key]
    return nil unless cached
    
    return nil if Time.now.to_i > cached[:expires_at]
    
    cached[:response]
  end

  def cache_response(key, response)
    self.class.cache[key] = {
      response: clone_response(response),
      expires_at: Time.now.to_i + get_ttl(response)
    }
  end

  def get_ttl(response)
    if response.headers['Cache-Control']&.match(/max-age=(\d+)/)
      $1.to_i
    else
      self.class.cache_ttl
    end
  end

  def copy_cached_response(cached_response, response)
    response.status_code = cached_response.status_code
    response.headers = cached_response.headers.dup
    response.body = cached_response.body.dup
    
    response.headers['X-Cache'] = 'HIT'
    response.headers['X-Cache-Timestamp'] = Time.now.to_i.to_s
  end

  def clone_response(response)
    cloned = HTTPResponse.new
    cloned.status_code = response.status_code
    cloned.headers = response.headers.dup
    cloned.body = response.body.dup
    
    cloned.headers['X-Cache'] = 'MISS'
    cloned
  end
end 