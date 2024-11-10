require_relative 'http_response'

class ResponseBuilder
  def initialize
    @response = HTTPResponse.new
  end

  def set_status_code(code)
    @response.status_code = code
    self
  end

  def add_header(key, value)
    @response.headers[key] = value
    self
  end

  def set_body(content)
    @response.body = content
    self
  end

  def build
    @response
  end
end 