web: bundle exec ruby app.rb -p $PORT
worker: bundle exec sidekiq -r ./jobs.rb -c 10
clock: bundle exec clockwork clock.rb