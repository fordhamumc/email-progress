require 'sinatra'
require 'open-uri'
require 'sidekiq'
require 'nokogiri'
require 'screencap'
require 'aws-sdk'
require 'redis'
require './lib/leaderboard'
require './lib/progress'

Sidekiq.configure_client do |config|
  config.redis = {db: 1}
end

Sidekiq.configure_server do |config|
  config.redis = {db: 1}
end

def number_with_delimiter(number, delimiter=',')
  number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
end


def awsupload(file, type = 'image/png', cache = 'no-cache, no-store, must-revalidate')
  s3 = Aws::S3::Resource.new(region: ENV.fetch('AWS_REGION'))
  name = File.basename(file)
  obj = s3.bucket(ENV.fetch('AWS_BUCKET')).object(name)
  obj.upload_file(file, acl:'public-read', content_type: type, cache_control: cache)
end

class Jobs
  include Sidekiq::Worker
  @redis = Redis.new
  @screencap = Screencap::Fetcher.new(ENV.fetch('SCREENSHOT_URL'))

  def self.cachedata(name, data)
    if data.to_s != @redis.get(name) || !@redis.exists("#{name}_change")
      puts "#{name} changed"
      @redis.setbit("#{name}_screenshot", 0, 1)
      @redis.mset(name, data, "#{name}_change", Time.new.to_i)
    end
  end

  def self.screenshot(conditions, filename, location)
    if conditions.any? {|condition| @redis.getbit(condition + '_screenshot', 0) == 1}
      puts 'Generating new ' + filename.to_s
      screenshot = @screencap.fetch(
          :output => './tmp/' + filename.to_s,
          :div => location.to_s
      )
      awsupload(screenshot)
    end
  end

  def self.css
    url = ENV.fetch('GIVECAMPUS_URL')
    data = Nokogiri::HTML(open(url))
    defaults = File.read(File.join('assets', 'progress.css'))

    raised = data.at_css(ENV.fetch('RAISED_PATH')).content.strip
    donors = data.at_css(ENV.fetch('DONORS_PATH')).content.strip
    goal = data.at_css(ENV.fetch('GOAL_PATH')).content

    challenge_goal = ENV.fetch('CHALLENGE_GOAL')
    challenge_start = ENV.fetch('CHALLENGE_START')

    progress_overall = Progress.new(donors, goal, raised)
    progress_challenge = Progress.new(donors, challenge_goal, raised, challenge_start)

    leaderboards = data.css(ENV.fetch('LEADERBOARD_PATH'))
    leaderboard_class = Leaderboard.new(ENV.fetch('LEADERBOARDITEM_CLASS'), leaderboards).strip('name', /\D/).sort('donors')
    leaderboard_scholarships = Leaderboard.new(ENV.fetch('LEADERBOARDITEM_SCHOLARSHIP'), leaderboards).sort('dollars')


    cachedata('lb_class', leaderboard_class.to_json)
    cachedata('lb_scholarships', leaderboard_scholarships.to_json)
    cachedata('donors', donors)
    cachedata('goal', goal)
    cachedata('raised', raised)
    cachedata('challenge_goal', challenge_goal)
    cachedata('challenge_start', challenge_start)


    if [ @redis.get('lb_class_change'),
         @redis.get('lb_scholarships_change'),
         @redis.get('donors_change'),
         @redis.get('goal_change'),
         @redis.get('raised_change'),
         @redis.get('challenge_goal_change'),
         @redis.get('challenge_start_change')].all? {|t| t.to_i <= @redis.get('css_change').to_i}
      puts 'Data are unchanged.'
    else
      @redis.set('css_change', Time.new.to_i)
      output = <<-CSS
        /* Updated: #{Time.new.inspect} */

        #{defaults}
        #{progress_overall.barcss('#progress-bar')}
        #{progress_challenge.barcss('#challenge-bar')}
        #{progress_overall.statscss('#progress-stats')}
        #{leaderboard_class.css('class')}
        #{leaderboard_scholarships.css('support')}

      CSS

      puts 'Uploading new stylesheet'
      File.open('./tmp/progress.css', 'w') {|f| f.write(output) }
      awsupload('./tmp/progress.css', 'text/css')
    end
  end

  def self.screenshots
    self.screenshot(%w{goal donors}, 'progress-bar.png', '#progress-bar')
    if @redis.get('challenge_goal').to_i > 0
      self.screenshot(%w{donors challenge_goal challenge_start}, 'challenge-bar.png', '#challenge-bar')
    end
    self.screenshot(%w{raised donors}, 'stats.png', '#progress-stats')
    self.screenshot(%w{lb_class}, 'top-years.png', '#participation-class')
    self.screenshot(%w{lb_scholarships}, 'top-areas.png', '#participation-areas')
    %w{goal donors raised challenge_goal challenge_start lb_class lb_scholarships}.each {|condition| @redis.setbit(condition + '_screenshot', 0, 0)}
  end
end