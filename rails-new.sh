echo "Ruby:"
echo ruby --version

echo "Rails:"
gem install rails
echo rails --version

echo "New:"
rails new calendarlog \
      --database=postgresql \
      --no-skip-action-mailer \
      --skip-action-mailbox \
      --skip-action-text \
      --skip-active-storage \
      --skip-action-cable \
      --skip-sprockets \
      --skip-javascript \
      --skip-turbolinks \
      --skip-test \
      --skip-system-test \
      --api \
      --skip-bundle \
      --skip-webpack-install
