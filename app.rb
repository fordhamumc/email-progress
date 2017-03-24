require 'open-uri'
require 'tilt/erb'
require 'sinatra'
require 'nokogiri'
require 'screencap'

configure do
  set :static_cache_control, [:no_cache, :no_store, :must_revalidate, max_age: 0]
end

class Leaderboard

  def initialize(query, leaderboards)
    @leaderboard = reduce(query, leaderboards)
  end

  def reduce(search, arr)
    arr.map do |lb|
      if lb.at_css('caption > text()').content.strip.downcase == search
        lb.css('tbody tr').map do |item|
          {
            'name' => child(1, item),
            'donors' => child(2, item),
            'dollars' => child(3, item)
          }
        end
      end
    end.compact[0] || []
  end

  def child(num, arr)
    arr.at_css("td:nth-child(#{num})").content.strip
  end

  def sort(column, dir = 'desc')
    @leaderboard.sort! do |a,b|
      a,b = b,a if dir == 'desc'
      a[column].gsub(/\D/,'').to_i <=> b[column].gsub(/\D/,'').to_i
    end
    self
  end

  def css(namespace, num = 5)
    lb = if num > 0 then @leaderboard.take(num) else @leaderboard end

    lb.map.with_index do |item, i|
      result = ''
      item.each do |key, value|
        result << "
          #lb-#{namespace}-#{i + 1} .#{key}:after {
            content: '#{value}';
          }
        "
      end
      result
    end.join("\n")
  end

end


get '/progress.css' do
  content_type 'text/css'
  expires 0, :no_cache, :no_store, :must_revalidate
  url = ENV.fetch('GIVECAMPUS_URL')
  data = Nokogiri::HTML(open(url))

  donors = data.at_css(ENV.fetch('DONORS_PATH')).content.strip
  goal = data.at_css(ENV.fetch('GOAL_PATH')).content.strip
  raised = data.at_css(ENV.fetch('RAISED_PATH')).content.strip
  leaderboards = data.css(ENV.fetch('LEADERBOARD_PATH'))

  leaderboard_class = Leaderboard.new(ENV.fetch('LEADERBOARDITEM_CLASS'), leaderboards)
  leaderboard_scholarships = Leaderboard.new(ENV.fetch('LEADERBOARDITEM_SCHOLARSHIP'), leaderboards)

  <<-CSS
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

    #{leaderboard_class.sort('donors').css('class')}

    #{leaderboard_scholarships.sort('dollars').css('scholarship')}


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
    .webkit-hide {
      display: none !important;
    }
  CSS

end

get '/' do
  erb :layout
end


get '/progress.html' do
  f = Screencap::Fetcher.new(ENV.fetch('SCREENSHOT_URL'))
  screenshot = f.fetch(
      :output => './public/progress.png',
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
      <img src="progress.png" width="304">
    </body>
    </html>
  HTML
end