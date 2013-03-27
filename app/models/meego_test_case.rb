require 'testreport'

class MeegoTestCase < ActiveRecord::Base
  default_scope where(:deleted => false)
  scope :deleted, where(:deleted => true)

  belongs_to :feature
  belongs_to :meego_test_session

  belongs_to :custom_result

  has_many :measurements,        :dependent => :destroy, :class_name => "MeegoMeasurement"
  has_many :serial_measurements, :dependent => :destroy
  has_one  :attachment, :as => :attachable, :dependent => :destroy, :class_name => "FileAttachment",
    :conditions => {:attachment_type => :attachment}

  accepts_nested_attributes_for :measurements, :serial_measurements, :attachment

  validate :custom_result_should_be_in_configuration, :on => :create

  CUSTOM   =  3
  MEASURED =  2
  PASS     =  1
  NA       =  0
  FAIL     = -1

  def self.by_name(name)
    where(:name => name).first
  end

  def result_name
    if result == CUSTOM
      custom_result.name
    else
      MeegoTestCaseHelper::RESULT_TO_TXT[result]
    end
  end

  def result_name=(new_result)
    res = MeegoTestCaseHelper::TXT_TO_RESULT[new_result.downcase]
    if res
      self.result = res
    else
      self.result = CUSTOM
      self.custom_result = CustomResult.find_by_name(new_result)
    end
  end

  def unique_id
    (feature.name + "_" + name).downcase
  end

  def feature_key
    feature.name
  end

  def product_key
    meego_test_session.product.downcase
  end

  def find_matching_case(session)
    session.test_case_by_name(feature_key, name) unless session.nil?
  end

  def all_measurements
    a = (measurements + serial_measurements)
    a.sort!{|x,y| x.sort_index <=> y.sort_index}
  end

  def has_measurements?
    return !(measurements.empty? and serial_measurements.empty?)
  end

  def find_change_class(prev_session)
    return case find_matching_case(prev_session).try(:result)
      when   result then 'unchanged_result'
      when     FAIL then 'changed_result changed_from_fail'
      when       NA then 'changed_result changed_from_na'
      when     PASS then 'changed_result changed_from_pass'
      when MEASURED then 'changed_result changed_from_measured'
      when   CUSTOM then 'changed_result changed_from_na'
      else             'unchanged_result'
    end
  end

  def custom_result_should_be_in_configuration
    if result == CUSTOM
      if !custom_result || !APP_CONFIG['custom_results'].map(&:downcase).include?(custom_result.name.downcase)
        errors[:custom_result] << "Invalid custom result in testcase #{name}"
      end
    end
  end

  def as_json(options = nil)
    {
      name: name,
      result: result_name,
      comment: comment_html,
      tc_id: tc_id.present? ? tc_id : nil,
      # TODO: Fix to handle multiple services
      bugs: comment.scan(/\[\[(\d+)\]\]/).map {|m| {id:m[0], url:"#{SERVICES[0]['link_uri']}#{m[0]}"}}
    }
  end

  def comment_html
    comment ? MeegoTestReport::format_txt(comment).html_safe : ""
  end
end
