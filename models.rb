require 'rubygems'
require 'data_mapper'
require 'icalendar'

require './golfse.rb'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite://#{File.expand_path(File.dirname(__FILE__))}/test.db")

class User
    include DataMapper::Resource
    property :id,           Serial
    property :golfId,       String 
    property :password,     String

    has n, :bookings

    def scrape
        golfse = GolfSE.new(self)
        golfse.scrape
    end

    def getCalendar
        cal = Icalendar::Calendar.new
        cal.timezone do |t|
            t.tzid = "Europe/Stockholm"
        end
        bookings.each do |booking|
            cal.add_event(booking.ical)
        end
        cal.publish
        cal
    end

end

class Booking
    include DataMapper::Resource

    property :id,           Serial
    property :uniqueId,     String,     :key => true
    property :date,         DateTime
    property :type,         String
    property :typeStr,      String
    property :course,       String

    belongs_to :user
    
    has n, :coPlayers

    def self.create_from_scrape(user, dateStr, timeStr, type, typeStr, course, players, uniqueId)
        date = Date.strptime(dateStr)
        if !timeStr.empty?
            dateTimeStr = "#{dateStr}T#{timeStr}"
            date = DateTime.strptime(dateTimeStr, "%Y-%m-%dT%H:%M")
        end
        b = Booking.first_or_create(:uniqueId => uniqueId, :user => user)
        b.attributes = {:user => user, :date => date, :type => type, :typeStr => typeStr, :course => course}
        players.each do |player|
        
            p = CoPlayer.first_or_create(:booking => b, :name => player[:name])
            puts p
            p[:hcp] = player[:hcp]
            p.save
        end
        b.save
        puts b.coPlayers
        return b
    end

    def to_s
        return "#{@typeStr} at #{@course}, #{@date} <#{@uniqueId}>"
    end

    def ical
        event = Icalendar::Event.new
        if @date.hour == 0
            # Only date if we have no hours
            event.dtstart = Icalendar::Values::Date.new(@date)
        else
            event.dtstart = @date
            # End 4 hours later
            event.dtend = @date + Rational(4, 24)
        end
        event.summary = @typeStr
        event.location = @course
        event.description = @typeStr
        puts @CoPlayers
        if @coPlayers
            player_arr = @CoPlayer.map do |player|
                "#{player.name} (#{player.hcp})"
            end
            event.description += " med " + player_arr.join(' och ')
        end
        return event
    end
end

class CoPlayer
    include DataMapper::Resource
    property :id,       Serial
    property :name,     String
    property :hcp,      String

    belongs_to :booking
end

DataMapper.finalize
DataMapper.auto_upgrade!
