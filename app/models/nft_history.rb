#
# This file is part of meego-qa-reports
#
# Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
#
# Authors: Sami Hangaslammi <sami.hangaslammi@leonidasoy.fi>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#

class NftHistory
  attr_reader :measurements, :start_date

  include MeasurementUtils

  GET_START_DATE_QUERY = <<-END
    SELECT
    meego_test_sessions.tested_at AS tested_at
    FROM
    meego_test_sessions, meego_test_cases
    WHERE
    meego_test_cases.meego_test_session_id = meego_test_sessions.id AND
    meego_test_sessions.profile_id         = ? AND
    meego_test_sessions.testset            = ? AND
    meego_test_sessions.product            = ? AND
    meego_test_sessions.published          = ? AND
    meego_test_sessions.release_id         = ? AND
    (
     EXISTS(SELECT id
            FROM   meego_measurements
            WHERE  meego_test_case_id=meego_test_cases.id)
     OR
     EXISTS(SELECT id
            FROM   serial_measurement_groups
            WHERE  meego_test_case_id=meego_test_cases.id)
    )
    ORDER BY meego_test_sessions.tested_at ASC
    LIMIT 1
    END

  GET_NFT_RESULTS_QUERY = <<-END
    SELECT
    features.name                 AS feature,
    meego_test_cases.name         AS test_case,
    NULL                          AS group_name,
    meego_measurements.name       AS measurement,
    meego_measurements.unit       AS unit,
    meego_measurements.value      AS value,
    meego_test_sessions.tested_at AS tested_at
    FROM
    meego_measurements, meego_test_cases, features, meego_test_sessions
    WHERE
    meego_measurements.meego_test_case_id = meego_test_cases.id AND
    meego_test_cases.feature_id           = features.id AND
    features.meego_test_session_id        = meego_test_sessions.id AND
    meego_test_sessions.release_id        = ? AND
    meego_test_sessions.profile_id        = ? AND
    meego_test_sessions.testset           = ? AND
    meego_test_sessions.product           = ? AND
    meego_test_sessions.tested_at        <= ? AND
    meego_test_sessions.published         = ?
    ORDER BY
    features.name ASC,
    meego_test_cases.name ASC,
    meego_measurements.name ASC,
    meego_test_sessions.tested_at ASC
    END

  GET_SERIAL_MEASUREMENTS_QUERY = <<-END
    SELECT
    features.name                    AS feature,
    meego_test_cases.name            AS test_case,
    smg.name                         AS group_name,
    serial_measurements.name         AS measurement,
    serial_measurements.unit         AS unit,
    serial_measurements.min_value    AS min_value,
    serial_measurements.max_value    AS max_value,
    serial_measurements.avg_value    AS avg_value,
    serial_measurements.median_value AS med_value,
    meego_test_sessions.tested_at    AS tested_at
    FROM
    serial_measurements, serial_measurement_groups AS smg,
    meego_test_cases, features, meego_test_sessions
    WHERE
    serial_measurements.serial_measurement_group_id = smg.id AND
    smg.meego_test_case_id                 = meego_test_cases.id AND
    meego_test_cases.feature_id            = features.id AND
    features.meego_test_session_id         = meego_test_sessions.id AND
    meego_test_sessions.release_id         = ? AND
    meego_test_sessions.profile_id         = ? AND
    meego_test_sessions.testset            = ? AND
    meego_test_sessions.product            = ? AND
    meego_test_sessions.tested_at         <= ? AND
    meego_test_sessions.published          = ?
    ORDER BY
    features.name ASC,
    meego_test_cases.name ASC,
    smg.name ASC,
    serial_measurements.name ASC,
    meego_test_sessions.tested_at ASC
    END

  def initialize(session)
    @session = session
  end

  def persisted?
    false
  end

  # Get the date of the first session with NFT results
  def start_date
    @first_nft_result_date ||= find_start_date()
  end

  # Get NFT measurements in a multidimensional hash (see find_measurements
  # comment for more information)
  def measurements
    @trend_data ||= find_measurements()
  end

  # Get the serial measurements in a multidimensional hash (see
  # find_serial_measurements comment for more information)
  def serial_measurements
    @serial_trend_data ||= find_serial_measurements()
  end

  protected

  def find_start_date
    data = MeegoTestSession.find_by_sql([GET_START_DATE_QUERY,
                                         @session.profile.id,
                                         @session.testset,
                                         @session.product,
                                         true,
                                         @session.release_id])

    data[0].tested_at
  end

  # Get measurement trends for given session
  #
  # Read all matching measurement values from the beginning of the time until
  # given session (included) and return the data as in a multidimensional
  # hash that has keys as follows:
  # hash[feature_name][testcase_name][group_name][measurement_name]['long_json'] =
  #   A hash with keys name, series, and data. This is used for the modal graphs
  # hash[feature_name][testcase_name][group_name][measurement_name]['json'] =
  #   A hash with keys name, unit, and data. This is used for the inline graphs
  #
  # The key figures are on the same level as long_json and json data in the hash.
  # The keys for the figures are min, max, avg and med, correspondingly.
  def find_measurements
    data = MeegoTestSession.find_by_sql([GET_NFT_RESULTS_QUERY,
                                         @session.release_id,
                                         @session.profile.id,
                                         @session.testset,
                                         @session.product,
                                         @session.tested_at,
                                         true])

    handle_db_measurements(data, :nft)
  end

  # Get serial measurement trends for given session. Output format the same
  # as in find_measurements
  def find_serial_measurements
    data = MeegoTestSession.find_by_sql([GET_SERIAL_MEASUREMENTS_QUERY,
                                         @session.release_id,
                                         @session.profile.id,
                                         @session.testset,
                                         @session.product,
                                         @session.tested_at,
                                         true])

    handle_db_measurements(data, :serial)
  end

  # Go through the results of the DB queries. The serial and NFT versions
  # have only minor differences in handling the results
  def handle_db_measurements(db_data, mode)

    feature     = ""
    testcase    = ""
    group       = ""
    measurement = ""
    long_json   = {name: "", series: [], data: []}
    json        = {name: "", unit: "",   data: []}

    # This will contain the actual structural measurement data and is
    # what is eventually returned from this method.
    hash = Hash.new
    db_data.each do |db_row|
      new_group = db_row.group_name.nil? ? "" : db_row.group_name
      # Start a new measurement
      if [feature, testcase, measurement, group] != [db_row.feature, db_row.test_case, db_row.measurement, new_group]
        begin_new_measurement(hash, db_row,
                              feature, testcase, group, measurement,
                              long_json, json, mode)
      end

      # Two JSON representations are created, one for the small graph
      # and one for the modal graph
      if mode == :serial
        long_json[:data] << [db_row.tested_at.strftime("%Y/%m/%d"),
                             db_row.max_value,
                             db_row.avg_value,
                             db_row.med_value,
                             db_row.min_value]

        # Only medians here, used in the small graph
        json[:data] << db_row.med_value

      elsif mode == :nft
        long_json[:data] << [db_row.tested_at.strftime("%Y/%m/%d"),
                             db_row.value]

        json[:data] << db_row.value
      end

    end

    # Last measurement data was not written in the loop above
    add_value(hash, feature, testcase, group, measurement, "long_json", long_json)
    add_value(hash, feature, testcase, group, measurement, "json", json)

    count_key_figures(hash)

    hash
  end

  def begin_new_measurement(hash, db_row,
                            feature, testcase, group, measurement,
                            long_json, json, mode)


    add_value(hash, feature, testcase, group, measurement, "long_json", long_json)
    add_value(hash, feature, testcase, group, measurement, "json", json)

    unit = (db_row.unit || " value").strip
    feature.replace(db_row.feature)
    testcase.replace(db_row.test_case)
    # When handling non-serial NFT there is no group name.
    group.replace(db_row.group_name.nil? ? "" : db_row.group_name)
    measurement.replace(db_row.measurement)

    if mode == :serial
      series = [{name: "Max #{measurement}", unit: unit.dup},
                {name: "Avg #{measurement}", unit: unit.dup},
                {name: "Med #{measurement}", unit: unit.dup},
                {name: "Min #{measurement}", unit: unit.dup}]
    else
      series = [{name: measurement.dup, unit: unit.dup}]
    end

    json.replace({name: measurement.dup, unit: unit.dup, data: []})
    long_json.replace({name:  measurement.dup, series: series.dup, data: []})
  end

  # Construct the hash that holds all data in previously described structure
  def add_value(container, feature, testcase, group, measurement, format, data)
    return if data.empty?
    return if data.kind_of?(Hash) and data[:data].empty?

    container[feature] ||= Hash.new
    container[feature][testcase] ||= Hash.new
    if group.blank?
      container[feature][testcase][measurement] ||= Hash.new
      container[feature][testcase][measurement][format] = data.dup
    else
      container[feature][testcase][group] ||= Hash.new
      container[feature][testcase][group][measurement] ||= Hash.new
      container[feature][testcase][group][measurement][format] = data.dup
    end
  end

  # Count the key figures that are shown below the small Bluff graphs
  # in history view (min, max, avg, med) and add them to the hash given.
  def count_key_figures(data, key=nil)
    return if data.nil?

    # If we have measurement data (JSON), get/calculate the key figures
    # (min, max, avg, med) needed for Bluff graphs
    if data.has_key?('json')
      raw_data    = data['json'][:data].select &:present?
      data['min'] = 'N/A'
      data['max'] = 'N/A'
      data['avg'] = 'N/A'
      data['med'] = 'N/A'

      size = raw_data.size
      if (size > 0)
        # Count the median value
        if (size % 2) == 0
          median = (raw_data[size/2] + raw_data[size/2-1])/2.0
        elsif size > 0
          median = raw_data[size/2]
        end

        data['max'] = format_value(raw_data.max, 3)
        data['min'] = format_value(raw_data.min, 3)
        data['med'] = format_value(median, 3)
        data['avg'] = format_value(raw_data.inject{|sum,el| sum + el}.to_f / size, 3)
      end
    else
      # Keep going until the level where the key figures are is found
      data.each do |m, h| count_key_figures(h, m) end
    end
  end

end
