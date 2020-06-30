#!/bin/sh

set -e

bundle config --delete without
echo $BUNDLE_PATH
echo $BUNDLE_WITHOUT
bundle install

# bundle exec rails generate migration AddFeedbackToUsers feedback_rating:integer feedback_text:text
# bundle exec rails generate migration RenameRecordMeasurementToPrecipitation
# bundle exec rails generate migration AddTemperatureToRecords temperature_min:float temperature_max:float

# echo "Database migrations..."
# bundle exec rake db:migrate

if [ "$RAILS_ENV" = "production" ]; then
   echo "Compiling assets..."
   bundle exec rake assets:precompile
fi

if [ -f tmp/pids/server.pid ]; then
    echo "Removing server.pid..."
    rm tmp/pids/server.pid
fi

echo "Running server..."
echo $RAILS_ENV
echo $RACK_ENV
exec bundle exec "$@"
