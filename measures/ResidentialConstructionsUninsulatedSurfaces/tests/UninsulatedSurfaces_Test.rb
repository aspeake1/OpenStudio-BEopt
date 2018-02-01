require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsUninsulatedSurfacesTest < MiniTest::Test

  def test_not_applicable
    args_hash = {}
    _test_na(nil, args_hash)
  end

  def test_slabs_below_unfinished_space
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>5, "Construction"=>4, "FoundationKiva"=>1, "FoundationKivaSettings"=>1, "SurfacePropertyExposedFoundationPerimeter"=>1}
    expected_values = {"SurfacesWithConstructions"=>9}
    _test_measure("SFD_2000sqft_2story_SL_GRG_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end

  def test_roofs_above_unfinished_space
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>7, "Construction"=>6, "FoundationKiva"=>1, "FoundationKivaSettings"=>1, "SurfacePropertyExposedFoundationPerimeter"=>1}
    expected_values = {"SurfacesWithConstructions"=>15}
    _test_measure("SFD_1000sqft_1story_FB_GRG_UA_DoorArea.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end    

  def test_single_family_attached
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>3, "Construction"=>2}
    expected_values = {"LayerRValue"=>0.0889/0.393+0.0127/0.1154577+0.0889/0.442, "LayerDensity"=>83.026+512.590+83.026, "LayerSpecificHeat"=>1211.616+1214.172+1211.616, "LayerIndex"=>0+1, "SurfacesWithConstructions"=>2*num_units+2*(num_units-1)}
    _test_measure("SFA_4units_1story_SL_UA_Offset.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end
  
  def test_multifamily
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>3, "Construction"=>5}
    expected_values = {"LayerRValue"=>0.0889/2.879+0.0889/0.442+0.1397/0.606, "LayerDensity"=>57.456+83.026+67.684, "LayerSpecificHeat"=>1210.259+1211.616+1210.925, "LayerIndex"=>0, "SurfacesWithConstructions"=>2*(num_units-2)+num_units+num_units+4}
    _test_measure("MF_8units_1story_SL_Inset.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsUninsulatedSurfaces.new

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
    measure = ProcessConstructionsUninsulatedSurfaces.new

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
    measure = ProcessConstructionsUninsulatedSurfaces.new

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
    
    actual_values = {"LayerRValue"=>0, "LayerConductivity"=>0, "LayerDensity"=>0, "LayerSpecificHeat"=>0, "LayerIndex"=>0, "SurfacesWithConstructions"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "Material"
                if new_object.to_StandardOpaqueMaterial.is_initialized
                    new_object = new_object.to_StandardOpaqueMaterial.get
                    actual_values["LayerRValue"] += new_object.thickness/new_object.conductivity
                else
                    new_object = new_object.to_MasslessOpaqueMaterial.get
                    actual_values["LayerRValue"] += new_object.thermalResistance
                end
                actual_values["LayerDensity"] += new_object.density
                actual_values["LayerSpecificHeat"] += new_object.specificHeat
            elsif obj_type == "Construction"
                next if !all_new_objects.keys.include?("Material")
                all_new_objects["Material"].each do |new_material|
                    if new_material.to_StandardOpaqueMaterial.is_initialized
                        new_material = new_material.to_StandardOpaqueMaterial.get
                    else
                        new_material = new_material.to_MasslessOpaqueMaterial.get
                    end
                    next if new_object.getLayerIndices(new_material)[0].nil?
                    actual_values["LayerIndex"] += new_object.getLayerIndices(new_material)[0]
                end
                model.getSurfaces.each do |surface|
                  if surface.construction.is_initialized
                    next unless surface.construction.get == new_object
                    actual_values["SurfacesWithConstructions"] += 1
                  end
                end
            end
        end
    end
    
    if not expected_values["LayerRValue"].nil?
        assert_in_epsilon(expected_values["LayerRValue"], actual_values["LayerRValue"], 0.01)
    end
    if not expected_values["LayerDensity"].nil?
        assert_in_epsilon(expected_values["LayerDensity"], actual_values["LayerDensity"], 0.01)
    end
    if not expected_values["LayerSpecificHeat"].nil?
        assert_in_epsilon(expected_values["LayerSpecificHeat"], actual_values["LayerSpecificHeat"], 0.01)
    end
    if not expected_values["LayerIndex"].nil?
        assert_equal(expected_values["LayerIndex"], actual_values["LayerIndex"])
    end
    if not expected_values["SurfacesWithConstructions"].nil?
        assert_equal(expected_values["SurfacesWithConstructions"], actual_values["SurfacesWithConstructions"])
    end
    
    return model
  end
  
end
