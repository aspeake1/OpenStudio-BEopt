require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ZoneMultipliersTest < MiniTest::Test

  def test_zone_mult_front_units_only
    num_finished_spaces = 3
    args_hash = {}
    args_hash["num_units"] = 8
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>3, "Surface"=>30, "ThermalZone"=>4, "Space"=>4, "SpaceType"=>2, "PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2, "ShadingSurfaceGroup"=>2, "ShadingSurface"=>42}
    expected_values = {"FinishedFloorArea"=>900*3, "UnfinishedAtticHeight"=>11.61, "UnfinishedAtticFloorArea"=>900*8, "BuildingHeight"=>8+11.61, "Beds"=>3.0, "Baths"=>2.0, "NumOccupants"=>2*13.56, "EavesDepth"=>2, "NumZonesRepresented"=>8, "NumAdiabaticSurfaces"=>7}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_zone_mult_with_rear_units
    num_finished_spaces = 6
    args_hash = {}
    args_hash["num_units"] = 8
    args_hash["has_rear_units"] = "true"
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>6, "Surface"=>48, "ThermalZone"=>6+1, "Space"=>6+1, "SpaceType"=>2, "PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2, "ShadingSurfaceGroup"=>2, "ShadingSurface"=>46}
    expected_values = {"FinishedFloorArea"=>900*6, "UnfinishedAtticHeight"=>22.21, "UnfinishedAtticFloorArea"=>900*8, "BuildingHeight"=>8+22.21, "Beds"=>3.0, "Baths"=>2.0, "NumOccupants"=>2*13.56, "EavesDepth"=>2, "NumZonesRepresented"=>8, "NumAdiabaticSurfaces"=>6}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_zone_mult_with_two_stories
    num_finished_spaces = 12
    args_hash = {}
    args_hash["num_units"] = 8
    args_hash["num_floors"] = 2
    args_hash["roof_type"] = Constants.RoofTypeHip
    args_hash["unit_aspect_ratio"] = 0.5
    args_hash["has_rear_units"] = "true"
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>6, "Surface"=>84, "ThermalZone"=>6+1, "Space"=>8*2+1-2*2, "SpaceType"=>2, "PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2, "ShadingSurfaceGroup"=>2, "ShadingSurface"=>60}
    expected_values = {"FinishedFloorArea"=>900*6, "UnfinishedAtticHeight"=>8.5, "UnfinishedAtticFloorArea"=>8*450, "BuildingHeight"=>8+8+8.5, "Beds"=>3.0, "Baths"=>2.0, "NumOccupants"=>2*13.56, "EavesDepth"=>2, "NumZonesRepresented"=>8, "NumAdiabaticSurfaces"=>10}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end
  
  
  
  

  def test_zone_mult_front_units_only
    num_finished_spaces = 3
    args_hash = {}
    args_hash["num_units"] = 8
    args_hash["corridor_width"] = 0
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>3, "Surface"=>18, "ThermalZone"=>3, "Space"=>3, "SpaceType"=>1, "PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2, "ShadingSurfaceGroup"=>2, "ShadingSurface"=>52}
    expected_values = {"FinishedFloorArea"=>900*3, "BuildingHeight"=>8, "Beds"=>3.0, "Baths"=>2.0, "NumOccupants"=>2*13.56, "EavesDepth"=>2, "NumZonesRepresented"=>8, "NumAdiabaticSurfaces"=>2}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_zone_mult_with_rear_units_even
    num_finished_spaces = 6
    args_hash = {}
    args_hash["num_units"] = 8
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>6, "Surface"=>48, "ThermalZone"=>6+1, "Space"=>6+1, "SpaceType"=>2, "PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2, "ShadingSurfaceGroup"=>2, "ShadingSurface"=>102}
    expected_values = {"FinishedFloorArea"=>900*6, "BuildingHeight"=>8, "Beds"=>3.0, "Baths"=>2.0, "NumOccupants"=>2*13.56, "EavesDepth"=>2, "NumZonesRepresented"=>8, "NumAdiabaticSurfaces"=>18}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_zone_mult_with_rear_units_odd
    num_finished_spaces = 6
    args_hash = {}
    args_hash["num_units"] = 9
    args_hash["corridor_position"] = "Double Exterior"
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>6, "Surface"=>36, "ThermalZone"=>6, "Space"=>6, "ShadingSurface"=>84, "ShadingSurfaceGroup"=>4, "SpaceType"=>1, "PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2}
    expected_values = {"FinishedFloorArea"=>900*6, "BuildingHeight"=>8, "Beds"=>3.0, "Baths"=>2.0, "NumOccupants"=>2*13.56, "EavesDepth"=>2, "NumZonesRepresented"=>8, "NumAdiabaticSurfaces"=>5}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_zone_mult_many_floors
    num_finished_spaces = 18
    args_hash = {}
    args_hash["num_floors"] = 12
    args_hash["num_units"] = 12*8
    args_hash["use_zone_mult"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BuildingUnit"=>18, "Surface"=>252, "ThermalZone"=>19, "Space"=>30, "SpaceType"=>2, "PeopleDefinition"=>num_finished_spaces, "People"=>num_finished_spaces, "ScheduleRuleset"=>2, "ShadingSurfaceGroup"=>2, "ShadingSurface"=>406}
    expected_values = {"FinishedFloorArea"=>900*18, "BuildingHeight"=>12*8, "Beds"=>3.0, "Baths"=>2.0, "NumOccupants"=>24*13.56, "EavesDepth"=>2, "NumZonesRepresented"=>12*8, "NumAdiabaticSurfaces"=>160}
    _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
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
    obj_type_exclusions = ["PortList", "Node", "ZoneEquipmentList", "SizingZone", "ZoneHVACEquipmentList", "Building", "ScheduleRule", "ScheduleDay", "ScheduleTypeLimits", "YearDescription"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)

    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    actual_values = {"FinishedFloorArea"=>0, "FinishedBasementFloorArea"=>0, "UnfinishedBasementFloorArea"=>0,  "CrawlspaceFloorArea"=>0, "UnfinishedAtticFloorArea"=>0, "FinishedAtticFloorArea"=>0, "FinishedBasementHeight"=>0, "UnfinishedBasementHeight"=>0, "CrawlspaceHeight"=>0, "UnfinishedAtticHeight"=>0, "FinishedAtticHeight"=>0, "BuildingHeight"=>0, "NumOccupants"=>0, "NumZonesRepresented"=>0, "NumAdiabaticSurfaces"=>0}
    new_spaces = []
    new_zones = []
    all_new_objects.each do |obj_type, new_objects|
      new_objects.each do |new_object|
        next if not new_object.respond_to?("to_#{obj_type}")
        new_object = new_object.public_send("to_#{obj_type}").get
        if obj_type == "Space"
          if new_object.name.to_s.start_with?("finished basement")
            actual_values["FinishedBasementHeight"] = Geometry.get_height_of_spaces([new_object])
            actual_values["FinishedBasementFloorArea"] += UnitConversions.convert(new_object.floorArea,"m^2","ft^2")
          elsif new_object.name.to_s.start_with?("unfinished basement")
            actual_values["UnfinishedBasementHeight"] = Geometry.get_height_of_spaces([new_object])
            actual_values["UnfinishedBasementFloorArea"] += UnitConversions.convert(new_object.floorArea,"m^2","ft^2")
          elsif new_object.name.to_s.start_with?("crawlspace")
            actual_values["CrawlspaceHeight"] = Geometry.get_height_of_spaces([new_object])
            actual_values["CrawlspaceFloorArea"] += UnitConversions.convert(new_object.floorArea,"m^2","ft^2")
          elsif new_object.name.to_s.start_with?("unfinished attic")
            actual_values["UnfinishedAtticHeight"] = Geometry.get_height_of_spaces([new_object])
            actual_values["UnfinishedAtticFloorArea"] += UnitConversions.convert(new_object.floorArea,"m^2","ft^2")
          elsif new_object.name.to_s.start_with?("finished attic")
            actual_values["FinishedAtticHeight"] = Geometry.get_height_of_spaces([new_object])
            actual_values["FinishedAtticFloorArea"] += UnitConversions.convert(new_object.floorArea,"m^2","ft^2")
          end
          if Geometry.space_is_finished(new_object)
            actual_values["FinishedFloorArea"] += UnitConversions.convert(new_object.floorArea,"m^2","ft^2")
          end
          new_spaces << new_object
        elsif obj_type == "People"
          actual_values["NumOccupants"] += new_object.peopleDefinition.numberofPeople.get
        elsif obj_type == "ShadingSurface"
          next unless new_object.name.to_s.include? Constants.ObjectNameEaves
          l, w, h = Geometry.get_surface_dimensions(new_object)
          actual_values["EavesDepth"] = [UnitConversions.convert(l,"m","ft"), UnitConversions.convert(w,"m","ft")].min
          assert_in_epsilon(expected_values["EavesDepth"], actual_values["EavesDepth"], 0.01)
        elsif obj_type == "BuildingUnit"
          spaces = new_object.spaces
          spaces.each do |space|
            thermal_zone = space.thermalZone.get
            unless new_zones.include? thermal_zone
              new_zones << thermal_zone
            end
          end
        elsif obj_type == "Surface"
          if new_object.outsideBoundaryCondition.downcase == "adiabatic"
            actual_values["NumAdiabaticSurfaces"] += 1
          end
        end
      end
    end
    if new_spaces.any? {|new_space| new_space.name.to_s.start_with?("finished basement")}
      assert_in_epsilon(expected_values["FinishedBasementHeight"], actual_values["FinishedBasementHeight"], 0.01)
      assert_in_epsilon(expected_values["FinishedBasementFloorArea"], actual_values["FinishedBasementFloorArea"], 0.01)
    end
    if new_spaces.any? {|new_space| new_space.name.to_s.start_with?("unfinished basement")}
      assert_in_epsilon(expected_values["UnfinishedBasementHeight"], actual_values["UnfinishedBasementHeight"], 0.01)
      assert_in_epsilon(expected_values["UnfinishedBasementFloorArea"], actual_values["UnfinishedBasementFloorArea"], 0.01)
    end
    if new_spaces.any? {|new_space| new_space.name.to_s.start_with?("crawlspace")}
      assert_in_epsilon(expected_values["CrawlspaceHeight"], actual_values["CrawlspaceHeight"], 0.01)
      assert_in_epsilon(expected_values["CrawlspaceFloorArea"], actual_values["CrawlspaceFloorArea"], 0.01)
    end
    if new_spaces.any? {|new_space| new_space.name.to_s.start_with?("unfinished attic")}
      assert_in_epsilon(expected_values["UnfinishedAtticHeight"], actual_values["UnfinishedAtticHeight"], 0.01)
      assert_in_epsilon(expected_values["UnfinishedAtticFloorArea"], actual_values["UnfinishedAtticFloorArea"], 0.01)
    end
    if new_spaces.any? {|new_space| new_space.name.to_s.start_with?("finished attic")}
      assert_in_epsilon(expected_values["FinishedAtticHeight"], actual_values["FinishedAtticHeight"], 0.01)
      assert_in_epsilon(expected_values["FinishedAtticFloorArea"], actual_values["FinishedAtticFloorArea"], 0.01)
    end
    assert_in_epsilon(expected_values["FinishedFloorArea"], actual_values["FinishedFloorArea"], 0.01)
    assert_in_epsilon(expected_values["BuildingHeight"], Geometry.get_height_of_spaces(new_spaces), 0.01)
    assert_in_epsilon(expected_values["NumOccupants"], actual_values["NumOccupants"], 0.01)
    new_zones.each do |new_zone|
      actual_values["NumZonesRepresented"] += new_zone.multiplier
    end

    # Ensure no surfaces adjacent to "ground" (should be Kiva "foundation")
    model.getSurfaces.each do |surface|
      refute_equal(surface.outsideBoundaryCondition.downcase, "ground")
    end

    Geometry.get_building_units(model, runner).each do |unit|
      nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
      assert_equal(expected_values["Beds"], nbeds)
      assert_equal(expected_values["Baths"], nbaths)
    end
    
    assert_equal(expected_values["NumZonesRepresented"], actual_values["NumZonesRepresented"])
    assert_equal(expected_values["NumAdiabaticSurfaces"], actual_values["NumAdiabaticSurfaces"])

    return model
  end

end
