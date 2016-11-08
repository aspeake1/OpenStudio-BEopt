require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialDishwasherTest < MiniTest::Test

  def osm_geo_beds
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end

  def osm_geo_loc
    return "2000sqft_2story_FB_GRG_UA_Denver.osm"
  end

  def osm_geo_beds_loc
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver.osm"
  end

  def osm_geo_beds_loc_tankwh
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHTank.osm"
  end

  def osm_geo_beds_loc_tanklesswh
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHTankless.osm"
  end
  
  def osm_geo_multifamily_3_units_beds_loc_tankwh
    return "multifamily_3_units_Beds_Baths_Denver_ElecWHtank.osm"
  end
  
  def osm_geo_multifamily_12_units_beds_loc_tankwh
    return "multifamily_12_units_Beds_Baths_Denver_ElecWHtank.osm"
  end

  def test_new_construction_none
    # Using energy multiplier
    args_hash = {}
    args_hash["mult_e"] = 0.0
    args_hash["mult_hw"] = 0.0
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "HotWater_gpd"=>0, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_318_rated_kwh
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>111, "HotWater_gpd"=>3.10, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_290_rated_kwh
    args_hash = {}
    args_hash["num_settings"] = 12
    args_hash["dw_E"] = 290
    args_hash["eg_gas_cost"] = 23
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>83.1, "HotWater_gpd"=>1.65, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_318_rated_kwh_mult_0_80
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["mult_e"] = 0.8
    args_hash["mult_hw"] = 0.8
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>88.8, "HotWater_gpd"=>2.48, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_318_rated_kwh_cold_inlet
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["cold_inlet"] = "true"
    args_hash["cold_use"] = 3.5
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>303.8, "HotWater_gpd"=>5.0, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_318_rated_kwh_cold_inlet_tankless
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["cold_inlet"] = "true"
    args_hash["cold_use"] = 3.5
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>303.8, "HotWater_gpd"=>5.0, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_beds_loc_tanklesswh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_318_rated_kwh_no_int_heater
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["int_htr"] = "false"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>124.8, "HotWater_gpd"=>2.41, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_basement
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["space"] = Constants.FinishedBasementSpace
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>111, "HotWater_gpd"=>3.10, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_retrofit_replace
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>111, "HotWater_gpd"=>3.10, "Space"=>args_hash["space"]}
    model = _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["num_settings"] = 12
    args_hash["dw_E"] = 290
    args_hash["eg_gas_cost"] = 23
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>83.1, "HotWater_gpd"=>1.65, "Space"=>args_hash["space"]}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
    
  def test_retrofit_remove
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>111, "HotWater_gpd"=>3.10, "Space"=>args_hash["space"]}
    model = _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["mult_e"] = 0.0
    args_hash["mult_hw"] = 0.0
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "HotWater_gpd"=>0, "Space"=>args_hash["space"]}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_multifamily_new_construction
    num_units = 3
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_values = {"Annual_kwh"=>314.5, "HotWater_gpd"=>8.8, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  def test_multifamily_new_construction_finished_basement
    num_units = 3
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["space"] = "finishedbasement_1"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>111, "HotWater_gpd"=>3.10, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_multifamily_new_construction_mult_draw_profiles
    num_units = 12
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_values = {"Annual_kwh"=>1332, "HotWater_gpd"=>37.2, "Space"=>args_hash["space"]}
    _test_measure(osm_geo_multifamily_12_units_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end

  def test_multifamily_retrofit_replace
    num_units = 3
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_values = {"Annual_kwh"=>314.5, "HotWater_gpd"=>8.8, "Space"=>args_hash["space"]}
    model = _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
    args_hash = {}
    args_hash["num_settings"] = 12
    args_hash["dw_E"] = 290
    args_hash["eg_gas_cost"] = 23
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_values = {"Annual_kwh"=>235.3, "HotWater_gpd"=>4.7, "Space"=>args_hash["space"]}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2*num_units)
  end
  
  def test_multifamily_retrofit_remove
    num_units = 3
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_values = {"Annual_kwh"=>314.5, "HotWater_gpd"=>8.8, "Space"=>args_hash["space"]}
    model = _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
    args_hash = {}
    args_hash["mult_e"] = 0.0
    args_hash["mult_hw"] = 0.0
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "HotWater_gpd"=>0, "Space"=>args_hash["space"]}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  def test_argument_error_num_settings_negative
    args_hash = {}
    args_hash["num_settings"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Number of place settings must be greater than or equal to 1.")
  end
  
  def test_argument_error_num_settings_zero
    args_hash = {}
    args_hash["num_settings"] = 0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Number of place settings must be greater than or equal to 1.")
  end

  def test_argument_error_dw_E_negative
    args_hash = {}
    args_hash["dw_E"] = -1.0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated annual energy consumption must be greater than or equal to 0.")
  end
  
  def test_argument_error_cold_use_negative
    args_hash = {}
    args_hash["cold_use"] = -1.0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Cold water connection use must be greater than or equal to 0.")
  end

  def test_argument_error_eg_date_negative
    args_hash = {}
    args_hash["eg_date"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Energy Guide date must be greater than or equal to 1900.")
  end

  def test_argument_error_eg_date_zero
    args_hash = {}
    args_hash["eg_date"] = 0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Energy Guide date must be greater than or equal to 1900.")
  end

  def test_argument_error_eg_gas_cost_negative
    args_hash = {}
    args_hash["eg_gas_cost"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Energy Guide annual gas cost must be greater than 0.")
  end

  def test_argument_error_eg_gas_cost_zero
    args_hash = {}
    args_hash["eg_gas_cost"] = 0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Energy Guide annual gas cost must be greater than 0.")
  end

  def test_argument_error_mult_e_negative
    args_hash = {}
    args_hash["mult_e"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Occupancy energy multiplier must be greater than or equal to 0.")
  end

  def test_argument_error_mult_hw_negative
    args_hash = {}
    args_hash["mult_hw"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Occupancy hot water multiplier must be greater than or equal to 0.")
  end

  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "No building geometry has been defined.")
  end
  
  def test_error_missing_beds
    args_hash = {}
    result = _test_error(osm_geo_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
  end
  
  def test_error_missing_location
    args_hash = {}
    args_hash["cold_inlet"] = "true"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Mains water temperature has not been set.")
  end

  def test_error_missing_water_heater
    args_hash = {}
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Could not find plant loop.")
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialDishwasher.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = get_model(File.dirname(__FILE__), osm_file)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    #show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialDishwasher.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    #show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    assert(result.finalCondition.is_initialized)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["WaterUseConnections", "Node", "ScheduleTypeLimits"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    actual_values = {"Annual_kwh"=>0, "HotWater_gpd"=>0, "Space"=>[]}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "ElectricEquipment"
                full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
                actual_values["Annual_kwh"] += OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh").get
                actual_values["Space"] << new_object.space.get.name.to_s
            elsif obj_type == "WaterUseEquipment"
                full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.flowRateFractionSchedule.get)
                actual_values["HotWater_gpd"] += OpenStudio.convert(full_load_hrs * new_object.waterUseEquipmentDefinition.peakFlowRate * new_object.multiplier, "m^3/s", "gal/min").get * 60.0 / 365.0
                actual_values["Space"] << new_object.space.get.name.to_s
            end
        end
    end
    assert_in_epsilon(expected_values["Annual_kwh"], actual_values["Annual_kwh"], 0.01)
    assert_in_epsilon(expected_values["HotWater_gpd"], actual_values["HotWater_gpd"], 0.01)
    if not expected_values["Space"].nil?
        assert_equal(1, actual_values["Space"].uniq.size)
        assert_equal(expected_values["Space"], actual_values["Space"][0])
    end

    return model
  end
  
end
