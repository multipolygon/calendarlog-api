cp ../../backups/api-rainfallrecord-app/latest.dump ./db/
sleep 1
docker-compose \
    exec \
    postgres \
    bash -c "pg_restore --create --verbose --clean --no-acl --no-owner -h localhost -U rails --dbname=calendarlog_development /var/src/db/latest.dump"
