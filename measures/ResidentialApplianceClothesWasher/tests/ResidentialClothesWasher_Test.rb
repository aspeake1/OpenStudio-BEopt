require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialClothesWasherTest < MiniTest::Test

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
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHtank.osm"
  end

  def osm_geo_beds_loc_tanklesswh
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHtankless.osm"
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
    args_hash["cw_mult_e"] = 0.0
    args_hash["cw_mult_hw"] = 0.0
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 0, 0.0, 0.0)
  end
  
  def test_new_construction_standard
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 42.9, 10.00)
  end
  
  def test_new_construction_energystar
    args_hash = {}
    args_hash["cw_mef"] = 2.47
    args_hash["cw_rated_annual_energy"] = 123
    args_hash["cw_annual_cost"] = 9.0
    args_hash["cw_drum_volume"] = 3.68
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 34.9, 2.27)
  end
  
  def test_new_construction_standard_2003
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    args_hash["cw_test_date"] = 2003
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 176.0, 4.80)
  end

  def test_new_construction_standard_mult_0_80
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    args_hash["cw_mult_e"] = 0.8
    args_hash["cw_mult_hw"] = 0.8
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 34.3, 8.00)
  end
  
  def test_new_construction_standard_int_heater
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    args_hash["cw_internal_heater"] = "true"
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 42.9, 10.00)
  end

  def test_new_construction_standard_no_thermostatic_control
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    args_hash["cw_thermostatic_control"] = "false"
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 42.9, 8.67)
  end

  def test_new_construction_energystar_cold_inlet
    args_hash = {}
    args_hash["cw_mef"] = 2.47
    args_hash["cw_rated_annual_energy"] = 123.0
    args_hash["cw_annual_cost"] = 9.0
    args_hash["cw_drum_volume"] = 3.68
    args_hash["cw_cold_cycle"] = "true"
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 34.9, 2.27)
  end

  def test_new_construction_energystar_cold_inlet_tankless
    args_hash = {}
    args_hash["cw_mef"] = 2.47
    args_hash["cw_rated_annual_energy"] = 123.0
    args_hash["cw_annual_cost"] = 9.0
    args_hash["cw_drum_volume"] = 3.68
    args_hash["cw_cold_cycle"] = "true"
    _test_measure(osm_geo_beds_loc_tanklesswh, args_hash, 0, 2, 34.9, 2.27)
  end

  def test_new_construction_basement
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    args_hash["space"] = Constants.FinishedBasementSpace
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 42.9, 10.00)
  end

  def test_retrofit_replace
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    model = _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 42.9, 10.00)
    args_hash = {}
    args_hash["cw_mef"] = 2.47
    args_hash["cw_rated_annual_energy"] = 123.0
    args_hash["cw_annual_cost"] = 9.0
    args_hash["cw_drum_volume"] = 3.68
    _test_measure(model, args_hash, 2, 2, 34.9, 2.27, 1)
  end
    
  def test_retrofit_remove
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    model = _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 42.9, 10.00)
    args_hash = {}
    args_hash["cw_mult_e"] = 0.0
    args_hash["cw_mult_hw"] = 0.0
    _test_measure(model, args_hash, 2, 0, 0.0, 0.0, 1)
  end
  
  def test_multifamily_new_construction
    num_units = 3
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, 0, 2*num_units, 121.5, 28.3, num_units)
  end
  
  def test_multifamily_new_construction_finished_basement
    num_units = 3
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    args_hash["space"] = "finishedbasement_1"
    _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, 0, 2, 42.9, 10.0)
  end
  
  def test_multifamily_new_construction_mult_draw_profiles
    num_units = 12
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    _test_measure(osm_geo_multifamily_12_units_beds_loc_tankwh, args_hash, 0, 2*num_units, 514.8, 120, num_units)
  end
  
  def test_multifamily_retrofit_replace
    num_units = 3
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    model = _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, 0, 2*num_units, 121.5, 28.3, num_units)
    args_hash = {}
    args_hash["cw_mef"] = 2.47
    args_hash["cw_rated_annual_energy"] = 123
    args_hash["cw_annual_cost"] = 9.0
    args_hash["cw_drum_volume"] = 3.68
    _test_measure(model, args_hash, 2*num_units, 2*num_units, 98.9, 6.4, 2*num_units)
  end
  
  def test_multifamily_retrofit_remove
    num_units = 3
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    model = _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, 0, 2*num_units, 121.5, 28.3, num_units)
    args_hash = {}
    args_hash["cw_mult_e"] = 0.0
    args_hash["cw_mult_hw"] = 0.0
    _test_measure(model, args_hash, 2*num_units, 0, 0.0, 0.0, num_units)
  end
  
  def test_argument_error_cw_mef_negative
    args_hash = {}
    args_hash["cw_mef"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Modified energy factor must be greater than 0.0.")
  end
  
  def test_argument_error_cw_mef_zero
    args_hash = {}
    args_hash["cw_mef"] = 0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Modified energy factor must be greater than 0.0.")
  end

  def test_argument_error_cw_rated_annual_energy_negative
    args_hash = {}
    args_hash["cw_rated_annual_energy"] = -1.0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Rated annual consumption must be greater than 0.0.")
  end
  
  def test_argument_error_cw_rated_annual_energy_zero
    args_hash = {}
    args_hash["cw_rated_annual_energy"] = 0.0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Rated annual consumption must be greater than 0.0.")
  end

  def test_argument_error_cw_test_date_negative
    args_hash = {}
    args_hash["cw_test_date"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Test date must be greater than or equal to 1900.")
  end

  def test_argument_error_cw_test_date_zero
    args_hash = {}
    args_hash["cw_test_date"] = 0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Test date must be greater than or equal to 1900.")
  end

  def test_argument_error_cw_annual_cost_negative
    args_hash = {}
    args_hash["cw_annual_cost"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Annual cost with gas DHW must be greater than 0.0.")
  end

  def test_argument_error_cw_annual_cost_zero
    args_hash = {}
    args_hash["cw_annual_cost"] = 0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Annual cost with gas DHW must be greater than 0.0.")
  end
  
  def test_argument_error_cw_drum_volume_negative
    args_hash = {}
    args_hash["cw_drum_volume"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Drum volume must be greater than 0.0.")
  end

  def test_argument_error_cw_drum_volume_zero
    args_hash = {}
    args_hash["cw_drum_volume"] = 0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Drum volume must be greater than 0.0.")
  end

  def test_argument_error_cw_mult_e_negative
    args_hash = {}
    args_hash["cw_mult_e"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Occupancy energy multiplier must be greater than or equal to 0.0.")
  end

  def test_argument_error_cw_mult_hw_negative
    args_hash = {}
    args_hash["cw_mult_hw"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Occupancy hot water multiplier must be greater than or equal to 0.0.")
  end

  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result.errors[0].logMessage, "Cannot determine number of building units; Building::standardsNumberOfLivingUnits has not been set.")
  end
  
  def test_error_missing_beds
    args_hash = {}
    result = _test_error(osm_geo_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
  end
  
  def test_error_missing_location
    args_hash = {}
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors[0].logMessage, "Mains water temperature has not been set.")
  end

  def test_error_missing_water_heater
    args_hash = {}
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Could not find plant loop.")
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialClothesWasher.new
    
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

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_annual_kwh, expected_hw_gpd, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialClothesWasher.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # store the original equipment in the seed model
    orig_equip = model.getElectricEquipments + model.getWaterUseEquipments

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
    
    # get new/deleted electric equipment objects
    new_objects = []
    (model.getElectricEquipments + model.getWaterUseEquipments).each do |equip|
        next if orig_equip.include?(equip)
        new_objects << equip
    end
    del_objects = []
    orig_equip.each do |equip|
        next if (model.getElectricEquipments + model.getWaterUseEquipments).include?(equip)
        del_objects << equip
    end
    
    # check for num new/del objects
    assert_equal(expected_num_del_objects, del_objects.size)
    assert_equal(expected_num_new_objects, new_objects.size)
    
    actual_annual_kwh = 0.0
    actual_hw_gpd = 0.0
    new_objects.each do |new_object|
        # check that the new object has the correct name
        assert(new_object.name.to_s.start_with?(Constants.ObjectNameClothesWasher))
    
        # check new object is in correct space
        if argument_map["space"].hasValue
            assert_equal(new_object.space.get.name.to_s, argument_map["space"].valueAsString)
        end
        
        if new_object.is_a?(OpenStudio::Model::ElectricEquipment)
            # check for the correct annual energy consumption
            full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
            actual_annual_kwh += OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh").get
        elsif new_object.is_a?(OpenStudio::Model::WaterUseEquipment)
            # check for the correct daily hot water consumption
            full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.flowRateFractionSchedule.get)
            actual_hw_gpd += OpenStudio.convert(full_load_hrs * new_object.waterUseEquipmentDefinition.peakFlowRate * new_object.multiplier, "m^3/s", "gal/min").get * 60.0 / 365.0
        end
    end
    assert_in_epsilon(expected_annual_kwh, actual_annual_kwh, 0.01)
    assert_in_epsilon(expected_hw_gpd, actual_hw_gpd, 0.02)

    return model
  end
  
end
