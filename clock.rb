require 'stalker'

module Clockwork
  handler { |job| Stalker.enqueue(job) }

  every 1.minute, 'css'
  every 1.minute, 'screenshot'
end