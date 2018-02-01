require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsWallsPartitionThermalMassTest < MiniTest::Test

  def test_add_1_2in_drywall
    args_hash = {}
    args_hash["frac"] = 1.0
    args_hash["thick_in1"] = 0.5
    args_hash["cond1"] = 1.1112
    args_hash["dens1"] = 50.0
    args_hash["specheat1"] = 0.2
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>3, "Construction"=>1, "InternalMass"=>2, "InternalMassDefinition"=>2}
    expected_values = {"MassSqft"=>188, "LayerThickness"=>0.0127*2+0.0889, "LayerConductivity"=>0.16029*2+0.44257, "LayerDensity"=>801*2+83, "LayerSpecificHeat"=>837.4*2+1211.8, "LayerIndex"=>0+1+2}
    _test_measure("SFD_2000sqft_2story_SL_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_2_of_5_8in_drywall_0_5_frac
    args_hash = {}
    args_hash["frac"] = 0.5
    args_hash["thick_in1"] = 0.625
    args_hash["cond1"] = 1.1112
    args_hash["dens1"] = 50.0
    args_hash["specheat1"] = 0.2
    args_hash["thick_in2"] = 0.625
    args_hash["cond2"] = 1.1112
    args_hash["dens2"] = 50.0
    args_hash["specheat2"] = 0.2
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>5, "Construction"=>1, "InternalMass"=>2, "InternalMassDefinition"=>2}
    expected_values = {"MassSqft"=>94, "LayerThickness"=>0.015875*4+0.0889, "LayerConductivity"=>0.16029*4+0.44257, "LayerDensity"=>801*4+83, "LayerSpecificHeat"=>837.4*4+1211.8, "LayerIndex"=>0+1+2+3+4}
    _test_measure("SFD_2000sqft_2story_SL_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_2_of_1_2in_drywall_and_replace_with_5_8in_drywall_0_5_frac
    args_hash = {}
    args_hash["frac"] = 1.0
    args_hash["thick_in1"] = 0.5
    args_hash["cond1"] = 1.1112
    args_hash["dens1"] = 50.0
    args_hash["specheat1"] = 0.2
    args_hash["thick_in2"] = 0.5
    args_hash["cond2"] = 1.1112
    args_hash["dens2"] = 50.0
    args_hash["specheat2"] = 0.2
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>5, "Construction"=>1, "InternalMass"=>2, "InternalMassDefinition"=>2}
    expected_values = {"MassSqft"=>188, "LayerThickness"=>0.0127*4+0.0889, "LayerConductivity"=>0.16029*4+0.44257, "LayerDensity"=>801*4+83, "LayerSpecificHeat"=>837.4*4+1211.8, "LayerIndex"=>0+1+2+3+4}
    model = _test_measure("SFD_2000sqft_2story_SL_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["frac"] = 0.5
    args_hash["thick_in1"] = 0.625
    args_hash["cond1"] = 1.1112
    args_hash["dens1"] = 50.0
    args_hash["specheat1"] = 0.2
    expected_num_del_objects = {"Material"=>5, "Construction"=>1, "InternalMass"=>2, "InternalMassDefinition"=>2}
    expected_num_new_objects = {"Material"=>3, "Construction"=>1, "InternalMass"=>2, "InternalMassDefinition"=>2}
    expected_values = {"MassSqft"=>94, "LayerThickness"=>0.015875*2+0.0889, "LayerConductivity"=>0.16029*2+0.44257, "LayerDensity"=>801*2+83, "LayerSpecificHeat"=>837.4*2+1211.8, "LayerIndex"=>0+1+2}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_argument_error_layer2_missing_args
    args_hash = {}
    args_hash["frac"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Fraction of Floor Area must be greater than or equal to 0.")
  end

  def test_argument_error_layer2_missing_args
    args_hash = {}
    args_hash["thick_in1"] = 1
    args_hash["cond1"] = 1
    args_hash["dens1"] = 1
    args_hash["specheat1"] = 1
    args_hash["thick_in2"] = 1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Layer 2 does not have all four properties (thickness, conductivity, density, specific heat) entered.")
  end

  def test_argument_error_thick_in1_zero
    args_hash = {}
    args_hash["thick_in1"] = 0
    args_hash["cond1"] = 1
    args_hash["dens1"] = 1
    args_hash["specheat1"] = 1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Thickness 1 must be greater than 0.")
  end

  def test_argument_error_thick_in2_zero
    args_hash = {}
    args_hash["thick_in1"] = 1
    args_hash["cond1"] = 1
    args_hash["dens1"] = 1
    args_hash["specheat1"] = 1
    args_hash["thick_in2"] = 0
    args_hash["cond2"] = 1
    args_hash["dens2"] = 1
    args_hash["specheat2"] = 1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Thickness 2 must be greater than 0.")
  end

  def test_argument_error_cond1_zero
    args_hash = {}
    args_hash["thick_in1"] = 1
    args_hash["cond1"] = 0
    args_hash["dens1"] = 1
    args_hash["specheat1"] = 1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Conductivity 1 must be greater than 0.")
  end

  def test_argument_error_cond2_zero
    args_hash = {}
    args_hash["thick_in1"] = 1
    args_hash["cond1"] = 1
    args_hash["dens1"] = 1
    args_hash["specheat1"] = 1
    args_hash["thick_in2"] = 1
    args_hash["cond2"] = 0
    args_hash["dens2"] = 1
    args_hash["specheat2"] = 1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Conductivity 2 must be greater than 0.")
  end

  def test_argument_error_dens1_zero
    args_hash = {}
    args_hash["thick_in1"] = 1
    args_hash["cond1"] = 1
    args_hash["dens1"] = 0
    args_hash["specheat1"] = 1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Density 1 must be greater than 0.")
  end

  def test_argument_error_dens2_zero
    args_hash = {}
    args_hash["thick_in1"] = 1
    args_hash["cond1"] = 1
    args_hash["dens1"] = 1
    args_hash["specheat1"] = 1
    args_hash["thick_in2"] = 1
    args_hash["cond2"] = 1
    args_hash["dens2"] = 0
    args_hash["specheat2"] = 1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Density 2 must be greater than 0.")
  end

  def test_argument_error_specheat1_zero
    args_hash = {}
    args_hash["thick_in1"] = 1
    args_hash["cond1"] = 1
    args_hash["dens1"] = 1
    args_hash["specheat1"] = 0
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Specific Heat 1 must be greater than 0.")
  end

  def test_argument_error_specheat2_zero
    args_hash = {}
    args_hash["thick_in1"] = 1
    args_hash["cond1"] = 1
    args_hash["dens1"] = 1
    args_hash["specheat1"] = 1
    args_hash["thick_in2"] = 1
    args_hash["cond2"] = 1
    args_hash["dens2"] = 1
    args_hash["specheat2"] = 0
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Specific Heat 2 must be greater than 0.")
  end

  def test_not_applicable_no_geometry
    args_hash = {}
    _test_na(nil, args_hash)
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsWallsPartitionThermalMass.new

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
    measure = ProcessConstructionsWallsPartitionThermalMass.new

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
    measure = ProcessConstructionsWallsPartitionThermalMass.new

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
    
    actual_values = {"MassSqft"=>0, "LayerThickness"=>0, "LayerConductivity"=>0, "LayerDensity"=>0, "LayerSpecificHeat"=>0, "LayerIndex"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "Material"
                new_object = new_object.to_StandardOpaqueMaterial.get
                actual_values["LayerThickness"] += new_object.thickness
                actual_values["LayerConductivity"] += new_object.conductivity
                actual_values["LayerDensity"] += new_object.density
                actual_values["LayerSpecificHeat"] += new_object.specificHeat
            elsif obj_type == "Construction"
                next if !all_new_objects.keys.include?("Material")
                all_new_objects["Material"].each do |new_material|
                    new_material = new_material.to_StandardOpaqueMaterial.get
                    actual_values["LayerIndex"] += new_object.getLayerIndices(new_material)[0]
                end
            elsif obj_type == "InternalMass"
                actual_values["MassSqft"] += new_object.surfaceArea.get
            end
        end
    end
    assert_in_epsilon(expected_values["LayerThickness"], actual_values["LayerThickness"], 0.01)
    assert_in_epsilon(expected_values["LayerConductivity"], actual_values["LayerConductivity"], 0.05)
    assert_in_epsilon(expected_values["LayerDensity"], actual_values["LayerDensity"], 0.01)
    assert_in_epsilon(expected_values["LayerSpecificHeat"], actual_values["LayerSpecificHeat"], 0.01)
    assert_in_epsilon(expected_values["LayerIndex"], actual_values["LayerIndex"], 0.01)
    assert_in_epsilon(expected_values["MassSqft"], actual_values["MassSqft"], 0.02)
    
    return model
  end
  
end
