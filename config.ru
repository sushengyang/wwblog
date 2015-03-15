# http://www.randomerrata.com/articles/2013/middleman-on-heroku/
require "rubygems"

require "rack"
require "middleman/rack"
require "rack/contrib/try_static"

`bundle exec middleman build`

# Enable proper HEAD responses
use Rack::Head

# Attempt to serve static HTML files
use Rack::TryStatic,
  :root => "build",
  :urls => %w[/],
  :try => ['.html', 'index.html', '/index.html']

# Serve a 404 page if all else fails
run lambda { |env|
  [
    404,
    {
      "Content-Type" => "text/html",
      "Cache-Control" => "public, max-age=60"
    },
    File.open("build/404/index.html", File::RDONLY)
  ]
}
