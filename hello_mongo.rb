require "rubygems"
require "bundler/setup"
require "sinatra"
require "mongo"
require "mongo_mapper"

MongoMapper.connection = Mongo::Connection.new(mongo_connection_info)
MongoMapper.database = 'pageStats'

# find our mongo connection info
def mongo_connection_info
  services = JSON.parse(ENV['VCAP_SERVICES'])
  services.each do |service_version, bindings|
    bindings.each do |binding|
      if binding['label'] =~ /mongo/i
        res = binding['credentials']
        return res
      end
    end
  end
  raise "could not find connection info"
end

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
