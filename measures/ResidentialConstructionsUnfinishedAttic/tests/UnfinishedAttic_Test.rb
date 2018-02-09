require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsUnfinishedAtticTest < MiniTest::Test

  def test_roof_insulated_and_insulate
    args_hash = {}
    args_hash["ceiling_r"] = 0
    args_hash["ceiling_ins_thick_in"] = 0
    args_hash["roof_cavity_r"] = 19
    args_hash["roof_cavity_ins_thick_in"] = 6.25
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>5, "Construction"=>3}
    expected_values = {"CeilingAssemblyR"=>0, "RoofAssemblyR"=>0}
    model = _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)   
    # Insulate
    expected_num_new_objects = {"Material"=>5, "Construction"=>3}
    expected_num_del_objects = {"Material"=>5, "Construction"=>3}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)   
  end
  
  def test_ceiling_ins_thk_less_than_joist_ht
    args_hash = {}
    args_hash["ceiling_r"] = 7
    args_hash["ceiling_ins_thick_in"] = 2.95
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>5, "Construction"=>3}
    expected_values = {"CeilingAssemblyR"=>0, "RoofAssemblyR"=>0}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end  
  
  def test_roof_ins_thk_more_than_roof_framing_thk
    args_hash = {}
    args_hash["ceiling_r"] = 0
    args_hash["ceiling_ins_thick_in"] = 0
    args_hash["roof_cavity_r"] = 30
    args_hash["roof_cavity_ins_thick_in"] = 9.5
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>5, "Construction"=>3}
    expected_values = {"CeilingAssemblyR"=>0, "RoofAssemblyR"=>0}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)   
  end  
  
  def test_roof_ins_thk_more_than_roof_framing_thk_etc
    args_hash = {}
    args_hash["ceiling_r"] = 0
    args_hash["ceiling_ins_thick_in"] = 0
    args_hash["roof_cavity_r"] = 30
    args_hash["roof_cavity_ins_thick_in"] = 9.5
    args_hash["ceiling_drywall_thick_in"] = 1.0
    args_hash["roof_osb_thick_in"] = 0
    args_hash["roof_rigid_r"] = 10
    args_hash["roof_rigid_thick_in"] = 2
    args_hash["roofing_material"] = Material.RoofingMetalWhite.name
    args_hash["has_radiant_barrier"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>6, "Construction"=>3}
    expected_values = {"CeilingAssemblyR"=>0, "RoofAssemblyR"=>0}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)   
  end  
  
  def test_argument_error_ceiling_cavity_r_negative
    args_hash = {}
    args_hash["ceiling_r"] = -1
    result = _test_error("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Insulation Nominal R-value must be greater than or equal to 0.")
  end
  
  def test_argument_error_ceiling_cavity_in_thk_negative
    args_hash = {}
    args_hash["ceiling_ins_thick_in"] = -1
    result = _test_error("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Insulation Thickness must be greater than or equal to 0.")
  end
  
  def test_argument_error_ceiling_framing_factor_negative
    args_hash = {}
    args_hash["ceiling_framing_factor"] = -1
    result = _test_error("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Framing Factor must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_ceiling_framing_factor_eq_1
    args_hash = {}
    args_hash["ceiling_framing_factor"] = 1.0
    result = _test_error("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Framing Factor must be greater than or equal to 0 and less than 1.")
  end
  
  def test_argument_error_ceiling_joist_ht_negative
    args_hash = {}
    args_hash["ceiling_joist_height_in"] = -1
    result = _test_error("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Joist Height must be greater than 0.")
  end
  
  def test_argument_error_roof_cavity_r_negative
    args_hash = {}
    args_hash["roof_cavity_r"] = -1
    result = _test_error("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Roof Cavity Insulation Nominal R-value must be greater than or equal to 0.")
  end
  
  def test_argument_error_roof_cavity_in_thk_negative
    args_hash = {}
    args_hash["roof_cavity_ins_thick_in"] = -1
    result = _test_error("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Roof Cavity Insulation Thickness must be greater than or equal to 0.")
  end
  
  def test_argument_error_roof_framing_factor_negative
    args_hash = {}
    args_hash["roof_framing_factor"] = -1
    result = _test_error("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Roof Framing Factor must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_roof_framing_factor_eq_1
    args_hash = {}
    args_hash["roof_framing_factor"] = 1.0
    result = _test_error("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Roof Framing Factor must be greater than or equal to 0 and less than 1.")
  end
  
  def test_argument_error_roof_joist_ht_negative
    args_hash = {}
    args_hash["roof_framing_thick_in"] = -1
    result = _test_error("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Roof Framing Thickness must be greater than 0.")
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsUnfinishedAttic.new

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    # create an instance of the measure
    measure = ProcessConstructionsUnfinishedAttic.new

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
    
    actual_values = {"CeilingAssemblyR"=>0, "FloorAssemblyR"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "Construction"
                if new_object.name.to_s.start_with? Constants.SurfaceTypeRoofUnfinInsExt
                    new_object.to_LayeredConstruction.get.layers.each do |layer|
                        material = layer.to_StandardOpaqueMaterial.get
                        actual_values["CeilingAssemblyR"] += material.thickness/material.conductivity
                    end
                elsif new_object.name.to_s.start_with? Constants.SurfaceTypeFloorFinInsUnfin
                    new_object.to_LayeredConstruction.get.layers.each do |layer|
                        material = layer.to_StandardOpaqueMaterial.get
                        actual_values["FloorAssemblyR"] += material.thickness/material.conductivity
                    end
                end
            end
        end
    end
    assert_in_epsilon(expected_values["CeilingAssemblyR"], actual_values["CeilingAssemblyR"], 0.01)
    assert_in_epsilon(expected_values["FloorAssemblyR"], actual_values["FloorAssemblyR"], 0.01)
    
    return model
  end
  
end
