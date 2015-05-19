# encoding: UTF-8
require 'rubygems'
require 'mechanize'
require './models.rb'

class GolfSE
    #A scraper for golf.se, uses mobile site
    def initialize(user)
        #initialize url, user and a new Mechanize agent, then do the login.
        @baseurl = "http://mgmobil.golf.se/"
        @user = user
        @agent = Mechanize.new
        @agent.user_agent_alias = 'Mac Safari'
        self.login()
    end

    def login
        #Login, basically just steps through the steps of the login and posts the correct forms.
        url = "http://www9.golf.se/Handlers/LoginHandler.ashx?methodName=Player&golfid=#{@user.golfId}&password=#{@user.password}&remember=1&_=1404643669273"
        @agent.get(url)
    end

    def scrape
        calURL = "http://www9.golf.se/MyPage/Calendar/Calendar.aspx"
        calPage = @agent.get(calURL)
        calPage.search(".mypage-calendar-content-main-list-holder > .row:not(.head)").map do |listing|
            type = listing.attribute('data-type')
            course = listing.attribute('data-coursename')
            dateStr = listing.search('.span2').first.attribute('title').content
            timeStr = listing.search('.span3').first.content
            players = listing.search('.span9').first.search('i').map do |player|
                {
                    :name => player.attribute('data-name'),
                    :hcp => player.attribute('data-hcp')
                }
            end
            btn = listing.search('.span10 > button').first
            uniqueId = btn.attribute('data-bookingcode')
            if !uniqueId
                uniqueId = btn.attribute('data-compid')
            end
            uniqueId = uniqueId.content
            typeStr = listing.search('.span6').first.content
            Booking.create_from_scrape(@user, dateStr, timeStr, type, typeStr, course, players, uniqueId)
        end
    end
end
