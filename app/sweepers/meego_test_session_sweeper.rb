class MeegoTestSessionSweeper < ActionController::Caching::Sweeper
  observe MeegoTestSession, MeegoTestCase

  def after_save(record)
    test_session = record.is_a?(MeegoTestSession) ? record : record.meego_test_session
    return true unless test_session.published

    expire_caches_for(test_session, true)
    expire_index_for(test_session)
  end

  def after_destroy(record)
    test_session = record.is_a?(MeegoTestSession) ? record : record.meego_test_session
    expire_caches_for(test_session, true)
    expire_index_for(test_session)
  end
end
