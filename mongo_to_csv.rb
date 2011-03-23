require 'rubygems'
require 'mongo'

db = Mongo::Connection.new.db('qadash-db')
reports_coll = db.collection('reports')

total_cases = {}

reports_coll.find().each do |data|

  weeknum = data["weeknum"]
  total_cases[weeknum] = 0 if total_cases[weeknum].nil?
  total_cases[weeknum] += data["total_cases"]

end
total_cases.each {|key, value| puts "wk#{key} has #{value} total cases" }





