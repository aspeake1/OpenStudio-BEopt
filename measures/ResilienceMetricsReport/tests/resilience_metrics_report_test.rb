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
                         # output_var=>[timeseries, min_val, max_val, hours_spent_below, hours_spent_above]
                         "Zone Mean Air Temperature"=>[[4.4]*8760, 60, 80, 8760, 0],
                         "Zone Air Relative Humidity"=>[[60]*8760, "NA", 60, nil, 0],
                         "Wet Bulb Globe Temperature"=>[[32]*8760, "NA", 88, nil, 8760]
                        }
    _test_resilience_metrics(resilience_metrics)
  end

  def test_coast_times
    coast_times = {
                  # output_var=>[timeseries, min_val, max_val, hours_until_below, hours_until_above]
                  "Zone Mean Air Temperature"=>[[-6.6]*10 + [0]*8750, 60, 80, 0, nil],
                  "Zone Air Relative Humidity"=>[[50]*100 + [65]*8660, "NA", 60, nil, 100],
                  "Wet Bulb Globe Temperature"=>[[29.4]*5 + [32]*8755, "NA", 88, nil, 5]
                }
    _test_coast_times(coast_times)
  end

  private
  
  def _test_resilience_metrics(resilience_metrics)

    # create an instance of the measure
    measure = ResilienceMetricsReport.new
    
    # Check for correct resilience metrics values
    resilience_metrics.each do |resilience_metric, resilience_metric_values|
      values, min_val, max_val, expected_hours_below, expected_hours_above = resilience_metric_values
      actual_hours_below, actual_hours_above = measure.calc_resilience_metric(resilience_metric, values, min_val, max_val)
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
      values, min_val, max_val, expected_hours_below, expected_hours_above = coast_time_values
      actual_hours_below, actual_hours_above = measure.calc_coast_time(coast_time, values, min_val, max_val)
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
