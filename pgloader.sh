# https://github.com/dimitri/pgloader

# Heroku:
# image: dimitri/pgloader:ccl.latest
# --no-ssl-cert-verification
# ?sslmode=require

pgloader ./db/production-latest.sqlite3 postgresql://rails:rails@postgres/calendarlog_development
