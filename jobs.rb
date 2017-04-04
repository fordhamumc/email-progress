require 'open-uri'
require 'sinatra'
require 'nokogiri'
require 'screencap'
require './lib/leaderboard'


job 'css' do
  url = ENV.fetch('GIVECAMPUS_URL')
  data = Nokogiri::HTML(open(url))

  donors = data.at_css(ENV.fetch('DONORS_PATH')).content.strip
  goal = data.at_css(ENV.fetch('GOAL_PATH')).content.strip
  goalmin = [goal.to_f, 100].min
  raised = data.at_css(ENV.fetch('RAISED_PATH')).content.strip

  leaderboards = data.css(ENV.fetch('LEADERBOARD_PATH'))
  leaderboard_class = Leaderboard.new(ENV.fetch('LEADERBOARDITEM_CLASS'), leaderboards).strip('name', /\D/).sort('donors')
  leaderboard_scholarships = Leaderboard.new(ENV.fetch('LEADERBOARDITEM_SCHOLARSHIP'), leaderboards).sort('dollars')

  output = <<-CSS
    /* Updated: #{Time.new.inspect} */

    .progress-stats .total-donors:before { content: "#{donors}"; }
    .progress-stats .total-donors:after { content: "Donors"; }
    .progress-bar {
      border: 2px solid #555555;
      height: 30px;
      margin: 0 auto 7px;
    }
    .progress-bar .bar {
      background-color: #900028;
      height: 100%;
      width: #{goalmin}%;
      -webkit-animation: slideright #{[(goalmin.to_f / 100), 0.2].max}s ease-out;
      animation: slideright #{[(goalmin.to_f / 100), 0.2].max}s ease-out;
      transform-origin: top left;
    }
    .progress-label { text-align: center; }
    .progress-label:after { content: "#{goal} of donor goal"; }

    .progress-stats {
      display: -webkit-flex;
      display: -ms-flexbox;
      display: flex;
      -webkit-justify-content: space-around;
      -ms-flex-pack: distribute;
      justify-content: space-around;
      margin-top: 50px;
    }
    .progress-stats .amount {
      text-align: center;
      width: 50%;
    }
    .progress-stats .amount:before,
    .progress-stats .amount:after { display: block; }
    .progress-stats .amount:after {
      color: #888888;
      text-transform: uppercase;
    }
    .progress-stats .amount:before { font-size: 50px; }
    .progress-stats .total-donors { border-right: 1px solid #cccccc; }
    .progress-stats .total-dollars:before { content: "#{raised}"; }
    .progress-stats .total-dollars:after { content: "Raised"; }

    .progress-table td{ padding: 10px; }
    .progress-table th { padding: 0 10px; }
    .progress-table th.name:after { content: 'Name' }
    .progress-table th.donors:after { content: 'Donors' }
    .progress-table th.dollars:after { content: 'Dollars' }
    .progress-table .name { width: 60%; }
    .progress-table .alt { background-color: #e5e5e3; }
    #{leaderboard_class.css('class')}
    #{leaderboard_scholarships.css('support')}

    @-webkit-keyframes slideright {
      0% { transform: scaleX(0); }
      100% { transform: scaleX(100%); }
    }
    @keyframes slideright {
      0% { transform: scaleX(0); }
      100% { transform: scaleX(100%); }
    }
    .webkit-hide { display: none !important; }
  CSS

  File.open('./public/progress.css', 'w') {|f| f.write(output) }

end

job 'screenshot' do
  f = Screencap::Fetcher.new(ENV.fetch('SCREENSHOT_URL'))
  progressbar = f.fetch(
      :output => './public/progress-bar.png',
      :div => '#progress-bar'
  )
  stats = f.fetch(
      :output => './public/stats.png',
      :div => '#progress-stats'
  )
  topyears = f.fetch(
      :output => './public/top-years.png',
      :div => '#participation-class'
  )
  topareas = f.fetch(
      :output => './public/top-areas.png',
      :div => '#participation-areas'
  )
end