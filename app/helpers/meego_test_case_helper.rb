module MeegoTestCaseHelper

  RESULT_TO_TXT = {MeegoTestCase::FAIL      => "Fail",
                   MeegoTestCase::NA        => "N/A",
                   MeegoTestCase::PASS      => "Pass",
                   MeegoTestCase::MEASURED  => "Measured"}

  TXT_TO_RESULT = {"fail"    => MeegoTestCase::FAIL,
                   "pass"    => MeegoTestCase::PASS,
                   "n/a"     => MeegoTestCase::NA,
                   "measured"=> MeegoTestCase::MEASURED}

  def result_to_txt(result)
    RESULT_TO_TXT[result] or "N/A"
  end

  def txt_to_result(txt)
    TXT_TO_RESULT[txt.downcase] or MeegoTestCase::NA
  end

  def result_html(model)
    return RESULT_TO_TXT[MeegoTestCase::NA] unless model
    model.result_name
  end

  def hide_passing(model)
    if model==nil
      return ""
    end
    if model.result == 1
      "display:none;"
    else
      ""
    end
  end

  def self.possible_results
    # Fixed results
    results = (-1..2).map do |idx|
      RESULT_TO_TXT[idx]
    end
    # Custom results
    results += APP_CONFIG['custom_results']
    results
  end

  def result_class(model, prefix = "")
    return prefix + MeegoTestSession.result_as_string(MeegoTestCase::NA) if model.nil?

    prefix + MeegoTestSession.result_as_string(model.result)
  end

  def comment_html(model)
    (model.present? && model.comment) ? MeegoTestReport::format_txt(model.comment).html_safe : nil
  end

  def purpose_html(model)
    (model.present? && model.purpose) ? MeegoTestReport::format_txt(model.purpose).html_safe : nil
  end
end
