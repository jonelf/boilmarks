require 'rubygems'
require 'sinatra'
require 'uri'
require 'mongo'
require 'bluecloth'

include Mongo

uri = URI.parse(ENV['MONGOHQ_URL'])
conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL']) #, {:slave_ok => true})
DB = conn.db(uri.path.gsub(/^\//, ''))

set :haml, {:escape_html => true }

configure :production do
  enable :raise_errors
end

get '/boilmarks' do
  @bluecloth = BlueCloth
  @boilmarks = DB['boilmarks'].find.sort([['seconds','ascending']])
  @average = Time.at(@boilmarks.inject(0){|sum, mark| sum+=mark['seconds'].to_i}/@boilmarks.count).gmtime.strftime('%R:%S')
  @boilmarks = DB['boilmarks'].find.sort([['seconds','ascending']])
  haml :boilmarks
end

get '/' do
  haml :index
end

get '/add' do
  haml :add
end

post '/add' do
  name = params[:name]
  reject_blank(name)
  minutes_seconds = params[:time].split(":")
  seconds = minutes_seconds[0].to_i*60+minutes_seconds[1].to_i
  if seconds==0
    haml "%h1== #{params[:time]} is not a correctly entered time."
  elsif params[:pwd].downcase=="boilmark"
    DB['boilmarks'].insert('name'=> name, 
      'email' => params[:email],
      'time' => params[:time],
      'seconds' => seconds,
      'type' => params[:type],
      'brand_model' => params[:brand_model],
      'comment' => params[:comment],
      'post_date' => Time.now.strftime('%Y-%m-%d'))
    redirect('/boilmarks')
  else
    haml "%h1 Incorrect password."
  end
end

helpers do
  def reject_blank(url)
    redirect('/') unless url.size > 0
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
