require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessHeatingSetpointsTest < MiniTest::Test

  def test_error_no_weather
    args_hash = {}
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Model has not been assigned a weather file.")    
  end 

  def test_argument_error_not_24_values
    args_hash = {}
    args_hash["weekday_setpoint"] = "71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71"
    result = _test_error("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_NoSetpoints.osm", args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "A comma-separated string of 24 numbers must be entered for the weekday schedule.")    
  end
  
  def test_no_equip
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
  end
  
  def test_wkdy_wked_are_different
    args_hash = {}
    args_hash["weekday_setpoint"] = "72"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>48, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {"heating_setpoint_sch_heating_season"=>72, "heating_setpoint_sch_overlap_season"=>72, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_furnace
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  
  
  def test_air_source_heat_pump
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_ASHP_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end
  
  def test_mini_split_heat_pump
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_MSHP_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end

  def test_boiler
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Boiler_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_unit_heater
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_UnitHeater_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_electric_baseboard
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_ElectricBaseboard_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  
  
  def test_gshp_vert_bore
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_GSHPVertBore_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)  
  end
  
  def test_retrofit_replace
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
    expected_num_del_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)    
  end
  
  def test_cooling_setpoints_exist_and_h_more_than_c
    args_hash = {}
    args_hash["weekday_setpoint"] = "77"
    args_hash["weekend_setpoint"] = "77"
    expected_num_del_objects = {"ScheduleRule"=>24, "ScheduleRuleset"=>2}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3}
    expected_values = {"heating_setpoint_sch_heating_season"=>77, "heating_setpoint_sch_overlap_season"=>76.5, "cooling_setpoint_sch_cooling_season"=>76, "cooling_setpoint_sch_overlap_season"=>76.5}
     _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC_NoHtgSetpoint.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>num_units}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure("SFA_4units_1story_SL_UA_3Beds_2Baths_Denver_Furnace_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*5)
  end

  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>num_units}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure("MF_8units_1story_SL_3Beds_2Baths_Denver_Furnace_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*5)
  end
  
  def test_auto_heating_season
    args_hash = {}
    args_hash["use_auto_season"] = true
    expected_num_del_objects = {"ScheduleRule"=>24, "ScheduleRuleset"=>2}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>76, "cooling_setpoint_sch_overlap_season"=>76}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC_NoHtgSetpoint.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end
  
  def test_custom_heating_season_loop_around_year
    args_hash = {}
    args_hash["season_start_month"] = "Oct"
    args_hash["season_end_month"] = "Mar"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {"heating_setpoint_sch_heating_season"=>71, "heating_setpoint_sch_overlap_season"=>71, "cooling_setpoint_sch_cooling_season"=>18000, "cooling_setpoint_sch_overlap_season"=>18000}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  private

  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ProcessHeatingSetpoints.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get arguments
    arguments = measure.arguments(model)
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
    measure.run(model, runner, argument_map)
    result = runner.result

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessHeatingSetpoints.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)
    
    # get arguments
    arguments = measure.arguments(model)
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
    measure.run(model, runner, argument_map)
    result = runner.result
    
    # show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert_equal(num_infos, result.info.size)
    assert_equal(num_warnings, result.warnings.size)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["ScheduleDay", "ScheduleTypeLimits"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "ScheduleRule" and new_object.name.to_s.start_with? Constants.ObjectNameHeatingSetpoint and new_object.applyMonday
                if new_object.startDate.get.monthOfYear.value == 1 # heating season
                    assert_in_epsilon(expected_values["heating_setpoint_sch_heating_season"], UnitConversions.convert(new_object.daySchedule.values[0],"C","F"), 0.01)
                elsif new_object.startDate.get.monthOfYear.value == 10 # overlap season
                    assert_in_epsilon(expected_values["heating_setpoint_sch_overlap_season"], UnitConversions.convert(new_object.daySchedule.values[0],"C","F"), 0.01)
                end
            elsif obj_type == "ScheduleRule" and new_object.name.to_s.start_with? Constants.ObjectNameCoolingSetpoint and new_object.applyMonday
                if new_object.startDate.get.monthOfYear.value == 1 # heating season
                    assert_in_epsilon(expected_values["cooling_setpoint_sch_overlap_season"], UnitConversions.convert(new_object.daySchedule.values[0],"C","F"), 0.01)
                elsif new_object.startDate.get.monthOfYear.value == 7 # cooling season
                    assert_in_epsilon(expected_values["cooling_setpoint_sch_cooling_season"], UnitConversions.convert(new_object.daySchedule.values[0],"C","F"), 0.01)
                elsif new_object.startDate.get.monthOfYear.value == 10 # overlap season
                    assert_in_epsilon(expected_values["cooling_setpoint_sch_overlap_season"], UnitConversions.convert(new_object.daySchedule.values[0],"C","F"), 0.01)
                end
            end
        end
    end    
    
    return model
  end  
  
end
