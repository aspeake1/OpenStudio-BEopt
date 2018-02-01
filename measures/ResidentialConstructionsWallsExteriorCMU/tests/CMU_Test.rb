require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsWallsExteriorCMUTest < MiniTest::Test

  def test_add_6in_hollow
    args_hash = {}
    args_hash["thickness"] = 6
    args_hash["conductivity"] = 4.29
    args_hash["density"] = 65
    args_hash["framing_factor"] = 0.076
    args_hash["furring_r"] = 0
    args_hash["furring_cavity_depth"] = 1
    args_hash["furring_spacing"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>2, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.1524/0.538472+0.0254/0.14026, "LayerDensity"=>1001.1218+71.989, "LayerSpecificHeat"=>852.065+1211.355, "LayerIndex"=>0+1}
    _test_measure("SFD_2000sqft_2story_SL_UA_CeilingIns.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_6in_hollow_no_furring
    args_hash = {}
    args_hash["thickness"] = 6
    args_hash["conductivity"] = 4.29
    args_hash["density"] = 65
    args_hash["framing_factor"] = 0.076
    args_hash["furring_r"] = 0
    args_hash["furring_cavity_depth"] = 0
    args_hash["furring_spacing"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.1524/0.538472, "LayerDensity"=>1001.1218, "LayerSpecificHeat"=>852.065, "LayerIndex"=>0}
    _test_measure("SFD_2000sqft_2story_SL_UA_CeilingIns.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_8in_hollow_r10
    args_hash = {}
    args_hash["thickness"] = 8
    args_hash["conductivity"] = 4
    args_hash["density"] = 45
    args_hash["framing_factor"] = 0.076
    args_hash["furring_r"] = 10
    args_hash["furring_cavity_depth"] = 2
    args_hash["furring_spacing"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>2, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.2032/0.284117+0.0508/0.04084, "LayerDensity"=>705.07224+110.334, "LayerSpecificHeat"=>858.2227+1154.524, "LayerIndex"=>0+1}
    _test_measure("SFD_2000sqft_2story_SL_UA_CeilingIns.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_6in_concrete_filled
    args_hash = {}
    args_hash["thickness"] = 6
    args_hash["conductivity"] = 5.33
    args_hash["density"] = 119
    args_hash["framing_factor"] = 0.076
    args_hash["furring_r"] = 0
    args_hash["furring_cavity_depth"] = 1
    args_hash["furring_spacing"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>2, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.1524/0.6499+0.0254/0.1402, "LayerDensity"=>1800.455+71.989, "LayerSpecificHeat"=>845.554+1211.354, "LayerIndex"=>0+1}
    _test_measure("SFD_2000sqft_2story_SL_UA_CeilingIns.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_6in_concrete_filled_to_layers
    args_hash = {}
    args_hash["thickness"] = 6
    args_hash["conductivity"] = 5.33
    args_hash["density"] = 119
    args_hash["framing_factor"] = 0.076
    args_hash["furring_r"] = 0
    args_hash["furring_cavity_depth"] = 1
    args_hash["furring_spacing"] = 24
    expected_num_del_objects = {"Construction"=>1}
    expected_num_new_objects = {"Material"=>2, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.1524/0.6499+0.0254/0.1402, "LayerDensity"=>1800.455+71.989, "LayerSpecificHeat"=>845.554+1211.354, "LayerIndex"=>2+3}
    _test_measure("SFD_2000sqft_2story_SL_UA_AllLayersButWallInsulation_CeilingIns.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_argument_error_thickness_zero
    args_hash = {}
    args_hash["thickness"] = 0
    result = _test_error("SFD_2000sqft_2story_SL_UA_CeilingIns.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "CMU Block Thickness must be greater than 0.")
  end
    
  def test_argument_error_conductivity_zero
    args_hash = {}
    args_hash["conductivity"] = 0
    result = _test_error("SFD_2000sqft_2story_SL_UA_CeilingIns.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "CMU Conductivity must be greater than 0.")
  end

  def test_argument_error_density_zero
    args_hash = {}
    args_hash["density"] = 0
    result = _test_error("SFD_2000sqft_2story_SL_UA_CeilingIns.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "CMU Density must be greater than 0.")
  end

  def test_argument_error_framing_factor_negative
    args_hash = {}
    args_hash["framing_factor"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA_CeilingIns.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Framing Factor must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_framing_factor_eq_1
    args_hash = {}
    args_hash["framing_factor"] = 1.0
    result = _test_error("SFD_2000sqft_2story_SL_UA_CeilingIns.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Framing Factor must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_furring_rvalue_negative
    args_hash = {}
    args_hash["furring_r"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA_CeilingIns.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Furring Insulation R-value must be greater than or equal to 0.")
  end
  
  def test_argument_error_furring_spacing_negative
    args_hash = {}
    args_hash["furring_spacing"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA_CeilingIns.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Furring Stud Spacing must be greater than or equal to 0.")
  end

  def test_argument_error_furring_cavity_depth_negative
    args_hash = {}
    args_hash["furring_cavity_depth"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA_CeilingIns.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Furring Cavity Depth must be greater than or equal to 0.")
  end

  def test_not_applicable_no_geometry
    args_hash = {}
    _test_na(nil, args_hash)
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsWallsExteriorCMU.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file)

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

    # show the output
    #show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end
  
  def _test_na(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsWallsExteriorCMU.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file)

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

    # show the output
    #show_output(result)

    # assert that it returned NA
    assert_equal("NA", result.value.valueName)
    assert(result.info.size == 1)
    
    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    # create an instance of the measure
    measure = ProcessConstructionsWallsExteriorCMU.new

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

    # show the output
    #show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    
    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    actual_values = {"LayerRValue"=>0, "LayerDensity"=>0, "LayerSpecificHeat"=>0, "LayerIndex"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "Material"
                new_object = new_object.to_StandardOpaqueMaterial.get
                actual_values["LayerRValue"] += new_object.thickness/new_object.conductivity
                actual_values["LayerDensity"] += new_object.density
                actual_values["LayerSpecificHeat"] += new_object.specificHeat
            elsif obj_type == "Construction"
                next if !all_new_objects.keys.include?("Material")
                all_new_objects["Material"].each do |new_material|
                    new_material = new_material.to_StandardOpaqueMaterial.get
                    actual_values["LayerIndex"] += new_object.getLayerIndices(new_material)[0]
                end
            end
        end
    end
    assert_in_epsilon(expected_values["LayerRValue"], actual_values["LayerRValue"], 0.02)
    assert_in_epsilon(expected_values["LayerDensity"], actual_values["LayerDensity"], 0.02)
    assert_in_epsilon(expected_values["LayerSpecificHeat"], actual_values["LayerSpecificHeat"], 0.02)
    assert_in_epsilon(expected_values["LayerIndex"], actual_values["LayerIndex"], 0.02)
    
    return model
  end
  
end
