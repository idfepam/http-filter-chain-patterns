require_relative '../filter'
require 'json'
require 'nokogiri'

class DataTransformationFilter < Filter
  def process(request, response, chain)
    transform_request(request) if request.body
    chain.execute(request, response)
    transform_response(response) if response.body
  end

  private

  def transform_request(request)
    content_type = request.headers['Content-Type']
    
    case content_type
    when 'application/json'
      request.body = JSON.parse(request.body) rescue request.body
    when 'application/xml'
      request.body = Nokogiri::XML(request.body) rescue request.body
    end
  end

  def transform_response(response)
    content_type = response.headers['Content-Type']
    
    case content_type
    when 'application/json'
      response.body = response.body.to_json unless response.body.is_a?(String)
      response.headers['Content-Length'] = response.body.bytesize.to_s

    end
  end
end 