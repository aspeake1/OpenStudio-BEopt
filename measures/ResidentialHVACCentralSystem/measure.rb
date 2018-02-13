# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"


# start the measure
class ProcessCentralSystem < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "ResidentialHVACCentralSystem"
  end

  # human readable description
  def description
    return "Description"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Modeler Description"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Make argument for system type
    hvac_chs = OpenStudio::StringVector.new # FIXME: some of these would never be found in a residential building?
    hvac_chs << "Inferred"
    hvac_chs << "PTAC"
    hvac_chs << "PTHP"
    hvac_chs << "PSZ-AC"
    hvac_chs << "PSZ-HP"
    hvac_chs << "PSZ_VAV"
    hvac_chs << "Fan Coil"
    hvac_chs << "Baseboards"
    hvac_chs << "Window AC"
    hvac_chs << "Unit Heaters"
    hvac_chs << "VAV Reheat"
    hvac_chs << "VAV No Reheat"
    hvac_chs << "VAV Gas Reheat"
    hvac_chs << "VAV PFP Boxes"
    hvac_chs << "PVAV Reheat"
    hvac_chs << "PVAV PFP Boxes"
    hvac_chs << "Water Source Heat Pumps"
    hvac_chs << "Ground Source Heat Pumps"
    hvac_chs << "DOAS"
    hvac_chs << "Evaporative Cooler"
    hvac_chs << "Ideal Air Loads"
    hvac_chs << "Water Source Heat Pumps with ERVs"
    hvac_chs << "Water Source Heat Pumps with DOAS"
    hvac_chs << "Ground Source Heat Pumps with ERVs"
    hvac_chs << "Ground Source Heat Pumps with DOAS"
    hvac_chs << "Fan Coil with ERVs"
    hvac_chs << "Fan Coil with DOAS"
    hvac_chs << "Residential Air Source Heat Pump"
    hvac_chs << "Residential Forced Air Furnace"
    hvac_chs << "Residential AC"
    system_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("system_type", hvac_chs,true)
    system_type.setDisplayName("HVAC System Type")
    system_type.setDefaultValue("Inferred")
    args << system_type

    # Make argument for HVAC delivery type
    hvac_type_chs = OpenStudio::StringVector.new
    hvac_type_chs << "air"
    hvac_type_chs << "hydronic"
    delivery_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("delivery_type", hvac_type_chs,true)
    delivery_type.setDisplayName("HVAC System Delivery Type")
    delivery_type.setDescription("How the HVAC system delivers heating or cooling to the zone.")
    delivery_type.setDefaultValue("air")
    args << delivery_type

    # Make argument for HVAC heating source
    htg_src_chs = OpenStudio::StringVector.new
    htg_src_chs << "Electricity"
    htg_src_chs << "NaturalGas"
    htg_src_chs << "DistrictHeating"
    htg_src_chs << "DistrictAmbient"
    htg_src = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("htg_src", htg_src_chs,true)
    htg_src.setDisplayName("HVAC Heating Source")
    htg_src.setDescription("The primary source of heating used by HVAC systems in the model.")
    htg_src.setDefaultValue("NaturalGas")
    args << htg_src

    # Make argument for HVAC cooling source
    clg_src_chs = OpenStudio::StringVector.new
    clg_src_chs << "Electricity"
    clg_src_chs << "DistrictCooling"
    clg_src_chs << "DistrictAmbient"
    clg_src = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("clg_src", clg_src_chs,true)
    clg_src.setDisplayName("HVAC Cooling Source")
    clg_src.setDescription("The primary source of cooling used by HVAC systems in the model.")
    clg_src.setDefaultValue("Electricity")
    args << clg_src

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    require 'openstudio-standards'

    system_type = runner.getStringArgumentValue("system_type", user_arguments)

    std = Standard.build("90.1-2013")

    if system_type == "Inferred"
      climate_zone_and_building_type = std.model_get_building_climate_zone_and_building_type(model)
      climate_zone = climate_zone_and_building_type["climate_zone"]
      area_type = "residential"
      delivery_type = runner.getStringArgumentValue("delivery_type", user_arguments)
      heating_source = runner.getStringArgumentValue("htg_src", user_arguments)
      cooling_source = runner.getStringArgumentValue("clg_src", user_arguments)
      area_m2 = UnitConversions.convert(Geometry.get_floor_area_from_spaces(model.getSpaces), "ft^2", "m^2")
      num_stories = Geometry.get_above_grade_building_stories(model.getSpaces)
      system_type, central_htg_fuel, zone_htg_fuel, clg_fuel = std.model_typical_hvac_system_type(model, climate_zone, area_type, delivery_type, heating_source, cooling_source, area_m2, num_stories)
    else
      central_htg_fuel = runner.getStringArgumentValue("htg_src", user_arguments)
      zone_htg_fuel = runner.getStringArgumentValue("htg_src", user_arguments)
      clg_fuel = runner.getStringArgumentValue("clg_src", user_arguments)
    end

    # story_groups = std.model_group_zones_by_story(model, model.getThermalZones) # TODO: need to write our own "zones by stories" method since we don't use BuildingStory
    thermal_zones = []
    model.getThermalZones.each do |thermal_zone|
      next unless Geometry.zone_is_of_type(thermal_zone, Constants.SpaceTypeLiving) or Geometry.zone_is_of_type(thermal_zone, Constants.SpaceTypeFinishedBasement)
      thermal_zones << thermal_zone
    end
    story_groups = [thermal_zones]
    story_groups.each do |zones|
      std.model_add_hvac_system(model, system_type, central_htg_fuel, zone_htg_fuel, clg_fuel, zones)
      runner.registerInfo("Added '#{system_type}' to the building.")
    end

    return true

  end

end

# register the measure to be used by the application
ProcessCentralSystem.new.registerWithApplication
