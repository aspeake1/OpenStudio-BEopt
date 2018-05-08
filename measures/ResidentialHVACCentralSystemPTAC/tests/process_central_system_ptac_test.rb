require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessCentralSystemPTACTest < MiniTest::Test

  def test_single_family_attached_ptac
    num_zones = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"PlantLoop"=>1, "PumpVariableSpeed"=>1, "BoilerHotWater"=>1, "ControllerWaterCoil"=>1*num_zones, "CoilHeatingWater"=>num_zones, "FanConstantVolume"=>num_zones, "CoilCoolingDXSingleSpeed"=>num_zones, "ZoneHVACPackagedTerminalAirConditioner"=>num_zones}
    expected_values = {}
    _test_measure("SFA_4units_1story_FB_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1)
  end

  def test_multifamily_ptac
    num_zones = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"PlantLoop"=>1, "PumpVariableSpeed"=>1, "BoilerHotWater"=>1, "ControllerWaterCoil"=>1*num_zones, "CoilHeatingWater"=>num_zones, "FanConstantVolume"=>num_zones, "CoilCoolingDXSingleSpeed"=>num_zones, "ZoneHVACPackagedTerminalAirConditioner"=>num_zones}
    expected_values = {}
    _test_measure("MF_8units_1story_SL_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1)
  end

  private

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, test_name, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessCentralSystemPTAC.new

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
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show_output(result)

    # save the model to test output directory
    # output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}.osm")
    # model.save(output_file_path, true)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert_equal(num_infos, result.info.size)
    assert_equal(num_warnings, result.warnings.size)

    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = ["CurveQuadratic", "CurveBiquadratic", "CurveExponent", "CurveCubic", "PipeAdiabatic", "ScheduleTypeLimits", "ScheduleDay",\
                           "AvailabilityManagerAssignmentList", "ConnectorMixer", "ConnectorSplitter", "Node", "SizingPlant", "ScheduleConstant",\
                           "PlantComponentTemperatureSource", "SizingSystem", "AirLoopHVACZoneSplitter", "AirLoopHVACZoneMixer", "ModelObjectList",\
                           "ScheduleRuleset", "SetpointManagerScheduled", "CoilCoolingDXVariableSpeedSpeedData", "AvailabilityManagerNightCycle"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)

    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get

        end
    end

    return model
  end

end