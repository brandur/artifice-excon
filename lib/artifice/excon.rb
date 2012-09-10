require "excon"
require "rack/test"

module Artifice
  module Excon
    EXCON_CONNECTION = ::Excon::Connection

    # Activate an endpoint for a specific host. The host has both scheme and
    # port omitted.
    #
    #     activate_for('google.com', rack_endpoint)
    def self.activate_for(host, endpoint)
      Excon::Connection.endpoints[host] = endpoint

      # activate only after the first stub is added
      replace_connection(Artifice::Excon::Connection) \
        if Excon::Connection.endpoints.count == 1

      if block_given?
        begin
          yield
        ensure
          deactivate_for(host)
        end
      end
    end

    # Deactivate an endpoint for a specific host.
    def self.deactivate_for(host)
      Excon::Connection.endpoints.delete(host)

      # deactivate fully after the last stub is gone
      replace_connection(EXCON_CONNECTION) \
        if Excon::Connection.endpoints.count == 0
    end

    # Activate a default endpoint to which all requests will be routed (unless
    # a more specific host endpoint is active).
    def self.activate_with(endpoint, &block)
      activate_for(:default, endpoint, &block)
    end

    # Deactivate all endpoints including the default and all host-specific
    # endpoints as well.
    def self.deactivate
      Excon::Connection.endpoints.clear
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
        def endpoints
          @endpoints ||= {}
        end
      end

      def request_kernel(params)
        endpoint = self.class.endpoints[params[:host]] ||
          self.class.endpoints[:default]
        return super unless endpoint

        rack_request = RackRequest.new(endpoint)

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
