# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/hvac"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

# start the measure
class ResidentialPhotovoltaics < OpenStudio::Measure::ModelMeasure

  class PVSystem
    def initialize
    end
    attr_accessor(:size, :module_type, :inv_eff, :losses)
  end

  class PVAzimuth
    def initialize
    end
    attr_accessor(:abs)
  end

  class PVTilt
    def initialize
    end
    attr_accessor(:abs)
  end

  # human readable name
  def name
    return "Set Residential Photovoltaics"
  end

  # human readable description
  def description
    return "Adds (or replaces) residential photovoltaics with the specified efficiency, size, orientation, and tilt. For both single-family detached and multifamily buildings, one array is added (or replaced).#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Any generators, inverters, or electric load center distribution objects are removed. An electric load center distribution object is created, along with pvwatts generator and inverter objects. The generator is added to the electric load center distribution object and the inverter is set."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for size
    size = OpenStudio::Measure::OSArgument::makeDoubleArgument("size", false)
    size.setDisplayName("Size")
    size.setUnits("kW")
    size.setDescription("Size (power) per unit of the photovoltaic array in kW DC.")
    size.setDefaultValue(2.5)
    args << size

    #make a choice arguments for module type
    module_types_names = OpenStudio::StringVector.new
    module_types_names << Constants.PVModuleTypeStandard
    module_types_names << Constants.PVModuleTypePremium
    module_types_names << Constants.PVModuleTypeThinFilm
    module_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("module_type", module_types_names, true)
    module_type.setDisplayName("Module Type")
    module_type.setDescription("Type of module to use for the PV simulation.")
    module_type.setDefaultValue(Constants.PVModuleTypeStandard)
    args << module_type

    #make a double argument for system losses
    system_losses = OpenStudio::Measure::OSArgument::makeDoubleArgument("system_losses", false)
    system_losses.setDisplayName("System Losses")
    system_losses.setUnits("frac")
    system_losses.setDescription("Difference between theoretical module-level and actual PV system performance due to wiring resistance losses, dust, module mismatch, etc.")
    system_losses.setDefaultValue(0.14)
    args << system_losses

    #make a double argument for inverter efficiency
    inverter_efficiency = OpenStudio::Measure::OSArgument::makeDoubleArgument("inverter_efficiency", false)
    inverter_efficiency.setDisplayName("Inverter Efficiency")
    inverter_efficiency.setUnits("frac")
    inverter_efficiency.setDescription("The efficiency of the inverter.")
    inverter_efficiency.setDefaultValue(0.96)
    args << inverter_efficiency

    #make a choice arguments for azimuth type
    azimuth_types_names = OpenStudio::StringVector.new
    azimuth_types_names << Constants.CoordRelative
    azimuth_types_names << Constants.CoordAbsolute
    azimuth_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("azimuth_type", azimuth_types_names, true)
    azimuth_type.setDisplayName("Azimuth Type")
    azimuth_type.setDescription("Relative azimuth angle is measured clockwise from the front of the house. Absolute azimuth angle is measured clockwise from due south.")
    azimuth_type.setDefaultValue(Constants.CoordRelative)
    args << azimuth_type

    #make a double argument for azimuth
    azimuth = OpenStudio::Measure::OSArgument::makeDoubleArgument("azimuth", false)
    azimuth.setDisplayName("Azimuth")
    azimuth.setUnits("degrees")
    azimuth.setDescription("The azimuth angle is measured clockwise, based on the azimuth type specified.")
    azimuth.setDefaultValue(180.0)
    args << azimuth

    #make a choice arguments for tilt type
    tilt_types_names = OpenStudio::StringVector.new
    tilt_types_names << Constants.TiltPitch
    tilt_types_names << Constants.CoordAbsolute
    tilt_types_names << Constants.TiltLatitude
    tilt_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("tilt_type", tilt_types_names, true)
    tilt_type.setDisplayName("Tilt Type")
    tilt_type.setDescription("Type of tilt angle referenced.")
    tilt_type.setDefaultValue(Constants.TiltPitch)
    args << tilt_type

    #make a double argument for tilt
    tilt = OpenStudio::Measure::OSArgument::makeDoubleArgument("tilt", false)
    tilt.setDisplayName("Tilt")
    tilt.setUnits("degrees")
    tilt.setDescription("Angle of the tilt.")
    tilt.setDefaultValue(0)
    args << tilt

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    size = runner.getDoubleArgumentValue("size",user_arguments)
    module_type = runner.getStringArgumentValue("module_type",user_arguments)
    system_losses = runner.getDoubleArgumentValue("system_losses",user_arguments)
    inverter_efficiency = runner.getDoubleArgumentValue("inverter_efficiency",user_arguments)
    azimuth_type = runner.getStringArgumentValue("azimuth_type",user_arguments)
    azimuth = runner.getDoubleArgumentValue("azimuth",user_arguments)
    tilt_type = runner.getStringArgumentValue("tilt_type",user_arguments)
    tilt = runner.getDoubleArgumentValue("tilt",user_arguments)

    if azimuth > 360 or azimuth < 0
      runner.registerError("Invalid azimuth entered.")
      return false
    end

    pv_system = PVSystem.new
    pv_azimuth = PVAzimuth.new
    pv_tilt = PVTilt.new

    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
      return false
    end

    roof_tilt = Geometry.get_roof_pitch(model.getSurfaces)

    pv_system.size = UnitConversions.convert(size, "kW", "W")
    pv_system.module_type = module_type
    pv_system.inv_eff = inverter_efficiency
    pv_system.losses = system_losses
    pv_tilt.abs = Geometry.get_abs_tilt(tilt_type, tilt, roof_tilt, weather.header.Latitude)
    pv_azimuth.abs = Geometry.get_abs_azimuth(azimuth_type, azimuth, model.getBuilding.northAxis)

    obj_name = Constants.ObjectNamePhotovoltaics

    # Remove existing photovoltaics
    curves_to_remove = []
    model.getElectricLoadCenterDistributions.each do |electric_load_center_dist|
      next unless electric_load_center_dist.name.to_s == "#{obj_name} elec load center dist"
      electric_load_center_dist.generators.each do |generator|
        generator = generator.to_GeneratorPVWatts.get
        generator.remove
      end
      if electric_load_center_dist.inverter.is_initialized
        inverter = electric_load_center_dist.inverter.get
        inverter.remove
      end
      electric_load_center_dist.remove
    end

    electric_load_center_dist = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
    electric_load_center_dist.setName("#{obj_name} elec load center dist")

    generator = OpenStudio::Model::GeneratorPVWatts.new(model, pv_system.size)
    generator.setName("#{obj_name} generator")
    generator.setModuleType(pv_system.module_type)
    generator.setSystemLosses(pv_system.losses)
    generator.setTiltAngle(pv_tilt.abs)
    generator.setAzimuthAngle(pv_azimuth.abs)
    
    inverter = OpenStudio::Model::ElectricLoadCenterInverterPVWatts.new(model)
    inverter.setName("#{obj_name} inverter")
    inverter.setInverterEfficiency(pv_system.inv_eff)

    electric_load_center_dist.addGenerator(generator)
    electric_load_center_dist.setInverter(inverter)

    return true

  end

end

# register the measure to be used by the application
ResidentialPhotovoltaics.new.registerWithApplication