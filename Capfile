load 'deploy'
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

# vim: ft=ruby

set :application, "smartbomb2"
set :repository,  "git://github.com/lachie/smartbomb.com.au.git"

set :use_sudo, false
set :git_enable_submodules, true

set :deploy_to, "/home/lachie/apps/#{application}"

set :scm, :git

role :app, "smartbomb.com.au"

namespace :deploy do
  task :finalize_update do
    run [
          "ln -s #{shared_path}/log #{latest_release}/log",
          "ln -s #{shared_path}/tmp #{latest_release}/tmp"
        ] * ' && '
  end
end
