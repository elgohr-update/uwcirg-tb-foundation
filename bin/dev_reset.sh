docker-compose stop sidekiq;
docker-compose restart db;
docker-compose exec web /bin/bash -c 'bundle exec rails db:reset';
docker-compose up -d sidekiq;