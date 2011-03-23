# read all bug reports and export them to mongodb
#

require 'rubygems'
require 'open-uri'
require 'net/http'
require 'net/https'
require 'FasterCSV'
require 'mongo'

FROMDATE = "2011-01-01"

BUGZILLA_CONFIG = { 'server' => 'bugs.meego.com',
                    'port' => 443,
                    'use_ssl' => true }

BUGZILLA_CONFIG['uri'] = "/buglist.cgi?bugidtype=include&columnlist=short_desc%2Cbug_status%2Copendate%2Cresolution&query_format=advanced&ctype=csv&chfield=%5BBug%20creation%5D&chfieldto=Now&chfieldfrom="

uri = BUGZILLA_CONFIG['uri'] + FROMDATE

content = ""
 
@http = Net::HTTP.new(BUGZILLA_CONFIG['server'], BUGZILLA_CONFIG['port'])
@http.use_ssl = BUGZILLA_CONFIG['use_ssl']

@http.start() {|http|
      req = Net::HTTP::Get.new(uri)
      if not BUGZILLA_CONFIG['http_username'].nil?
        req.basic_auth BUGZILLA_CONFIG['http_username'], BUGZILLA_CONFIG['http_password']
      end
      response = http.request(req)
      content = response.body
      }

# For debugging csv export content
#puts content
#exit


db   = Mongo::Connection.new.db('qadash-db')
coll = db.collection('bugs')

#bug_id,"short_desc","bug_status","opendate","resolution"
csv_header = { "bug_id"     => 0,
	           "short_desc" => 1,
	           "bug_status" => 2,
	           "opendate"   => 3,
	           "resolution" => 4	           
	           }

FasterCSV.parse(content, :headers => true) do |row|

  data = {}
  
  # store exported data as such for each header field
  csv_header.each do |key, value|
    data[key] = row[value]
  end

  # customize data
  opendate = row[csv_header["opendate"]]
  date_obj = Time.parse(opendate)
  data["opendate"] = date_obj.utc

  weeknum = Date.parse(opendate).cweek()
  data["weeknum"] = weeknum

  # For debugging the data structure 
  #data.each {|key, value| puts "#{key} is #{value}" }
  #temp = gets

  coll.update({"bug_id" => data["bug_id"]}, data, :upsert => true)
end

