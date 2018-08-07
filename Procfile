web: bundle exec puma -C config/puma.rb
worker:  bundle exec rake jobs:work
clock: bundle exec clockwork clock.rb
worker: ruby tweet_streamer.rb run
