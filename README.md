artifice-excon
==============

Artifice allows you to replace remote HTTP/HTTPS calls with a stub that routes
all requests to a Rack application. This version integrates with the
[Excon](https://github.com/geemus/excon) instead of the Net:HTTP subsystem that
[Wycat's original gem](https://github.com/wycats/artifice) provides.

Remote service stubs can be constructed using Sinatra, raw Rack, or even Rails,
allowing you to leverage familiar and conveninent tools.

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
Artifice::Excon.activate_with(rack_endpoint)</pre>

# an extremely basic example
app = proc do |env|
  [200, {}, "Hello, world!"]
end
Artifice::Excon.activate_with(app)</pre>
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
