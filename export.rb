# read all test sessions and export them to mongodb
#

require 'rubygems'
require 'mongo'

db   = Mongo::Connection.new.db('qadash-db')
coll = db.collection('reports')

sessions = MeegoTestSession.find(:all)

sessions.each do |s|
  sets = []
  s.meego_test_sets.each do |set|
    cases = []

    set.meego_test_cases.each do |c|
      bugs = c.comment.scan(/\[\[(\d+)\]\]/).map {|m| m[0].to_i}
      data = {
        "qa_id" => c.id,
        "name" => c.name,

        "result" => c.result,
        "comment" => c.comment,

        "bugs" => bugs
      }
      cases << data
    end

    data = {
      "qa_id" => set.id,
      "name" => set.feature,
      
      "total_cases" => set.total_cases,
      "total_pass" => set.total_passed,
      "total_fail" => set.total_failed,
      "total_na" => set.total_na,

      "comments" => set.comments,

      "cases" => cases
    }
    sets << data
  end

  data = {
    "qa_id" => s.id,

    "title" => s.title,

    "hwproduct" => s.hwproduct,
    "target" => s.target,
    "testtype" => s.testtype,
    "version" => s.release_version,

    "created_at" => s.created_at.utc,
    "updated_at" => s.updated_at.utc,
    "tested_at" => s.tested_at.utc,
    "weeknum" => Date.parse(s.tested_at.to_date.to_s).cweek(),

    "total_cases" => s.total_cases,
    "total_pass" => s.total_passed,
    "total_fail" => s.total_failed,
    "total_na" => s.total_na,

    "features" => sets,
  }
  
  

  coll.update({"qa_id" => s.id}, data, :upsert => true)
end
