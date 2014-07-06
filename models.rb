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

    def self.create_from_scrape(user, dateStr, timeStr, type, typeStr, course, uniqueId)
        date = Date.strptime(dateStr)
        if !timeStr.empty?
            dateTimeStr = "#{dateStr}T#{timeStr}"
            date = DateTime.strptime(dateTimeStr, "%Y-%m-%dT%H:%M")
        end
        b = Booking.first_or_create(:uniqueId => uniqueId, :user => user)
        b.attributes = {:user => user, :date => date, :type => type, :typeStr => typeStr, :course => course}
        b.save
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
        end
        event.summary = @typeStr
        event.location = @course
        return event
    end
end

DataMapper.finalize
DataMapper.auto_upgrade!
