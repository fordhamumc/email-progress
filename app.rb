require 'open-uri'
require 'tilt/erb'
require 'sinatra'
require 'nokogiri'
require 'screencap'

configure do
  set :static_cache_control, [:no_cache, :no_store, :must_revalidate, max_age: 0]
end

get '/progress.css' do
  content_type 'text/css'
  expires 0, :no_cache, :no_store, :must_revalidate
  url = ENV.fetch('GIVECAMPUS_URL')
  data = Nokogiri::HTML(open(url))

  donors = data.css(ENV.fetch('DONORS_PATH'))[0].content.strip
  goal = data.css(ENV.fetch('GOAL_PATH'))[0].content.strip
  raised = data.css(ENV.fetch('RAISED_PATH'))[0].content.strip

  <<-CSS
    .progress {
      display: inline-block;
      line-height: 1.6;
    }
    .progress .donors:after {
      content: "#{donors} donors";
    }
    .progress .goal {
      border: 2px solid #555555;
      height: 30px;
      width: 300px;
    }
    .progress .goal-slider {
      background-color: #900028;
      height: 100%;
      width: #{[goal.to_f, 100].min}%;
      -webkit-animation: slideright 1s ease-out;
      animation: slideright 1s ease-out;
      transform-origin: top left;
    }
    .progress .goal-text:after {
      content: "#{goal} of donor goal";
    }
    .progress .raised:after {
      content: "#{raised} donated";
    }
    @-webkit-keyframes slideright {
      0% {
        transform: scaleX(0);
      }
      100% {
        transform: scaleX(100%);
      }
    }
    @keyframes slideright {
      0% {
        transform: scaleX(0);
      }
      100% {
        transform: scaleX(100%);
      }
    }
    @media screen and (-webkit-min-device-pixel-ratio: 0) {
      .webkit-hide {
        display: none !important;
      }
    }
  CSS
end

get '/' do
  erb :layout
end


get '/progress.html' do
  f = Screencap::Fetcher.new(ENV.fetch('SCREENSHOT_URL'))
  screenshot = f.fetch(
      :output => '.public/progress.png',
      :div => '.progress'
  )
  <<-HTML
    <!DOCTYPE HTML>
    <html lang="en-US">
    <head>
      <meta charset="UTF-8">
    </head>
    <body>
      new screenshot created<br />
      <img src="progress.png">
    </body>
    </html>
  HTML
end