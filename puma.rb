#

root = "#{Dir.getwd}"

port ENV.fetch("PORT") { 8080 }

pidfile "#{root}/tmp/puma/pid"

state_path "#{root}/tmp/puma/state"

rackup "#{root}/config.ru"

workers ENV.fetch("PUMA_WORKERS") { 1 }

min_threads = ENV.fetch("PUMA_MIN_THREADS") { 2 }.to_i
max_threads = ENV.fetch("PUMA_MAX_THREADS") { 2 }.to_i
threads min_threads, max_threads

activate_control_app

preload_app!
