require 'open-uri'
require 'net/http'
require 'sinatra'
require 'nokogiri'

get '/progress.css' do
  content_type 'text/css'
  url = ENV.fetch('GIVECAMPUS_URL')
  data = Nokogiri::HTML(open(url))

  donors = data.css(ENV.fetch('DONORS_PATH'))[0].content.strip
  goal = data.css(ENV.fetch('GOAL_PATH'))[0].content.strip
  raised = data.css(ENV.fetch('RAISED_PATH'))[0].content.strip

  <<-CSS
    .progress {
      line-height: 1.6
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
      animation: slideright 1s ease-out;
      transform-origin: top left;
    }
    .progress .goal-text:after {
      content: "#{goal} of donor goal";
    }
    .progress .raised:after {
      content: "#{raised} donated";
    }
    @keyframes slideright {
      0% {
        transform: scaleX(0);
      }
      100% {
        transform: scaleX(100%);
      }
    }
  CSS
end

get '/' do
  erb :layout
end