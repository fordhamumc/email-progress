require './jobs'

module Clockwork

  every 1.minute, 'css' do
    Jobs.css
  end
  every 1.minute, 'screenshot' do
    Jobs.screenshot
  end
end