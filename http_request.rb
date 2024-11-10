class HTTPRequest
  attr_accessor :method, :path, :headers, :body

  def initialize
    @headers = {}
    @body = nil
  end
end 