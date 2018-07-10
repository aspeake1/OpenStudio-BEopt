#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"

#start the measure
class ResidentialHvacEvaporativeCooler < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Evaporative Cooler"
  end
  
  def description
    return "This measure removes any existing HVAC components from the building and adds an evaporative cooler with an on/off supply fan to a unitary air loop. For multifamily buildings, the evaporative cooler can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Any supply components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. Any existing air/plant loops are also removed. An evaporative cooler element "EvaporativeCoolerDirectResearchSpecial" and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone.# A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a string argument for ashp installed seer
    seer = OpenStudio::Measure::OSArgument::makeDoubleArgument("seer", true)
    seer.setDisplayName("Installed SEER")
    seer.setUnits("Btu/W-h")
    seer.setDescription("The installed Seasonal Energy Efficiency Ratio (SEER) of the heat pump.")
    seer.setDefaultValue(13.0)
    args << seer

    #make a double argument for ashp rated supply fan power
    fan_power_rated = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_rated", true)
    fan_power_rated.setDisplayName("Rated Supply Fan Power")
    fan_power_rated.setUnits("W/cfm")
    fan_power_rated.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan under conditions prescribed by AHRI Standard 210/240 for SEER testing.")
    fan_power_rated.setDefaultValue(0.365)
    args << fan_power_rated
    
    #make a double argument for ashp installed supply fan power
    fan_power_installed = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_installed", true)
    fan_power_installed.setDisplayName("Installed Supply Fan Power")
    fan_power_installed.setUnits("W/cfm")
    fan_power_installed.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan for the maximum fan speed under actual operating conditions.")
    fan_power_installed.setDefaultValue(0.5)
    args << fan_power_installed     
    
    #make a string argument for distribution system efficiency
    dse = OpenStudio::Measure::OSArgument::makeStringArgument("dse", true)
    dse.setDisplayName("Distribution System Efficiency")
    dse.setDescription("Defines the energy losses associated with the delivery of energy from the equipment to the source of the load.")
    dse.setDefaultValue("NA")
    args << dse   
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    seer = runner.getDoubleArgumentValue("seer",user_arguments)
    fan_power_rated = runner.getDoubleArgumentValue("fan_power_rated",user_arguments)
    fan_power_installed = runner.getDoubleArgumentValue("fan_power_installed",user_arguments)
    dse = runner.getStringArgumentValue("dse",user_arguments)
    if dse.to_f > 0
      dse = dse.to_f
    else
      dse = 1.0
    end
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end
    
    units.each do |unit|

      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      HVAC.get_control_and_slave_zones(thermal_zones).each do |control_zone, slave_zones|
        ([control_zone] + slave_zones).each do |zone|
          HVAC.remove_hvac_equipment(model, runner, zone, unit,
                                     Constants.ObjectNameAirSourceHeatPump)
        end
      end
      
      success = HVAC.apply_central_ashp_1speed(model, unit, runner, seer, 
                                               fan_power_rated, fan_power_installed,
                                               dse)
      return false if not success
                                               
    end # unit

    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessEvaporativeCoolerDirectResearchSpecial.new.registerWithApplication