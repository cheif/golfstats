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

  def scrapeRounds
    url = "https://www9.golf.se/MyPage/Stats/Stats.aspx"
    page = @agent.get(url)
    scriptTag = page.search("head > script").last
    m = /_roundData\s*= (.*?);/.match(scriptTag.content)
    jsonData = m[1]
    json_rounds = JSON.parse(jsonData)
    json_rounds.map do |k, json|
      Round.create_from_scrape(@user, json)
    end
  end

  def scrapeHoles(round)
    url = "https://www9.golf.se/MyPage/Stats/Item.aspx?r=#{round.id}"
    page = @agent.get(url)
    scriptTag = page.search("head > script").last

    if round.course.holes.count == 0
      m = /_hole\s*= (.*?);/.match(scriptTag.content)
      json_holes = JSON.parse(m[1])
      json_holes.each do |_, data|
        Hole.first_or_create(:course => round.course,
                             :number => data['Number'],
                             :par => data['Par'], :index => data['Index'])
      end
    end

    m = /_data\s*= (.*?);/.match(scriptTag.content)
    if m[1] != 'null'
      # Data might be null if there is no result added
      data = JSON.parse(m[1])
      json_results = data['Holes']
      json_results.map do |data|
        hole = Hole.first(:course => round.course, :number => data['Number'])
        HoleResult.first_or_create(:round => round, :hole => hole,
                                   :score => data['GrossScore'])
      end
    end
  end
end
