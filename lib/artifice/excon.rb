module Artifice
  module Excon
    EXCON_CONNETION = ::Excon::Connection

    def self.activate_with(endpoint)
      Excon::Connection.endpoint = endpoint
      replace_connection(Artifice::Excon::Connection)

      if block_given?
        begin
          yield
        ensure
          deactivate
        end
      end
    end

    # Deactivate the Artifice replacement.
    def self.deactivate
      replace_connection(EXCON_CONNECTION)
    end

  private

    def self.replace_connection(value)
      ::Excon.class_eval do
        remove_const(:Connection)
        const_set(:Connection, value)
      end
    end

    # This is an internal object that can receive Rack requests
    # to the application using the Rack::Test API
    class RackRequest
      include Rack::Test::Methods
      attr_reader :app

      def initialize(app)
        @app = app
      end
    end

    class Connection < ::Excon::Connection
      class << self
        attr_accessor :endpoint
      end

      def request_kernel(params)
        rack_request = RackRequest.new(self.class.endpoint)

        params[:headers].each do |header, value|
          rack_request.header(header, value)
        end if params[:headers]

        request = "#{params[:scheme]}://#{params[:host]}:#{params[:port]}"
        request << params[:path]
        request << query_string(params[:query])

        response = rack_request.request(request,
          { :method => params[:method], :input => params[:body] })

        ::Excon::Response.new(:body => response.body,
          :headers => response.headers, :status => response.status)
      end

    private

      def query_string(query)
        query_string = ""
        case query
        when String
          query_string << '?' << query
        when Hash
          query_string << '?'
          query.each do |key, values|
            if values.nil?
              query_string << key.to_s << '&'
            else
              [*values].each do |value|
                query_string << key.to_s << '=' << CGI.escape(value.to_s) << '&'
              end
            end
          end
          query_string.chop! # remove trailing '&'
        end
        query_string
      end
    end
  end
end
