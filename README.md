artifice-excon
==============

Artifice allows you to replace remote HTTP/HTTPS calls with a stub that routes
all requests to a Rack application. This version integrates with
[Excon](https://github.com/geemus/excon) instead of the Net:HTTP subsystem that
[Wycat's original gem](https://github.com/wycats/artifice) provides.

Remote service stubs can be constructed using Sinatra, raw Rack, or even Rails,
allowing you to leverage familiar and convenient tools.

Usage
-----

Bundle artifice-excon in your `Gemfile`:

``` ruby
gem 'artifice-excon'
```

Use `Bundle.require` or require it manually:

``` ruby
require 'artifice/excon'
```

Next, activate artifice-excon by passing in a Rack endpoint:

``` ruby
Artifice::Excon.activate_with(rack_endpoint)

# an extremely basic example
app = proc do |env|
  [200, {}, "Hello, world!"]
end
Artifice::Excon.activate_with(app)
```

And finally, deactivate it again:

``` ruby
Artifice::Excon.deactivate
```

Alternatively, pass a block to `activate_with` to keep stub requests for the duration of the block only:


``` ruby
Artifice.activate_with(rack_endpoint) do
  Excon.get("https://google.com")
end
```

### Host-based Activation

A feature present in artifice-excon that isn't in the original is host-based
endpoint activation, so that a particular rack app can be activated for a
particular host. This is useful in case you have an app that potentially needs
to speak to multiple services with different APIs.

``` ruby
Artifice::Excon.activate_for('google.com', google_endpoint)

# a catch-all is still allowed! but a registered host-specific endpoint will
# always take preference
Artifice::Excon.activate_with(rack_endpoint)
```

Once again, deactivate for a particular host or everything:

``` ruby
Artifice.deactivate_for('google.com')

# deactivates all registered endpoints including host-specific and global
Artifice.deactivate
```

Development
-----------

Run tests using:

```
rake test
```
