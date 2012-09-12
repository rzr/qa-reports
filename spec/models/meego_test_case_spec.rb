require 'spec_helper'
require 'pp'
require "#{Rails.root}/features/support/factories"

describe MeegoTestCase do
    it "should validate custom status on create" do
        APP_CONFIG['custom_results'] = ['Pending']
        CustomResult.create([{:name => 'Pending'}, {:name => 'Blocked'}])

        result = CustomResult.find_by_name('Blocked')

        tc = MeegoTestCase.new(
            :name           => 'Test case with deprecated status',
            :result         => MeegoTestCase::CUSTOM,
            :custom_result  => result
        )

        tc.save.should be_false
        tc.errors.delete(:custom_result).should_not be_empty
        tc.errors.should be_empty
    end

    it "should not validate custom status on update" do
        APP_CONFIG['custom_results'] = ['Pending']

        report = FactoryGirl.create(:report_with_custom_results)

        APP_CONFIG['custom_results'] = []

        report     = MeegoTestSession.find(report.id)
        tc         = report.meego_test_cases.first
        tc.comment = "Adding comment should work for TC with deprecated status"

        tc.save.should be_true
    end

    it "should set pass, fail and n/a result based on result name" do
        tc = MeegoTestCase.new

        tc.result_name = "Pass"
        tc.result.should == MeegoTestCase::PASS

        tc.result_name = "FAIL"
        tc.result.should == MeegoTestCase::FAIL

        tc.result_name = "n/a"
        tc.result.should == MeegoTestCase::NA
    end

    it "should set a custom result based on result name" do
        APP_CONFIG['custom_results'] = ['Pending']
        CustomResult.create([{:name => 'Pending'}, {:name => 'Blocked'}])

        tc = MeegoTestCase.new

        tc.result_name = "Pending"
        tc.result.should == MeegoTestCase::CUSTOM
        tc.custom_result.name.should == "Pending"
    end
end
