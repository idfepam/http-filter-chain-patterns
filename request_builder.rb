require_relative 'http_request'

class RequestBuilder
  def initialize
    @request = HTTPRequest.new
  end

  def set_method(method)
    @request.method = method
    self
  end

  def set_path(path)
    @request.path = path
    self
  end

  def add_header(key, value)
    @request.headers[key] = value
    self
  end

  def set_body(content)
    @request.body = content
    self
  end

  def build
    @request
  end
end 