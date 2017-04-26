require 'sinatra'
require 'open-uri'
require 'sidekiq'
require 'nokogiri'
require 'screencap'
require 'aws-sdk'
require 'redis'
require './lib/leaderboard'

Sidekiq.configure_client do |config|
  config.redis = {db: 1}
end

Sidekiq.configure_server do |config|
  config.redis = {db: 1}
end


def awsupload(file, type = 'image/png', cache = 'no-cache, no-store, must-revalidate')
  s3 = Aws::S3::Resource.new(region: ENV.fetch('AWS_REGION'))
  name = File.basename(file)
  obj = s3.bucket(ENV.fetch('AWS_BUCKET')).object(name)
  obj.upload_file(file, acl:'public-read', content_type: type, cache_control: cache)
end

def cachedata(name, data, redis)
  if data != redis.get(name) || !redis.exists("#{name}_change")
    puts "#{name} changed"
    redis.mset(name, data, "#{name}_change", Time.new.to_i, "#{name}_screenshot", true)
  end
end

class Jobs
  include Sidekiq::Worker
  @redis = Redis.new

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

    cachedata('lb_class', leaderboard_class.to_json, @redis)
    cachedata('lb_scholarships', leaderboard_scholarships.to_json, @redis)
    cachedata('donors', donors, @redis)
    cachedata('goal', goal, @redis)
    cachedata('raised', raised, @redis)


    if [@redis.get('lb_class_change'),
         @redis.get('lb_scholarships_change'),
         @redis.get('donors_change'),
         @redis.get('goal_change'),
         @redis.get('raised_change')].all? {|t| t.to_i <= @redis.get('css_change').to_i}
      puts 'Data are unchanged.'
    else
      @redis.set('css_change', Time.new.to_i)
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
        .progress-label:after { content: "#{goal} of donor goal"; }
    
        .progress-stats {
          max-width: 440px;
          margin-bottom: 10px;
        }
        .progress-stats .amount {
          display: inline-block;
          text-align: center;
          padding-right: 20px;
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
        #participation-class th.name:after { content: 'Class' }
        #participation-areas th.name:after { content: 'Fund' }
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

      puts 'Uploading new stylesheet'
      File.open('./tmp/progress.css', 'w') {|f| f.write(output) }
      awsupload('./tmp/progress.css', 'text/css')
    end
  end

  def self.screenshot
    f = Screencap::Fetcher.new(ENV.fetch('SCREENSHOT_URL'))
    if @redis.get('goal_screenshot') == 'true'
      puts 'Generating new progress bar screenshot'
      progressbar = f.fetch(
          :output => './tmp/progress-bar.png',
          :div => '#progress-bar'
      )
      awsupload(progressbar)
      @redis.set('goal_screenshot', false)
    end

    if @redis.get('donors_screenshot') == 'true' || @redis.get('raised_screenshot') == 'true'
      puts 'Generating new overall stats screenshot'
      stats = f.fetch(
          :output => './public/stats.png',
          :div => '#progress-stats'
      )
      awsupload(stats)
      @redis.set('donors_screenshot', false)
      @redis.set('raised_screenshot', false)
    end


    if @redis.get('lb_class_screenshot') == 'true'
      puts 'Generating new class participation screenshot'
      topyears = f.fetch(
          :output => './public/top-years.png',
          :div => '#participation-class'
      )
      awsupload(topyears)
      @redis.set('lb_class_screenshot', false)
    end


    if @redis.get('lb_scholarships_screenshot') == 'true'
      puts 'Generating new funding areas screenshot'
      topareas = f.fetch(
          :output => './public/top-areas.png',
          :div => '#participation-areas'
      )
      awsupload(topareas)
      @redis.set('lb_scholarships_screenshot', false)
    end
  end
end