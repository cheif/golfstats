require 'rubygems'
require 'sinatra'
require 'json'

require './models.rb'

post '/createCal/' do
    content_type :json
    golfId = params[:golfId]
    password = params[:password]
    u = User.first_or_create(:golfId => golfId, :password => password)
    u.scrape
    return {
        :status => "Created calendar", 
        :golfId => u.golfId, 
        :url => url("cal/#{u.golfId}/")
    }.to_json
end

get '/cal/:golfId/?' do
    golfId = params[:golfId]
    u = User.first(:golfId => golfId)
    u.getCalendar.to_ical
end
