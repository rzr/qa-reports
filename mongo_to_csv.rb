require 'rubygems'
require 'mongo'

db = Mongo::Connection.new.db('qadash-db')
reports_coll = db.collection('reports')
bugs_coll = db.collection('bugs')

total_cases = {}
output = []

(1..12).each do |weeknum|
  reports = reports_coll.find({"weeknum" => weeknum})
  total_cases = 0
  reports.each do |r|
    total_cases += r["total_cases"]
  end

  bugs = bugs_coll.find({"weeknum" => weeknum}).count()
  
  output << [weeknum, total_cases, bugs]

end

puts "Weeknum, Testcases, Bugs"
output.each do |row|
  puts "#{row[0]},#{row[1]},#{row[2]}\n"
end

