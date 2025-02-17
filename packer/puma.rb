#
# puma.rb
#

root = "#{Dir.getwd}"

bind "unix://#{root}/tmp/puma/socket"

pidfile "#{root}/tmp/puma/pid"

state_path "#{root}/tmp/puma/state"

rackup "#{root}/config.ru"

workers 1

threads 4, 8

activate_control_app

preload_app!
