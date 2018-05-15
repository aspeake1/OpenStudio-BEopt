# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"
require "#{File.dirname(__FILE__)}/resources/airflow"

#start the measure
class ResidentialQualityFaultProgram < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Single-Speed Central Air Conditioner"
  end
  
  def description
    return "This measure removes any existing HVAC cooling components from the building and adds a single-speed central air conditioner along with an on/off supply fan to a unitary air loop. For multifamily buildings, the single-speed central air conditioner can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Any cooling components are removed from any existing air loops or zones. Any existing air loops are also removed. A cooling DX coil and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a double argument for central ac rated cfm per ton
    rated_cfm_per_ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("rated_cfm_per_ton", true)
    rated_cfm_per_ton.setDisplayName("Rated CFM Per Ton")
    rated_cfm_per_ton.setUnits("cfm/ton")
    rated_cfm_per_ton.setDescription("TODO.")
    rated_cfm_per_ton.setDefaultValue(400.0)
    args << rated_cfm_per_ton
    
    #make a double argument for central ac actual cfm per ton
    actual_cfm_per_ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("actual_cfm_per_ton", true)
    actual_cfm_per_ton.setDisplayName("Actual CFM Per Ton")
    actual_cfm_per_ton.setUnits("cfm/ton")
    actual_cfm_per_ton.setDescription("TODO.")
    actual_cfm_per_ton.setDefaultValue(400.0)
    args << actual_cfm_per_ton

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    rated_cfm_per_ton = runner.getDoubleArgumentValue("rated_cfm_per_ton",user_arguments)
    actual_cfm_per_ton = runner.getDoubleArgumentValue("actual_cfm_per_ton",user_arguments)
    
    # Error checking
    if ( rated_cfm_per_ton < 150 or actual_cfm_per_ton < 150 ) or ( rated_cfm_per_ton > 750 or actual_cfm_per_ton > 750 )
      runner.registerError("Input(s) are outside the valid range.")
      return false
    end
    if ( rated_cfm_per_ton < 200 or actual_cfm_per_ton < 200 ) or ( rated_cfm_per_ton > 600 or actual_cfm_per_ton > 600 )
      runner.registerWarning("Input(s) are almost outside the valid range.")
    end

    # Output variables
    output_vars = Airflow.create_output_vars(model, ["Zone Mean Air Temperature", "Zone Outdoor Air Drybulb Temperature"])

    HVAC.remove_fault_ems(model, Constants.ObjectNameInstallationQualityFault)

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    units.each do |unit|

      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      HVAC.get_control_and_slave_zones(thermal_zones).each do |control_zone, slave_zones|

        if HVAC.has_central_ac(model, runner, control_zone) or HVAC.has_ashp(model, runner, control_zone)

          result = HVAC.write_fault_ems(model, unit, runner, control_zone, rated_cfm_per_ton, actual_cfm_per_ton, HVAC.has_ashp(model, runner, control_zone), output_vars)
          return false unless result

        else

          runner.registerWarning("No central air conditioner or air source heat pump found.")
          return true

        end

      end

    end # unit

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialQualityFaultProgram.new.registerWithApplication