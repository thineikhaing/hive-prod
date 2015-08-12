require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  class User; end

  handler do |job|
    puts "Running #{job}"
  end

  every(1.day, 'Queueing Regenerate Auth_Token job', :at => '00:00') { Delayed::Job.enqueue RegenerateAuthTokenJob.new }

end
