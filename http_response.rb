class HTTPResponse
  attr_accessor :status_code, :headers, :body

  def initialize
    @status_code = 200
    @headers = {}
    @body = nil
  end
end 