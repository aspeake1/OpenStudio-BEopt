require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsDoorsTest < MiniTest::Test
  
  def test_retrofit_replace
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    door_r = 0.04445/0.0612266553480475
    expected_values = {"DoorR"=>door_r, "WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Wood.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Wood.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Wood.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Wood.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Wood.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Wood.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Wood.coatingLayerWaterVaporDiffusionResistanceFactor}
    model = _test_measure("SFD_2000sqft_2story_SL_GRG_UA_Windows_Doors.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["ufactor"] = 0.48
    expected_num_del_objects = {"Material"=>1, "Construction"=>1, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    door_r = 0.04445/0.2092601547388782
    expected_values = {"DoorR"=>door_r, "WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Wood.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Wood.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Wood.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Wood.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Wood.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Wood.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Wood.coatingLayerWaterVaporDiffusionResistanceFactor}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)    
  end
  
  def test_argument_error_invalid_ufactor
    args_hash = {}
    args_hash["ufactor"] = 0
    result = _test_error("SFD_2000sqft_2story_SL_GRG_UA_Windows_Doors.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Door U-Factor must be greater than 0.")    
  end  
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsDoors.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file)

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
      
    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    # create an instance of the measure
    measure = ProcessConstructionsDoors.new

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

    # show the output
    #show_output(result)
    
    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    
    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = ["ScheduleRule", "ScheduleDay", "ScheduleTypeLimits"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    actual_values = {"DoorR"=>0, "WaterVaporDiffusionResistanceFactor"=>0, "MoistureEquationCoefficientA"=>0, "MoistureEquationCoefficientB"=>0, "MoistureEquationCoefficientC"=>0, "MoistureEquationCoefficientD"=>0, "CoatingLayerThickness"=>0, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "Material"
                new_object = new_object.to_StandardOpaqueMaterial.get
                actual_values["DoorR"] += new_object.thickness / new_object.conductivity
            elsif obj_type == "MaterialPropertyMoisturePenetrationDepthSettings"
              actual_values["WaterVaporDiffusionResistanceFactor"] += new_object.waterVaporDiffusionResistanceFactor
              actual_values["MoistureEquationCoefficientA"] += new_object.moistureEquationCoefficientA
              actual_values["MoistureEquationCoefficientB"] += new_object.moistureEquationCoefficientB
              actual_values["MoistureEquationCoefficientC"] += new_object.moistureEquationCoefficientC
              actual_values["MoistureEquationCoefficientD"] += new_object.moistureEquationCoefficientD
              actual_values["CoatingLayerThickness"] += new_object.coatingLayerThickness
              actual_values["CoatingLayerWaterVaporDiffusionResistanceFactor"] += new_object.coatingLayerWaterVaporDiffusionResistanceFactor
            end
        end
    end
    assert_in_epsilon(expected_values["DoorR"], actual_values["DoorR"], 0.01)
    assert_in_epsilon(expected_values["WaterVaporDiffusionResistanceFactor"], actual_values["WaterVaporDiffusionResistanceFactor"], 0.01)
    assert_in_epsilon(expected_values["MoistureEquationCoefficientA"], actual_values["MoistureEquationCoefficientA"], 0.01)
    assert_in_epsilon(expected_values["MoistureEquationCoefficientB"], actual_values["MoistureEquationCoefficientB"], 0.01)
    assert_in_epsilon(expected_values["MoistureEquationCoefficientC"], actual_values["MoistureEquationCoefficientC"], 0.01)
    assert_in_epsilon(expected_values["MoistureEquationCoefficientD"], actual_values["MoistureEquationCoefficientD"], 0.01)
    assert_in_epsilon(expected_values["CoatingLayerThickness"], actual_values["CoatingLayerThickness"], 0.01)
    assert_in_epsilon(expected_values["CoatingLayerWaterVaporDiffusionResistanceFactor"], actual_values["CoatingLayerWaterVaporDiffusionResistanceFactor"], 0.01)

    return model
  end  
  
end
