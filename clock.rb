require './jobs'

module Clockwork

  every 30.seconds, 'css' do
    Jobs.css
  end
  every 1.minute, 'screenshot' do
    Jobs.screenshot
  end
end