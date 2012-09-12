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

  validate :custom_result_should_be_in_configuration

  CUSTOM   =  3
  MEASURED =  2
  PASS     =  1
  NA       =  0
  FAIL     = -1

  def self.by_name(name)
    where(:name => name).first
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
      when nil    then ''
      when result then 'unchanged_result'
      when     -1 then 'changed_result changed_from_fail'
      when      0 then 'changed_result changed_from_na'
      when      1 then 'changed_result changed_from_pass'
      when      2 then 'changed_result changed_from_measured'
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

end
