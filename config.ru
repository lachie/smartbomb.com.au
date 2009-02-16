require 'rubygems'
gem 'sinatra', '~> 0.9' 
require './smartbomb'

set :run, false
set :environment, :production
run Sinatra::Application


# vim: ft=ruby
