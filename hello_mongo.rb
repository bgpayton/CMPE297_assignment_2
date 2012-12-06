require "rubygems"
require "bundler/setup"
require "sinatra"
require "mongo"
require "mongo_mapper"

host = JSON.parse(ENV['VCAP_SERVICES'])['mongodb-2.0'].first['credentials']['hostname'] rescue 'localhost'
port = JSON.parse( ENV['VCAP_SERVICES'] )['mongodb-2.0'].first['credentials']['port'] rescue 27017
mongo_uri = 'mongodb://' + host + ':' + port.to_s

MongoMapper.connection = Mongo::Connection.from_uri(mongo_uri)
MongoMapper.database = 'pageStats'


class PageHit
  include MongoMapper::Document

  key :date, String
  key :ip, String
end

class PageHitCountApp < Sinatra::Base

  get '/cmpe297-assignment2' do
    recordPageHit(request.ip)
    code = "
<html>
Hello World!
<p>
<%= getUniquePageHitsByDate() %>
</html>"
    erb code
  end

  def recordPageHit(ip)
    t = Time.now
    date = t.year.to_s + '-' + t.month.to_s + '-' + t.day.to_s
    ph = PageHit.find_or_initialize_by_date_and_ip(date, ip)
    ph.save
  end

  def getUniquePageHitsByDate
    result = ""
    phArray = PageHit.sort(:date).all
    curDate = nil
    curHitCount = 1
    for i in 0...phArray.length
      ph = phArray[i]
      if curDate == nil
        curDate = ph.date
      elsif ph.date != curDate
        result = result + '<p>' + curDate + ' = ' + curHitCount.to_s
        curDate = ph.date
        curHitCount = 1
      else
        curHitCount = curHitCount + 1
      end
    end
    result = result + '<p>' + curDate + ' = ' + curHitCount.to_s

    return result
  end
end

PageHitCountApp.run!
