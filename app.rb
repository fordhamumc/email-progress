require 'tilt/erb'
require 'sinatra'

configure do
  set :static_cache_control, [:no_cache, :no_store, :must_revalidate, max_age: 0]
end

get '/' do
  erb :layout
end


get '/progress.html' do
  <<-HTML
    <!DOCTYPE HTML>
    <html lang="en-US">
    <head>
      <meta charset="UTF-8">
    </head>
    <body>
      <img src="progress-bar.png" width="630"><br />
      <img src="stats.png" width="630"><br />
      <img src="top-years.png" width="630"><br />
      <img src="top-areas.png" width="630">
    </body>
    </html>
  HTML
end