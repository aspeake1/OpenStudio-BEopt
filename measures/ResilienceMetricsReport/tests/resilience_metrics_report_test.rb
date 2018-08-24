require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResilienceMetricsReportTest < MiniTest::Test

  def test_argument_error
    args_hash = {}
    args_hash["output_vars"] = "Zone Mean Air Temperature, Zone Air Relative Humidity"
    args_hash["min_vals"] = "60, 5, 0"
    args_hash["max_vals"] = "80, 60, 0"
    result = _test_error(args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Number of output variable elements specified inconsistent with either number of minimum or maximum values.")    
  end

  def test_resilience_metrics
    resilience_metrics = {
                         # output_var=>[timeseries, min_val, max_val, hours_spent_below, hours_spent_above, ix_outage_start, ix_outage_end]
                         "Zone Mean Air Temperature"=>[[4.4]*8760, 60, 80, 15, 0, 10, 25],
                         "Zone Air Relative Humidity"=>[[60]*8760, "NA", 60, nil, 0, 0, 24],
                         "Wetbulb Globe Temperature"=>[[32]*8760, "NA", 88, nil, 48, 24, 72]
                        }
    _test_resilience_metrics(resilience_metrics)
  end

  def test_coast_times
    coast_times = {
                  # output_var=>[timeseries, min_val, max_val, hours_until_below, hours_until_above, ix_outage_start, ix_outage_end]
                  "Zone Mean Air Temperature"=>[[-6.6]*10 + [0]*8750, 60, 80, 0, nil, 0, 24],
                  "Zone Air Relative Humidity"=>[[50]*100 + [65]*8660, "NA", 60, nil, 20, 80, 120],
                  "Wetbulb Globe Temperature"=>[[29.4]*5 + [32]*8755, "NA", 88, nil, 2, 3, 24]
                }
    _test_coast_times(coast_times)
  end

  def test_end_of_outage_vals
    end_of_outage_vals = {
                         # output_var=>[timeseries, end_of_outage_val, ix_outage_end]
                         "End Of Outage Indoor Drybulb Temperature"=>[[29.4]*50 + [32]*8710, 90, 60]
                        }
    _test_end_of_outage_vals(end_of_outage_vals)
  end

  private
  
  def _test_resilience_metrics(resilience_metrics)

    # create an instance of the measure
    measure = ResilienceMetricsReport.new
    
    # Check for correct resilience metrics values
    resilience_metrics.each do |resilience_metric, resilience_metric_values|
      values, min_val, max_val, expected_hours_below, expected_hours_above, ix_outage_start, ix_outage_end = resilience_metric_values
      actual_hours_below, actual_hours_above = measure.calc_resilience_metric(resilience_metric, values, min_val, max_val, ix_outage_start, ix_outage_end)
      if expected_hours_below.nil?
        assert_nil(actual_hours_below)
      else
        assert_in_epsilon(expected_hours_below, actual_hours_below, 0.01)
      end
      if expected_hours_above.nil?
        assert_nil(actual_hours_above)
      else
        assert_in_epsilon(expected_hours_above, actual_hours_above, 0.01)
      end
    end

  end

  def _test_coast_times(coast_times)

    # create an instance of the measure
    measure = ResilienceMetricsReport.new
    
    # Check for correct resilience metrics values
    coast_times.each do |coast_time, coast_time_values|
      values, min_val, max_val, expected_hours_below, expected_hours_above, ix_outage_start, ix_outage_end = coast_time_values
      actual_hours_below, actual_hours_above = measure.calc_coast_time(coast_time, values, min_val, max_val, ix_outage_start, ix_outage_end)
      if expected_hours_below.nil?
        assert_nil(actual_hours_below)
      else
        assert_in_epsilon(expected_hours_below, actual_hours_below, 0.01)
      end
      if expected_hours_above.nil?
        assert_nil(actual_hours_above)
      else
        assert_in_epsilon(expected_hours_above, actual_hours_above, 0.01)
      end
    end

  end

  def _test_end_of_outage_vals(end_of_outage_vals)
    # create an instance of the measure
    measure = ResilienceMetricsReport.new
    
    # Check for correct resilience metrics values
    end_of_outage_vals.each do |end_of_outage_val, end_of_outage_val_values|
      values, expected_val, ix_outage_end = end_of_outage_val_values
      actual_val = measure.calc_end_of_outage_val(end_of_outage_val, values, ix_outage_end)
      assert_in_epsilon(expected_val, actual_val, 0.01)
    end

  end

  def _test_error(args_hash)
    # create an instance of the measure
    measure = ResilienceMetricsReport.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(runner, argument_map)
    result = runner.result

    # show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)

    return result
  end

end
