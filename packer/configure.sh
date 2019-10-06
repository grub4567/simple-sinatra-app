#!/bin/sh
#
# Configure Simple Sinatra App
#

set -e
set pipefail

message() {
  echo "configure-simple-sinatra-app ==> ${1}"
}

message "Started"

message "Waiting 180 seconds for cloud-init to update apt sources"
timeout 180 sh -c "until stat /var/lib/cloud/instance/boot-finished \
2>/dev/null; do sleep 1; done"

message "Upgrading packages"
apt-get update
apt-get upgrade -y

message "Installing packages"
apt-get install -y \
  build-essential \
  curl \
  nginx \
  ruby \
  ruby-dev \
  ruby-bundler

message "Creating Puma user"
useradd --system puma

message "Moving application files to application directory"
for file in helloworld.rb Gemfile config.ru puma.rb; do
  mv "/tmp/${file}" /srv
done

message "Creating directories in application directory"
mkdir -p /srv/tmp/puma /srv/log /srv/public

message "Changing ownership of application directory to Puma user"
chown -R puma:puma /srv

message "Installing Gems"
bundle install --gemfile /srv/Gemfile

message "Moving Puma systemd service file"
mv /tmp/puma.service /etc/systemd/system/puma.service

message "Moving NGINX config"
mv /tmp/nginx.conf /etc/nginx/conf.d/puma.conf

message "Removing default NGINX conf"
rm /etc/nginx/sites-enabled/default

message "Testing NGINX config"
nginx -t

message "Enabling Puma systemd service"
systemctl daemon-reload
systemctl enable --now puma.service

message "Enabling NGINX systemd service"
systemctl enable nginx.service
systemctl restart nginx.service

message "Checking that the app is exposed on port 80"
curl --silent http://localhost | grep "Hello World!"

message "Completed"
