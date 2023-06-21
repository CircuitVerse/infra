#!/bin/bash

git pull
bundle install --with pg --without development test
RAILS_ENV=production rails db:migrate
# RAILS_ENV=production rails webpacker:clobber
RAILS_ENV=production rails assets:precompile
procodile restart
echo "Run procodile status"
