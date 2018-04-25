require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ZoneMultipliersTest < MiniTest::Test

  def test_sfd_zone_mult
    args_hash = {}
    expected_num_del_objects = {"BuildingUnit"=>0, "ThermalZone"=>0}
    expected_num_new_objects = {}
    expected_values = {"NumActualZones"=>2, "NumZonesRepresented"=>2}
    _test_measure("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_sfa_zone_mult_front_units_only
    args_hash = {}
    expected_num_del_objects = {"BuildingUnit"=>7, "ThermalZone"=>7}
    expected_num_new_objects = {}
    expected_values = {"NumActualZones"=>3, "NumZonesRepresented"=>10}
    _test_measure("SFA_10units_2story_SL_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_sfa_zone_mult_has_rear_units
    args_hash = {}
    expected_num_del_objects = {"BuildingUnit"=>4, "ThermalZone"=>4}
    expected_num_new_objects = {}
    expected_values = {"NumActualZones"=>6, "NumZonesRepresented"=>10}
    _test_measure("SFA_10units_2story_SL_UA_3Beds_2Baths_Denver_HasRearUnits.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_mf_zone_mult_double_loaded_corridor
    num_finished_spaces = 3
    args_hash = {}
    expected_num_del_objects = {"BuildingUnit"=>22, "ThermalZone"=>22}
    expected_num_new_objects = {}
    expected_values = {"NumActualZones"=>18, "NumZonesRepresented"=>40}
    _test_measure("MF_40units_4story_SL_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end
  
  def test_mf_zone_mult_exterior_corridor
    num_finished_spaces = 3
    args_hash = {}
    expected_num_del_objects = {"BuildingUnit"=>5, "ThermalZone"=>5}
    expected_num_new_objects = {}
    expected_values = {"NumActualZones"=>3, "NumZonesRepresented"=>8}
    _test_measure("MF_8units_1story_SL_Denver_ExteriorCorridor.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  private

  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ZoneMultipliers.new

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

    # show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)

    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, test_name)
    # create an instance of the measure
    measure = ZoneMultipliers.new

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

    # save the model to test output directory
    # output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}.osm")
    # model.save(output_file_path, true)
    
    # show the output
    # show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)

    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = ["Node", "PortList", "SizingZone", "ZoneHVACEquipmentList", "Space", "Surface"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)

    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    actual_values = {"NumActualZones"=>0, "NumZonesRepresented"=>0}
    zones = []
    units = Geometry.get_building_units(model)
    units.each do |unit|
      unit.spaces.each do |space|
        zone = space.thermalZone.get
        unless zones.include? zone
          zones << zone
        end
      end
    end
    zones.each do |zone|
      actual_values["NumActualZones"] += 1
      actual_values["NumZonesRepresented"] += zone.multiplier
    end

    assert_equal(expected_values["NumActualZones"], actual_values["NumActualZones"])
    assert_equal(expected_values["NumZonesRepresented"], actual_values["NumZonesRepresented"])

    return model
  end

end
