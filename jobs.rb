require 'sinatra'
require 'open-uri'
require 'sidekiq'
require 'nokogiri'
require 'screencap'
require 'aws-sdk'
require './lib/leaderboard'

Sidekiq.configure_client do |config|
  config.redis = {db: 1}
end

Sidekiq.configure_server do |config|
  config.redis = {db: 1}
end

class Jobs
  include Sidekiq::Worker

  def self.css
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
        text-align: center;
      }
      .progress-stats .amount {
        display: inline-block;
        text-align: center;
        padding: 0 10px;
      }
      .progress-stats .amount:before,
      .progress-stats .amount:after { display: inline-block; }
      .progress-stats .amount:after {
        color: #888888;
        text-transform: uppercase;
        padding: 0 5px;
      }
      .progress-stats .amount:before { font-size: 37px; }
  
      .progress-stats .total-donors:before { content: "#{donors}"; }
      .progress-stats .total-donors:after { content: "Donors"; }
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

    File.open('./tmp/progress.css', 'w') {|f| f.write(output) }

    s3 = Aws::S3::Resource.new(region: ENV.fetch('AWS_REGION'))
    file = './tmp/progress.css'
    name = File.basename(file)
    obj = s3.bucket(ENV.fetch('AWS_BUCKET')).object(name)
    obj.upload_file(file, acl:'public-read')
  end

  def self.screenshot
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
end