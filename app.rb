require 'tilt/erb'
require 'sinatra'

configure do
  set :static_cache_control, [:no_cache, :no_store, :must_revalidate, max_age: 0]
end

get '/' do
  erb :index
end

get '/dashboard.html' do
  erb :dashboard
end


get '/progress.html' do
  <<-HTML
    <!DOCTYPE HTML>
    <html lang="en-US">
    <head>
      <meta charset="UTF-8">
    </head>
    <body>
      <img src="https://s3.amazonaws.com/fordham-givingday/progress-bar.png" width="630"><br />
      <img src="https://s3.amazonaws.com/fordham-givingday/stats.png" width="440"><br />
      <img src="https://s3.amazonaws.com/fordham-givingday/top-years.png" width="630"><br />
      <img src="https://s3.amazonaws.com/fordham-givingday/top-areas.png" width="630">
    </body>
    </html>
  HTML
end