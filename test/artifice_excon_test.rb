require "bundler/setup"
Bundler.require

require "minitest/spec"
require "minitest/autorun"

require "artifice/excon"

describe Artifice::Excon do
  EXCON_CONNECTION = ::Excon::Connection

  FakeApp = proc do |env|
    #require "debugger" ; debugger
    [200, {"Content-Type"  => "text/html",
           "X-Test-Method" => env["REQUEST_METHOD"],
           "X-Test-Input"  => env["rack.input"].read,
           "X-Test-Scheme" => env["rack.url_scheme"],
           "X-Test-Host"   => env["SERVER_NAME"],
           "X-Test-Port"   => env["SERVER_PORT"],
           "X-Test-Query"  => env["QUERY_STRING"]},
      ["Hello, world!"]
    ]
  end

  describe "before activating" do
    it "does not override Excon::HTTP" do
      ::Excon::Connection.must_equal EXCON_CONNECTION
    end
  end

  describe "when activating without a block" do
    after do
      Artifice::Excon.deactivate
      ::Excon::Connection.must_equal EXCON_CONNECTION
    end

    before do
      Artifice::Excon.activate_with(FakeApp)
    end

    it "replaces Excon::Connection" do
      ::Excon::Connection.wont_equal EXCON_CONNECTION
    end

    describe "HTTP POST request" do
      before do
        @response = Excon.post('http://google.com/index', :body => "foo=bar")
      end

      it "sends the method properly" do
        @response.headers["X-Test-Method"].must_equal "POST"
      end

      it "sends the input properly" do
        @response.headers["X-Test-Input"].must_equal "foo=bar"
      end
    end

    describe "HTTP GET request" do
      before do
        @response = Excon.get('http://google.com/index', :query => { :foo => 'bar' })
      end

      it "sends the method properly" do
        @response.headers["X-Test-Method"].must_equal "GET"
      end

      it "sends the input properly" do
        @response.headers["X-Test-Query"].must_equal "foo=bar"
      end
    end

    describe "HTTP scheme" do
      before do
        @response = Excon.post('http://google.com/index')
      end

      it "sends the scheme properly" do
        @response.headers["X-Test-Scheme"].must_equal "http"
      end

      it "sends the port properly" do
        @response.headers["X-Test-Port"].must_equal "80"
      end
    end

    describe "HTTPS scheme" do
      before do
        @response = Excon.post('https://google.com/index')
      end

      it "sends the scheme properly" do
        @response.headers["X-Test-Scheme"].must_equal "https"
      end

      it "sends the port properly" do
        @response.headers["X-Test-Port"].must_equal "443"
      end
    end
  end

  describe "when activating with a block" do
    before do
      ::Excon::Connection.must_equal EXCON_CONNECTION
    end

    after do
      ::Excon::Connection.must_equal EXCON_CONNECTION
    end

    it "deactivates automatically after the block is executed" do
      Artifice::Excon.activate_with( lambda {} ) do
        ::Excon::Connection.wont_equal EXCON_CONNECTION
      end
    end

    it "deactivates even if an exception is raised from within the block" do
      lambda {
        Artifice::Excon.activate_with( lambda {} ) do
          ::Excon::Connection.wont_equal EXCON_CONNECTION
          raise 'Boom!'
        end
      }.must_raise RuntimeError
    end
  end

  describe "for a particular host" do
    after do
      Artifice::Excon.deactivate
      ::Excon::Connection.must_equal EXCON_CONNECTION
    end

    before do
      Artifice::Excon.activate_for('google.com', FakeApp)
    end

    it "sends the request properly" do
      @response = Excon.get('http://google.com/index')
      @response.headers["X-Test-Method"].must_equal "GET"
    end

    it "supports hosts with scheme as well" do
      Artifice::Excon.activate_for('http://example.com', FakeApp)
      @response = Excon.get('http://google.com/index')
      @response.headers["X-Test-Method"].must_equal "GET"
    end

    it "can be deactivated" do
      Artifice::Excon.deactivate_for('google.com')
      ::Excon::Connection.must_equal EXCON_CONNECTION
    end

    it "stays active, even after other hosts are activated and deactivated" do
      Artifice::Excon.activate_for(:default, FakeApp)
      Artifice::Excon.deactivate_for(:default)
      ::Excon::Connection.wont_equal EXCON_CONNECTION
    end

    it "still clears everything on global deactivate" do
      Artifice::Excon.deactivate
      ::Excon::Connection.must_equal EXCON_CONNECTION
    end
  end
end
