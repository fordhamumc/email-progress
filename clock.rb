require './jobs'

module Clockwork

  every 30.seconds, 'css' do
    Jobs.css
    puts 'Finished \'css\''
  end
  every 1.minute, 'screenshot' do
    Jobs.screenshot
    puts 'Finished \'screenshot\''
  end
end