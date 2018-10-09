require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsSlabTest < MiniTest::Test

  def test_uninsulated
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>3, "Construction"=>2, "FoundationKiva"=>1, "FoundationKivaSettings"=>1, "SurfacePropertyExposedFoundationPerimeter"=>1, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"SumRValues"=>0.077+0.293, "SumWidths"=>0, "SumDepths"=>0, "ExposedPerimeter"=>134.165, "WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Carpet.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Carpet.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Carpet.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Carpet.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Carpet.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.coatingLayerWaterVaporDiffusionResistanceFactor}
    _test_measure("SFD_2000sqft_2story_SL_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_2ft_r5_perimeter_r5_gap
    args_hash = {}
    args_hash["perimeter_r"] = 5
    args_hash["perimeter_width"] = 2
    args_hash["gap_r"] = 5
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>5, "Construction"=>2, "FoundationKiva"=>1, "FoundationKivaSettings"=>1, "SurfacePropertyExposedFoundationPerimeter"=>1, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"SumRValues"=>0.077+0.88+0.88+0.293, "SumWidths"=>0.609, "SumDepths"=>0.1016, "ExposedPerimeter"=>134.167, "WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Carpet.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Carpet.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Carpet.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Carpet.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Carpet.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.coatingLayerWaterVaporDiffusionResistanceFactor}
    _test_measure("SFD_2000sqft_2story_SL_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_4ft_r15_exterior
    args_hash = {}
    args_hash["exterior_depth"] = 4
    args_hash["exterior_r"] = 15
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>4, "Construction"=>2, "FoundationKiva"=>1, "FoundationKivaSettings"=>1, "SurfacePropertyExposedFoundationPerimeter"=>1, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"SumRValues"=>0.077+2.64+0.293, "SumWidths"=>0, "SumDepths"=>1.2192, "ExposedPerimeter"=>134.167, "WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Carpet.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Carpet.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Carpet.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Carpet.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Carpet.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.coatingLayerWaterVaporDiffusionResistanceFactor}
    _test_measure("SFD_2000sqft_2story_SL_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_whole_slab_r20_r10_gap
    args_hash = {}
    args_hash["whole_r"] = 20
    args_hash["gap_r"] = 10
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>5, "Construction"=>2, "FoundationKiva"=>1, "FoundationKivaSettings"=>1, "SurfacePropertyExposedFoundationPerimeter"=>1, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"SumRValues"=>0.077+1.76+3.52+0.293, "SumWidths"=>0, "SumDepths"=>0.1016, "ExposedPerimeter"=>134.167, "WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Carpet.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Carpet.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Carpet.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Carpet.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Carpet.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.coatingLayerWaterVaporDiffusionResistanceFactor}
    _test_measure("SFD_2000sqft_2story_SL_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_exposed_perimeter_with_garage
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>4, "Construction"=>4, "FoundationKiva"=>2, "FoundationKivaSettings"=>1, "SurfacePropertyExposedFoundationPerimeter"=>2, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"ExposedPerimeter"=>104, "WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Carpet.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Carpet.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Carpet.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Carpet.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Carpet.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.coatingLayerWaterVaporDiffusionResistanceFactor}
    _test_measure("SFD_2000sqft_2story_SL_GRG_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_exposed_perimeter_with_door
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>4, "Construction"=>4, "FoundationKiva"=>2, "FoundationKivaSettings"=>1, "SurfacePropertyExposedFoundationPerimeter"=>2, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"ExposedPerimeter"=>104.167, "WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Carpet.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Carpet.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Carpet.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Carpet.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Carpet.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.coatingLayerWaterVaporDiffusionResistanceFactor}
    _test_measure("SFD_2000sqft_2story_SL_GRG_UA_Windows_Doors.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>6, "Construction"=>8, "FoundationKiva"=>num_units, "FoundationKivaSettings"=>1, "SurfacePropertyExposedFoundationPerimeter"=>num_units, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"ExposedPerimeter"=>254.558, "WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Carpet.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Carpet.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Carpet.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Carpet.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Carpet.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.coatingLayerWaterVaporDiffusionResistanceFactor}
    _test_measure("SFA_4units_1story_SL_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_multifamily_new_construction
    num_units = 8+1
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>11, "Construction"=>18, "FoundationKiva"=>num_units, "FoundationKivaSettings"=>1, "SurfacePropertyExposedFoundationPerimeter"=>num_units, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"ExposedPerimeter"=>339.411, "WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Carpet.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Carpet.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Carpet.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Carpet.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Carpet.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Carpet.coatingLayerWaterVaporDiffusionResistanceFactor}
    _test_measure("MF_8units_1story_SL_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_argument_error_perimeter_r_negative
    args_hash = {}
    args_hash["perimeter_r"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Perimeter Insulation Nominal R-value must be greater than or equal to 0.")
  end
    
  def test_argument_error_perimeter_width_negative
    args_hash = {}
    args_hash["perimeter_width"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Perimeter Insulation Width must be greater than or equal to 0.")
  end

  def test_argument_error_whole_r_negative
    args_hash = {}
    args_hash["whole_r"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Whole Slab Insulation Nominal R-value must be greater than or equal to 0.")
  end

  def test_argument_error_gap_r_negative
    args_hash = {}
    args_hash["gap_r"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Gap Insulation Nominal R-value must be greater than or equal to 0.")
  end

  def test_argument_error_exterior_r_negative
    args_hash = {}
    args_hash["exterior_r"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Exterior Insulation Nominal R-value must be greater than or equal to 0.")
  end

  def test_argument_error_exterior_depth_negative
    args_hash = {}
    args_hash["exterior_depth"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Exterior Insulation Depth must be greater than or equal to 0.")
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsSlab.new

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

    # show the output
    #show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    # create an instance of the measure
    measure = ProcessConstructionsSlab.new

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
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    actual_values = {"SumRValues"=>0, "SumWidths"=>0, "SumDepths"=>0, "ExposedPerimeter"=>0, "WaterVaporDiffusionResistanceFactor"=>0, "MoistureEquationCoefficientA"=>0, "MoistureEquationCoefficientB"=>0, "MoistureEquationCoefficientC"=>0, "MoistureEquationCoefficientD"=>0, "CoatingLayerThickness"=>0, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "FoundationKiva"
                if new_object.interiorHorizontalInsulationMaterial.is_initialized
                    mat = new_object.interiorHorizontalInsulationMaterial.get.to_StandardOpaqueMaterial.get
                    actual_values["SumRValues"] += mat.thickness/mat.conductivity
                end
                if new_object.interiorVerticalInsulationMaterial.is_initialized
                    mat = new_object.interiorVerticalInsulationMaterial.get.to_StandardOpaqueMaterial.get
                    actual_values["SumRValues"] += mat.thickness/mat.conductivity
                end
                if new_object.exteriorVerticalInsulationMaterial.is_initialized
                    mat = new_object.exteriorVerticalInsulationMaterial.get.to_StandardOpaqueMaterial.get
                    actual_values["SumRValues"] += mat.thickness/mat.conductivity
                end
                if new_object.interiorHorizontalInsulationWidth.is_initialized
                    actual_values["SumWidths"] += new_object.interiorHorizontalInsulationWidth.get
                end
                if new_object.interiorVerticalInsulationDepth.is_initialized
                    actual_values["SumDepths"] += new_object.interiorVerticalInsulationDepth.get
                end
                if new_object.exteriorVerticalInsulationDepth.is_initialized
                    actual_values["SumDepths"] += new_object.exteriorVerticalInsulationDepth.get
                end
            elsif obj_type == "Construction"
                if new_object.name.to_s.start_with? Constants.SurfaceTypeFloorFndGrndFinSlab
                    new_object.to_LayeredConstruction.get.layers.each do |layer|
                        mat = layer.to_StandardOpaqueMaterial.get
                        actual_values["SumRValues"] +=  mat.thickness/mat.conductivity
                    end
                    model.getSurfaces.each do |surface|
                        next if not surface.construction.is_initialized
                        next if surface.construction.get.name.to_s != new_object.name.to_s
                        next if not surface.surfacePropertyExposedFoundationPerimeter.is_initialized
                        actual_values["ExposedPerimeter"] += UnitConversions.convert(surface.surfacePropertyExposedFoundationPerimeter.get.totalExposedPerimeter.get,"m","ft")
                    end
                end
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
    actual_values.each do |prop, val|
      next if expected_values[prop].nil?
      assert_in_epsilon(expected_values[prop], actual_values[prop], 0.01)  
    end
    
    return model
  end
  
end
