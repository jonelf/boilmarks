require 'rubygems'
require 'sinatra'
require 'uri'
require 'mongo'

include Mongo

uri = URI.parse(ENV['MONGOHQ_URL'])
conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
DB = conn.db(uri.path.gsub(/^\//, ''))

#DB = Connection.new(ENV['DATABASE_URL'] || 'localhost').db('boilmarks')
#if ENV['DATABASE_USER'] && ENV['DATABASE_PASSWORD']
#  auth = DB.authenticate(ENV['DATABASE_USER'], ENV['DATABASE_PASSWORD'])
#end

set :haml, {:escape_html => true }

configure :production do
  enable :raise_errors
end

get '/test' do
  haml "%h1 This is a test for sure."
end

get '/' do
  <<-HTML
    <title>Boilmarks</title>
    <form action="/shorten" method="post">
      <input type="text" name="url" />
      <input type="submit" value="shorten" />
    </form>
    <p>Written in Sinatra and MongoDB.</p>
  HTML
end

post '/shorten' do
  reject_blank    params[:url]
  shorten         params[:url]
  slug = slug_for params[:url]
  host = Sinatra::Application.host
  "<a href='/#{slug}' id='short'>http://shorty-app.heroku.com/#{slug}</a>"
end

get '/:slug' do |slug|
  if url = url_for(slug)
    redirect(url)
  else
    halt(404)
  end
end

helpers do
  def reject_blank(url)
    redirect('/') unless url.size > 0
  end

  def shorten(url)
    if DB['urls'].find('url' => url).count == 0
      DB['urls'].insert('url' => url, 'slug' => DB['urls'].count.to_s(36))
    end
  end

  def slug_for(url)
    DB['urls'].find('url' => url).collect {|row| row['slug'] }.flatten
  end

  def url_for(slug)
    DB['urls'].find('slug' => slug).collect {|row| row['url'] }.flatten
  end
end

__END__

@@layout
!!! XML
!!! Basic
%html
  %head
    %title Boilmarks - clocked boilers
    %link{:href=>"/stylesheets/style.css",:media=>"screen",:rel=>"stylesheet",:type=>"text/css"}
    %link{:rel=>"icon", :type=>"image/gif", :href=>"/boil.png"}
  %body
    != yield
      %p
        %a{:href=>'mailto:jonas@plea.se', :class=>'contact'}Contact
