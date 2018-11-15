# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require_relative "../HPXMLtoOpenStudio/resources/unit_conversions"
require_relative "../HPXMLtoOpenStudio/resources/geometry"
require_relative "../HPXMLtoOpenStudio/resources/util"
require_relative "../HPXMLtoOpenStudio/resources/hvac"

# start the measure
class ProcessCentralSystemBoilerBaseboards < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "ResidentialHVACCentralSystemBoilerBaseboards"
  end

  # human readable description
  def description
    return "Adds a central hot water (or steam) boiler to the model. Also adds baseboards to each finished zone."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Adds a hot water (or steam) boiler with variable-speed pump to a single plant loop. Also adds zone hvac convective water objects with coil heating water baseboard objects to the demand side of the plant loop."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a string argument for central boiler system type
    central_boiler_system_type_names = OpenStudio::StringVector.new
    central_boiler_system_type_names << Constants.BoilerTypeForcedDraft
    central_boiler_system_type_names << Constants.BoilerTypeSteam
    central_boiler_system_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("central_boiler_system_type", central_boiler_system_type_names, true)
    central_boiler_system_type.setDisplayName("Central Boiler System Type")
    central_boiler_system_type.setDescription("The system type of the central boiler.")
    central_boiler_system_type.setDefaultValue(Constants.BoilerTypeForcedDraft)
    args << central_boiler_system_type

    # make a string argument for central boiler fuel type
    central_boiler_fuel_type_names = OpenStudio::StringVector.new
    central_boiler_fuel_type_names << Constants.FuelTypeElectric
    central_boiler_fuel_type_names << Constants.FuelTypeGas
    central_boiler_fuel_type_names << Constants.FuelTypeOil
    central_boiler_fuel_type_names << Constants.FuelTypePropane
    central_boiler_fuel_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("central_boiler_fuel_type", central_boiler_fuel_type_names, true)
    central_boiler_fuel_type.setDisplayName("Central Boiler Fuel Type")
    central_boiler_fuel_type.setDescription("The fuel type of the central boiler used for heating.")
    central_boiler_fuel_type.setDefaultValue(Constants.FuelTypeGas)
    args << central_boiler_fuel_type

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    require "openstudio-standards"

    central_boiler_system_type = runner.getStringArgumentValue("central_boiler_system_type", user_arguments)
    central_boiler_fuel_type = HelperMethods.eplus_fuel_map(runner.getStringArgumentValue("central_boiler_fuel_type", user_arguments))

    std = Standard.build("90.1-2013")

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    hot_water_loop = nil
    units.each do |unit|
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      HVAC.get_control_and_slave_zones(thermal_zones).each do |control_zone, slave_zones|
        ([control_zone] + slave_zones).each do |zone|
          HVAC.remove_hvac_equipment(model, runner, zone, unit,
                                     Constants.ObjectNameCentralSystemBoilerBaseboards)
        end
      end

      if hot_water_loop.nil?
        hot_water_loop = std.model_get_or_add_hot_water_loop(model, central_boiler_fuel_type)
        runner.registerInfo("Added '#{hot_water_loop.name}' to model.")
      end

      success = HVAC.apply_central_system_boiler_baseboards(model, unit, runner, std, hot_water_loop)

      return false if not success
    end # unit

    if central_boiler_system_type == Constants.BoilerTypeSteam
      plant_loop = model.getPlantLoopByName("Hot Water Loop").get
      plant_loop.supplyComponents.each do |supply_component|
        next unless supply_component.to_PumpVariableSpeed.is_initialized

        pump = supply_component.to_PumpVariableSpeed.get
        # TODO: how to zero out the pumping energy?
      end
    end

    simulation_control = model.getSimulationControl
    simulation_control.setRunSimulationforSizingPeriods(true) # indicate e+ autosizing

    return true
  end
end

# register the measure to be used by the application
ProcessCentralSystemBoilerBaseboards.new.registerWithApplication
