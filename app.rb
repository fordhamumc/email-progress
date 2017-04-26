require 'tilt/erb'
require 'sinatra'

configure do
  set :static_cache_control, [:no_cache, :no_store, :must_revalidate, max_age: 0]
end


get '/' do
  @bucket = ENV.fetch('AWS_BUCKET')
  erb :index
end

get '/dashboard.html' do
  @bucket = ENV.fetch('AWS_BUCKET')
  erb :dashboard
end

get '/progress.html' do
  @bucket = ENV.fetch('AWS_BUCKET')
  <<-HTML
    <!DOCTYPE HTML>
    <html lang="en-US">
    <head>
      <meta charset="UTF-8">
    </head>
    <body>
      <img src="https://s3.amazonaws.com/#{@bucket}/progress-bar.png" width="630"><br />
      <img src="https://s3.amazonaws.com/#{@bucket}/stats.png" width="440"><br />
      <img src="https://s3.amazonaws.com/#{@bucket}/top-years.png" width="630"><br />
      <img src="https://s3.amazonaws.com/#{@bucket}/top-areas.png" width="630">
    </body>
    </html>
  HTML
end