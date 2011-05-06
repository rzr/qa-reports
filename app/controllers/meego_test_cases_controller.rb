class MeegoTestCasesController < ApplicationController
  include CacheHelper

  before_filter :authenticate_user!
    
  def update_case_comment
    case_id  = params[:id]
    comment  = params[:comment]
    attachment = params[:attachment]
    testcase = MeegoTestCase.find(case_id)
    testcase.update_attribute(:comment, comment)
    testcase.update_attachment(attachment)

    @test_session = testcase.meego_test_session
    @test_session.updated_by(current_user)
    @editing = true
    expire_caches_for(@test_session)

    logger.info(render :partial => 'reports/testcase_comment', :locals => {:testcase => testcase})
  end

  def update_case_result
    case_id  = params[:id]
    result   = params[:result]
    testcase = MeegoTestCase.find(case_id)
    testcase.update_attribute(:result, result.to_i)

    test_session = testcase.meego_test_session
    test_session.updated_by(current_user)
    expire_caches_for(test_session, true)

    render :text => "OK"
  end

end