set :user, "danbooru"
set :rails_env, "production"
server "sortbug.com", :roles => %w(web app db), :primary => true, :user => "danbooru"
#server "hijiribe.donmai.us", :roles => %w(web app), :user => "albert"

set :linked_files, fetch(:linked_files, []).push(".env.production")
