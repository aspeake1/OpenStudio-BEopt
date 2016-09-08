require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialGasFireplaceTest < MiniTest::Test

  def osm_geo
    return "2000sqft_2story_FB_GRG_UA.osm"
  end

  def osm_geo_beds
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end
  
  def osm_geo_multifamily_3_units
    return "multifamily_3_units.osm"
  end
  
  def osm_geo_multifamily_3_units_beds
    return "multifamily_3_units_Beds_Baths.osm"
  end
  
  def test_new_construction_none1
    # Using annual energy
    args_hash = {}
    args_hash["base_energy"] = 0.0
    _test_measure(osm_geo_beds, args_hash, 0, 0, 0.0)
  end
  
  def test_new_construction_none2
    # Using energy multiplier
    args_hash = {}
    args_hash["mult"] = 0.0
    _test_measure(osm_geo_beds, args_hash, 0, 0, 0.0)
  end
  
  def test_new_construction_gas
    args_hash = {}
    args_hash["base_energy"] = 60.0
    _test_measure(osm_geo_beds, args_hash, 0, 1, 60.6)
  end
  
  def test_new_construction_mult_0_032
    args_hash = {}
    args_hash["base_energy"] = 60.0
    args_hash["mult"] = 0.032
    _test_measure(osm_geo_beds, args_hash, 0, 1, 1.94)
  end
  
  def test_new_construction_modified_schedule
    args_hash = {}
    args_hash["base_energy"] = 60.0
    args_hash["weekday_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["weekend_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["monthly_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12"
    _test_measure(osm_geo_beds, args_hash, 0, 1, 60.6)
  end

  def test_new_construction_no_scale_energy
    args_hash = {}
    args_hash["base_energy"] = 60.0
    args_hash["scale_energy"] = "false"
    _test_measure(osm_geo_beds, args_hash, 0, 1, 60.0)
  end

  def test_new_construction_basement
    args_hash = {}
    args_hash["base_energy"] = 60.0
    args_hash["space"] = Constants.FinishedBasementSpace
    _test_measure(osm_geo_beds, args_hash, 0, 1, 60.6)
  end

  def test_new_construction_garage
    args_hash = {}
    args_hash["base_energy"] = 60.0
    args_hash["space"] = Constants.GarageSpace
    _test_measure(osm_geo_beds, args_hash, 0, 1, 60.6)
  end

  def test_retrofit_replace
    args_hash = {}
    args_hash["base_energy"] = 60.0
    model = _test_measure(osm_geo_beds, args_hash, 0, 1, 60.6)
    args_hash = {}
    args_hash["base_energy"] = 30.0
    _test_measure(model, args_hash, 1, 1, 30.3, 1)
  end
  
  def test_retrofit_remove
    args_hash = {}
    args_hash["base_energy"] = 60.0
    model = _test_measure(osm_geo_beds, args_hash, 0, 1, 60.6)
    args_hash = {}
    args_hash["base_energy"] = 0.0
    _test_measure(model, args_hash, 1, 0, 0.0, 1)
  end
  
  def test_multifamily_new_construction
    num_units = 3
    args_hash = {}
    args_hash["base_energy"] = 60.0
    _test_measure(osm_geo_multifamily_3_units_beds, args_hash, 0, num_units, 160.5, num_units)
  end
  
  def test_multifamily_new_construction_finished_basement
    num_units = 3
    args_hash = {}
    args_hash["base_energy"] = 60.0
    args_hash["space"] = "finishedbasement_1"
    _test_measure(osm_geo_multifamily_3_units_beds, args_hash, 0, 1, 59.1)
  end
  
  def test_multifamily_retrofit_replace
    num_units = 3
    args_hash = {}
    args_hash["base_energy"] = 60.0
    model = _test_measure(osm_geo_multifamily_3_units_beds, args_hash, 0, num_units, 160.5, num_units)
    args_hash = {}
    args_hash["base_energy"] = 30.0
    _test_measure(model, args_hash, num_units, num_units, 80.2, 2*num_units)
  end
  
  def test_multifamily_retrofit_remove
    num_units = 3
    args_hash = {}
    args_hash["base_energy"] = 60.0
    model = _test_measure(osm_geo_multifamily_3_units_beds, args_hash, 0, num_units, 160.5, num_units)
    args_hash = {}
    args_hash["base_energy"] = 0.0
    _test_measure(model, args_hash, num_units, 0, 0.0, num_units)
  end
  
  def test_argument_error_base_energy_negative
    args_hash = {}
    args_hash["base_energy"] = -1.0
    _test_error(osm_geo_beds, args_hash)
  end
  
  def test_argument_error_mult_negative
    args_hash = {}
    args_hash["mult"] = -1.0
    _test_error(osm_geo_beds, args_hash)
  end
  
  def test_argument_error_weekday_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekday_sch"] = "1,1"
    _test_error(osm_geo_beds, args_hash)
  end
  
  def test_argument_error_weekday_sch_not_number
    args_hash = {}
    args_hash["weekday_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    _test_error(osm_geo_beds, args_hash)
  end
    
  def test_argument_error_weekend_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekend_sch"] = "1,1"
    _test_error(osm_geo_beds, args_hash)
  end
    
  def test_argument_error_weekend_sch_not_number
    args_hash = {}
    args_hash["weekend_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    _test_error(osm_geo_beds, args_hash)
  end
  
  def test_argument_error_monthly_sch_wrong_number_of_values  
    args_hash = {}
    args_hash["monthly_sch"] = "1,1"
    _test_error(osm_geo_beds, args_hash)
  end
  
  def test_argument_error_monthly_sch_not_number
    args_hash = {}
    args_hash["monthly_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1"
    _test_error(osm_geo_beds, args_hash)
  end
  
  def test_error_missing_beds
    args_hash = {}
    _test_error(osm_geo, args_hash)
  end
  
  def test_error_missing_beds_multifamily
    args_hash = {}
    _test_error(osm_geo_multifamily_3_units, args_hash)
  end
    
  def test_error_missing_geometry
    args_hash = {}
    _test_error(nil, args_hash)
  end
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialGasFireplace.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = _get_model(osm_file)

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
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_annual_therm, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialGasFireplace.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = _get_model(osm_file_or_model)

    # store the original equipment in the seed model
    orig_equip = model.getElectricEquipments + model.getGasEquipments

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
    
    # get new/deleted equipment objects
    new_objects = []
    (model.getElectricEquipments + model.getGasEquipments).each do |equip|
        next if orig_equip.include?(equip)
        new_objects << equip
    end
    del_objects = []
    orig_equip.each do |equip|
        next if model.getElectricEquipments.include?(equip) or model.getGasEquipments.include?(equip)
        del_objects << equip
    end
    
    # check for num new/del objects
    assert_equal(expected_num_del_objects, del_objects.size)
    assert_equal(expected_num_new_objects, new_objects.size)
    
    actual_annual_therm = 0.0
    new_objects.each do |new_object|
        # check that the new object has the correct name
        assert(new_object.name.to_s.start_with?(Constants.ObjectNameGasFireplace))
        
        # check new object is in correct space
        if argument_map["space"].hasValue
            assert_equal(new_object.space.get.name.to_s, argument_map["space"].valueAsString)
        end
        
        # check for the correct annual energy consumption
        full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
        actual_annual_therm += OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "therm").get
    end
    assert_in_epsilon(expected_annual_therm, actual_annual_therm, 0.01)

    return model
  end
  
  def _get_model(osm_file_or_model)
    if osm_file_or_model.is_a?(OpenStudio::Model::Model)
        # nothing to do
        model = osm_file_or_model
    elsif osm_file_or_model.nil?
        # make an empty model
        model = OpenStudio::Model::Model.new
    else
        # load the test model
        translator = OpenStudio::OSVersion::VersionTranslator.new
        path = OpenStudio::Path.new(File.join(File.dirname(__FILE__), osm_file_or_model))
        model = translator.loadModel(path)
        assert((not model.empty?))
        model = model.get
    end
    return model
  end
  
end