require 'sinatra/base'

require 'active_support/lazy_load_hooks'
require 'active_support/core_ext/string'

class App < Sinatra::Base

  configure do
    #set :root, File.dirname(__FILE__)
    set :public_folder, 'app'
    set :admin_user_uid, 1
    set :admin_user_passwd, "Eq7K8h9gpg"
  end

  configure :development do
    enable :dump_errors, :logging
    set :port, 80
  end

  configure :production do
    disable :dump_errors, :logging
    set :bind, '0.0.0.0'
  end

   Dir[File.dirname(__FILE__) + '/apis/*.rb'].each do |file| 
    file_class = 'app/' + File.basename(file, File.extname(file))
    require file
    use file_class.classify.constantize
  end

  get '/' do
    File.read(File.join('app', 'index.html'))
  end

  get '/bower_components/*' do
    puts "Bower"
    tpl = 'bower_components/' + params[:splat][0]
    File.read(File.join('bower_components', params[:splat][0]))
  end

end