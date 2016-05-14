require "httpi/adapter/base"
require "httpi/response"

class Patron::HTTPIAdapter < HTTPI::Adapter::Base

  register :patron, :deps => ['patron']
  
  def initialize(request)
    @request = request
    @session = Patron::Session.new
  end

  def client
    @session
  end

  def request(method)
    unless Patron::Request::VALID_ACTIONS.include?(method.to_s.upcase)
      raise NotSupportedError, "Curb does not support custom HTTP methods"
    end

    if @request.on_body 
      raise NotSupportedError, "Patron does not support streaming responses"
    end
    
    url = @request.url.to_s
    request_body = @request.body || ""
    
    do_request { |client| client.request(method, url, @request.headers, :data => request_body) }
  rescue Patron::UnsupportedSSLVersion
    raise SSLError
  rescue Patron::ConnectionFailed  # connection refused
    $!.extend ConnectionError
    raise
  end

  private

  def do_request
    setup_client
    patron_response = yield(@session)
    respond_with(patron_response)
  end

  def setup_client
    basic_setup

    raise NotSupportedError, "Patron does not support NTLM auth" if @request.auth.ntlm?
    raise NotSupportedError, "Patron does not support GSS auth" if @request.auth.gssnegotiate?
    
    setup_http_auth if @request.auth.http?
    setup_ssl_auth if @request.auth.ssl? || @request.ssl?
  end

  def basic_setup
    @session.proxy_url = @request.proxy.to_s if @request.proxy
    @session.timeout = @request.read_timeout if @request.read_timeout
    @session.connect_timeout = @request.open_timeout if @request.open_timeout
    @session.headers = @request.headers.to_hash
    # cURL workaround
    # see: http://stackoverflow.com/a/10755612/102920
    #      https://github.com/typhoeus/typhoeus/issues/260
    # @session.set(:NOSIGNAL, true)
  end

  def setup_http_auth
    @session.auth_type = :basic # @request.auth.type
    @session.username, @session.password = *@request.auth.credentials
  end

  def setup_ssl_auth
    ssl = @request.auth.ssl

    if @request.auth.ssl?
      if ssl.verify_mode == :none
        @session.insecure = true
      else
        @session.cacert = ssl.ca_cert_file if ssl.ca_cert_file
        #@session.certtype = ssl.cert_type.to_s.upcase
      end

      raise NotSupportedError, "Patron does not support client certificates" if ssl.cert_key_file
      raise NotSupportedError, "Patron does not support client certificates" if ssl.cert_file

      # @session.ssl_verify_peer = ssl.verify_mode == :peer
    end

    begin
      @session.ssl_version = ssl.ssl_version.to_s
    rescue Patron::UnsupportedSSLVersion => e
      raise NotSupportedError, e.message
    end 
  end

  def respond_with(patron_response)
    ::HTTPI::Response.new(patron_response.status, patron_response.headers, patron_response.body)
  end
end
