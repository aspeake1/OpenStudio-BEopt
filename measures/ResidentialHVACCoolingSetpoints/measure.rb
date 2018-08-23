#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/hvac"

#start the measure
class ProcessCoolingSetpoints < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Cooling Setpoints and Schedules"
  end
  
  def description
    return "This measure creates the cooling season schedules and the cooling setpoint schedules.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "This measure creates #{Constants.ObjectNameCoolingSeason} ruleset objects. Schedule values are either user-defined or populated based on information contained in the EPW file. This measure also creates #{Constants.ObjectNameCoolingSetpoint} ruleset objects. Schedule values are populated based on information input by the user as well as contained in the #{Constants.ObjectNameCoolingSeason}. The cooling setpoint schedules are added to the living zone's thermostat."
  end     
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
  
    #Make a string argument for 24 weekday cooling set point values
    weekday_setpoint = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_setpoint", true)
    weekday_setpoint.setDisplayName("Weekday Setpoint")
    weekday_setpoint.setDescription("Specify a single cooling setpoint or a 24-hour comma-separated cooling schedule for the weekdays.")
    weekday_setpoint.setUnits("degrees F")
    weekday_setpoint.setDefaultValue("76")
    args << weekday_setpoint  
    
    #Make a string argument for 24 weekend cooling set point values
    weekend_setpoint = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_setpoint", true)
    weekend_setpoint.setDisplayName("Weekend Setpoint")
    weekend_setpoint.setDescription("Specify a single cooling setpoint or a 24-hour comma-separated cooling schedule for the weekend.")
    weekend_setpoint.setUnits("degrees F")
    weekend_setpoint.setDefaultValue("76")
    args << weekend_setpoint    

    weekday_setback_1 = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_setback_1", true)
    weekday_setback_1.setDisplayName("Weekday Setback_1")
    weekday_setback_1.setDescription("Specify a  24-hour comma-separated cooling offset schedule for the weekdays.")
    weekday_setback_1.setUnits("degrees F")
    weekday_setback_1.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << weekday_setback_1  
    
    #Make a string argument for 24 weekend cooling set point values
    weekend_setpoint = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_setback_1", true)
    weekend_setpoint.setDisplayName("Weekend_setback_1")
    weekend_setpoint.setDescription("Specify  a 24-hour comma-separated cooling schedule for the weekend.")
    weekend_setpoint.setUnits("degrees F")
    weekend_setpoint.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << weekend_setpoint

    weekday_setback_2 = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_setback_2", true)
    weekday_setback_2.setDisplayName("Weekday Setback_2")
    weekday_setback_2.setDescription("Specify a  24-hour comma-separated cooling offset schedule for the weekdays.")
    weekday_setback_2.setUnits("degrees F")
    weekday_setback_2.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << weekday_setback_2  
    
    #Make a string argument for 24 weekend cooling set point values
    weekend_setpoint = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_setback_2", true)
    weekend_setpoint.setDisplayName("Weekend_setback_2")
    weekend_setpoint.setDescription("Specify  a 24-hour comma-separated cooling schedule for the weekend.")
    weekend_setpoint.setUnits("degrees F")
    weekend_setpoint.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << weekend_setpoint

    weekday_setback_3 = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_setback_3", true)
    weekday_setback_3.setDisplayName("Weekday Setback_3")
    weekday_setback_3.setDescription("Specify a  24-hour comma-separated cooling offset schedule for the weekdays.")
    weekday_setback_3.setUnits("degrees F")
    weekday_setback_3.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << weekday_setback_3  
    
    #Make a string argument for 24 weekend cooling set point values
    weekend_setpoint = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_setback_3", true)
    weekend_setpoint.setDisplayName("Weekend_setback_3")
    weekend_setpoint.setDescription("Specify  a 24-hour comma-separated cooling schedule for the weekend.")
    weekend_setpoint.setUnits("degrees F")
    weekend_setpoint.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << weekend_setpoint    

    #make a bool argument for using hsp season or not
    use_auto_season = OpenStudio::Measure::OSArgument::makeBoolArgument("use_auto_season", true)
    use_auto_season.setDisplayName("Use Auto Cooling Season")
    use_auto_season.setDescription("Specifies whether to automatically define the cooling season based on the weather file. User-defined cooling season start/end months will be ignored if this is selected.")
    use_auto_season.setDefaultValue(false)
    args << use_auto_season
    
    #make a choice argument for months of the year
    month_display_names = OpenStudio::StringVector.new
    month_display_names << "Jan"
    month_display_names << "Feb"
    month_display_names << "Mar"
    month_display_names << "Apr"
    month_display_names << "May"
    month_display_names << "Jun"
    month_display_names << "Jul"
    month_display_names << "Aug"
    month_display_names << "Sep"
    month_display_names << "Oct"
    month_display_names << "Nov"
    month_display_names << "Dec"
    
    season_start_month = OpenStudio::Measure::OSArgument::makeChoiceArgument("season_start_month", month_display_names, false)
    season_start_month.setDisplayName("Cooling Season Start Month")
    season_start_month.setDescription("Start month of the cooling season.")
    season_start_month.setDefaultValue("Jan")
    args << season_start_month
    
    season_end_month = OpenStudio::Measure::OSArgument::makeChoiceArgument("season_end_month", month_display_names, false)
    season_end_month.setDisplayName("Cooling Season End Month")
    season_end_month.setDescription("End month of the cooling season.")
    season_end_month.setDefaultValue("Dec")
    args << season_end_month
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    weekday_setpoint = runner.getStringArgumentValue("weekday_setpoint",user_arguments)
    weekend_setpoint = runner.getStringArgumentValue("weekend_setpoint",user_arguments)
    
    weekday_setback_1 = runner.getStringArgumentValue("weekday_setback_1",user_arguments)
    weekend_setpoint_1 = runner.getStringArgumentValue("weekend_setpoint_1",user_arguments)
    
    weekday_setback_2 = runner.getStringArgumentValue("weekday_setback_2",user_arguments)
    weekend_setpoint_2 = runner.getStringArgumentValue("weekend_setpoint_2",user_arguments)

    weekday_setback_3 = runner.getStringArgumentValue("weekday_setback_3",user_arguments)
    weekend_setpoint_3 = runner.getStringArgumentValue("weekend_setpoint_3",user_arguments)

    use_auto_season = runner.getBoolArgumentValue("use_auto_season",user_arguments)
    season_start_month = runner.getOptionalStringArgumentValue("season_start_month",user_arguments)
    season_end_month = runner.getOptionalStringArgumentValue("season_end_month",user_arguments)    
    
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
      return false
    end
    
    # Convert to 24-values if a single value entered for the setpoint
    if not weekday_setpoint.include?(",")
      weekday_setpoints = Array.new(24, weekday_setpoint.to_f)
    else
      weekday_setpoints = weekday_setpoint.split(",").map(&:to_f)
    end
    if not weekend_setpoint.include?(",")
      weekend_setpoints = Array.new(24, weekend_setpoint.to_f)
    else
      weekend_setpoints = weekend_setpoint.split(",").map(&:to_f)
    end
    
    # Create one 24-value string for setback schedule if 3 separate setbacks are defined
    weekday_setback_sch= [weekday_setback_1.split(".").map(&:to_f) , weekday_setback_2.split(".").map(&:to_f) , weekday_setback_3.split(".").map(&:to_f)].trnaspose{&:sum} 
    weekend_setback_sch = [weekend_setback_1.split(",").map(&:to_f) , weekend_setpoint_2.split(",").map(&:to_f) , weekend_setback_3.split(",").map(&:to_f)].transpose{&:sum}

    weekday_setpoints -= weekday_setback_sch
    weekend_setpoints -= weekend_setback_sch

    # Convert to month int or nil
    month_map = {"Jan"=>1, "Feb"=>2, "Mar"=>3, "Apr"=>4, "May"=>5, "Jun"=>6, "Jul"=>7, "Aug"=>8, "Sep"=>9, "Oct"=>10, "Nov"=>11, "Dec"=>12}
    if not season_start_month.is_initialized
      season_start_month = nil
    else
      season_start_month = month_map[season_start_month.get]
    end
    if not season_end_month.is_initialized
      season_end_month = nil
    elseruby 
      season_end_month = month_map[season_end_month.get]
    end
    
    success = HVAC.apply_cooling_setpoints(model, runner, weather, weekday_setpoints, weekend_setpoints,
                                           use_auto_season, season_start_month, season_end_month)
    return false if not success
    
    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessCoolingSetpoints.new.registerWithApplication