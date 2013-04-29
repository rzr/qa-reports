require 'spec_helper'

describe ReportShow do
  before(:each) do
    author = User.new(:name => 'User', :email => 'email@domain.com', :password => 'pwdpwd')
    author.save!

    attributes = {
      :release =>  Release.find_by_name('1.1'),
      :profile =>  Profile.find_by_name('Core'),
      :author => author,
      :editor => author,
      :testset => 'Sanity',
      :product => 'N900',
      :tested_at => '2013-04-29 12:00:00',
      :qa_summary_txt => '[[1234]]',
      :title => 'Test report',
      :result_files => [FileAttachment.new(:file => 'f', :attachment_type => :result_file)],
      :features_attributes => [
        {
          :name => 'Feature 1',
          :meego_test_cases_attributes => [
            {
              :name => 'TC1',
              :result => 1,
              :comment => '[[4567]]'
            }
          ]
        }
      ]
    }

    s = MeegoTestSession.new(attributes)
    s.save!
    @report = ReportShow.new(s)
  end

  describe "produced JSON" do

    it "should contain only basic information if no options are given" do
      json = @report.as_json
      json.keys.length.should == 8
      json.has_key?(:title).should == true
      json.has_key?(:release).should == true
      json.has_key?(:profile).should == true
      json.has_key?(:testset).should == true
      json.has_key?(:product).should == true
      json.has_key?(:title).should == true
      json.has_key?(:summary).should == true
      json.has_key?(:features).should == true
      json.has_key?(:prev_session_id).should == true

      json[:summary].has_key?('Pass').should == true
      json[:summary].has_key?('Fail').should == true
      json[:summary].has_key?('N/A').should == true
      json[:summary].has_key?('Measured').should == true
      json[:summary].has_key?('Total').should == true

      json[:summary]['Total'].should == 1

      json[:features].length.should == 1
      json[:features][0].keys.length.should == 2
      json[:features][0].has_key?(:name).should == true
      json[:features][0].has_key?(:summary).should == true

      json[:features][0][:summary]['Total'].should == 1
    end

    it "should contain legacy summary if defined" do
      json = @report.as_json({:legacy_summary => true})
      json.keys.length.should == 12
      json.has_key?(:total_cases).should == true
      json.has_key?(:total_pass).should == true
      json.has_key?(:total_fail).should == true
      json.has_key?(:total_na).should == true
      json.has_key?(:total_measured).should == true

      json[:total_cases].should == 1

      json[:features][0].keys.length.should == 6
      json[:features][0].has_key?(:total_cases).should == true
      json[:features][0].has_key?(:total_pass).should == true
      json[:features][0].has_key?(:total_fail).should == true
      json[:features][0].has_key?(:total_na).should == true
      json[:features][0].has_key?(:total_measured).should == true

      json[:features][0][:total_cases].should == 1

    end

    it "should contain database ID if defined" do
      json = @report.as_json({:include_db_id => true})
      json.keys.length.should == 9
      json.has_key?(:qa_id).should == true
      json[:features][0].has_key?(:qa_id).should == true
    end

    it "should contain dates if defined" do
      json = @report.as_json({:include_dates => true})
      json.keys.length.should == 12
      json.has_key?(:created_at).should == true
      json.has_key?(:updated_at).should == true
      json.has_key?(:tested_at).should == true
      json.has_key?(:weeknum).should == true
    end

    it "should contain the text fields if defined" do
      json = @report.as_json({:include_text_fields => true})
      json.keys.length.should == 15
      json.has_key?(:objective).should == true
      json.has_key?(:build).should == true
      json.has_key?(:build_id).should == true
      json.has_key?(:environment).should == true
      json.has_key?(:qa_summary).should == true
      json.has_key?(:issue_summary).should == true
      json.has_key?(:patches_included).should == true

      json[:features][0].has_key?(:comments).should == true
    end

    it "should contain bugs from text fields if defined" do
      json = @report.as_json({:scan_text_fields => true})
      json.keys.length.should == 9
      json.has_key?(:bugs).should == true
      json[:bugs].length.should == 1
      json[:bugs][0][:id].should == "1234"
    end

    it "should contain test cases if defined" do
      json = @report.as_json({:include_testcases => true})
      json[:features][0].has_key?(:testcases)
      json[:features][0][:testcases].length.should == 1
      json[:features][0][:testcases][0][:name].should == "TC1"
    end

    it "should contain db id and comments for test cases as well" do
      json = @report.as_json({
        :include_testcases => true,
        :include_db_id => true,
        :include_text_fields => true
      })
      json[:features][0].has_key?(:testcases)
      json[:features][0][:testcases].length.should == 1
      json[:features][0][:testcases][0][:name].should == "TC1"
      json[:features][0][:testcases][0].has_key?(:qa_id).should == true
      json[:features][0][:testcases][0].has_key?(:comment).should == true
    end
  end
end
