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
class ProcessHeatingSetpoints < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Heating Setpoints and Schedules"
  end
  
  def description
    return "This measure creates the heating season schedules and the heating setpoint schedules.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "This measure creates #{Constants.ObjectNameHeatingSeason} ruleset objects. Schedule values are either user-defined or populated based on information contained in the EPW file. This measure also creates #{Constants.ObjectNameHeatingSetpoint} ruleset objects. Schedule values are populated based on information input by the user as well as contained in the #{Constants.ObjectNameHeatingSeason}. The heating setpoint schedules are added to the living zone's thermostat. The heating setpoint schedules are added to the living zone's thermostat. The heating setpoint schedule is constructed by taking the base setpoint (or 24-hour comma-separated heating schedule) and applying an optional offset, as specified by the offset magnitude and offset schedule. If specified as a 24-hour schedule, the base setpoint can incorporate setpoint schedule changes, but having a separately specified offset magnitude and schedule is convenient for parametric runs."
  end     
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

   #Make a string argument for 24 weekday heating set point values
    weekday_setpoint = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_setpoint", true)
    weekday_setpoint.setDisplayName("Weekday Setpoint")
    weekday_setpoint.setDescription("Specify a single heating setpoint or a 24-hour comma-separated heating schedule for the weekdays.")
    weekday_setpoint.setUnits("degrees F")
    weekday_setpoint.setDefaultValue("71")
    args << weekday_setpoint

    #Make a string argument for 24 weekend heating set point values
    weekend_setpoint = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_setpoint", true)
    weekend_setpoint.setDisplayName("Weekend Setpoint")
    weekend_setpoint.setDescription("Specify a single heating setpoint or a 24-hour comma-separated heating schedule for the weekend.")
    weekend_setpoint.setUnits("degrees F")
    weekend_setpoint.setDefaultValue("71")
    args << weekend_setpoint

    #Make a string argument for 24 weekday heating set point offset magnitude
    weekday_offset_magnitude = OpenStudio::Measure::OSArgument::makeDoubleArgument("weekday_offset_magnitude", true)
    weekday_offset_magnitude.setDisplayName("Weekday Offset Magnitude")
    weekday_offset_magnitude.setDescription("Specify the magnitude of the heating setpoint offset for the weekdays, which will be applied during hours specified by the offset schedule. A positive offset increases the setpoint while a negative offset decreases the setpoint.")
    weekday_offset_magnitude.setUnits("degrees F")
    weekday_offset_magnitude.setDefaultValue(0)
    args << weekday_offset_magnitude

    #Make a string argument for 24 weekend heating set point offset magnitude
    weekend_offset_magnitude = OpenStudio::Measure::OSArgument::makeDoubleArgument("weekend_offset_magnitude", true)
    weekend_offset_magnitude.setDisplayName("Wcalceekend Offset Magnitude")
    weekend_offset_magnitude.setDescription("Specify the magnitude of the heating setpoint offset for the weekdays, which will be applied during hours specified by the offset schedule. A positive offset increases the setpoint while a negative offset decreases the setpoint.")
    weekend_offset_magnitude.setUnits("degrees F")
    weekend_offset_magnitude.setDefaultValue(0)
    args << weekend_offset_magnitude    

    #Make a string argument for 24 weekday heating offset values
    weekday_offset_schedule = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_offset_schedule", true)
    weekday_offset_schedule.setDisplayName("Weekday offset Schedule")
    weekday_offset_schedule.setDescription("Specify a 24-hour comma-separated schedule of 0s and 1s for applying the offset on weekdays.")
    weekday_offset_schedule.setUnits("degrees F")
    weekday_offset_schedule.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << weekday_offset_schedule  
    
    #Make a string argument for 24 weekend heating offset_tod values
    weekend_offset_schedule = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_offset_schedule", true)
    weekend_offset_schedule.setDisplayName("Weekend offset Schedule")
    weekend_offset_schedule.setDescription("Specify a 24-hour comma-separated schedule of 0s and 1s for applying the offset on weekend.")
    weekend_offset_schedule.setUnits("degrees F")
    weekend_offset_schedule.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << weekend_offset_schedule

    #make a bool argument for using hsp season or not
    use_auto_season = OpenStudio::Measure::OSArgument::makeBoolArgument("use_auto_season", true)
    use_auto_season.setDisplayName("Use Auto Heating Season")
    use_auto_season.setDescription("Specifies whether to automatically define the heating season based on the weather file. User-defined heating season start/end months will be ignored if this is selected")
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
    season_start_month.setDisplayName("Heating Season Start Month")
    season_start_month.setDescription("Start month of the heating season.")
    season_start_month.setDefaultValue("Jan")
    args << season_start_month

    season_end_month = OpenStudio::Measure::OSArgument::makeChoiceArgument("season_end_month", month_display_names, false)
    season_end_month.setDisplayName("Heating Season End Month")
    season_end_month.setDescription("End month of the heating season.")
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

    weekday_offset_magnitude = runner.getDoubleArgumentValue("weekday_offset_magnitude", user_arguments)
    weekend_offset_magnitude = runner.getDoubleArgumentValue("weekend_offset_magnitude", user_arguments)
    
    weekday_offset_schedule = runner.getStringArgumentValue("weekday_offset_schedule",user_arguments)
    weekend_offset_schedule = runner.getStringArgumentValue("weekend_offset_schedule",user_arguments)

    use_auto_season = runner.getBoolArgumentValue("use_auto_season",user_arguments)
    season_start_month = runner.getOptionalStringArgumentValue("season_start_month",user_arguments)
    season_end_month = runner.getOptionalStringArgumentValue("season_end_month",user_arguments)    
    
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
      return false
    end
    
    # Convert to 24-values if a single value entered
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

    #  Convert the string of weekday/end-offset magnitude value into a 24 valued float array
    weekday_offset_magnitude = Array.new(24, weekday_offset_magnitude)
    weekend_offset_magnitude = Array.new(24, weekend_offset_magnitude)

  # Convert the string of weekday-offset_tod values into float arrays
    weekday_offset_schedule = weekday_offset_schedule.split(",").map(&:to_f)

    # Convert the string of weekend-offset_tod values into float arrays
    weekend_offset_schedule = weekend_offset_schedule.split(",").map(&:to_f)

    # Error-checking
    if weekday_setpoints.length != 24
      err_msg = "A comma-separated string of 24 numbers must be entered for the weekday setpoint schedule."
      runner.registerError(err_msg)
      return false
    end

    if weekend_setpoints.length != 24
      err_msg = "A comma-separated string of 24 numbers must be entered for the weekend setpoint schedule."
      runner.registerError(err_msg)
      return false
    end

    if weekday_offset_schedule.length != 24
      err_msg = "A comma-separated string of 24 numbers must be entered for the weekday offset time of day schedule."
      runner.registerError(err_msg)
      return false
    end

    if weekend_offset_schedule.length != 24
      err_msg = "A comma-separated string of 24 numbers must be entered for the weekend offset time of day schedule."
      runner.registerError(err_msg)
      return false
    end

    # set the offset variables after offset_mag and offset_tod
    weekday_offset = [weekday_offset_magnitude, weekday_offset_schedule].transpose.map {|x| x.reduce(:*)}
    weekend_offset = [weekend_offset_magnitude, weekend_offset_schedule].transpose.map {|x| x.reduce(:*)}

    # Update to one 24-value float array for setpoints schedule to count for the offset_tods 
    weekday_setpoints = [ weekday_setpoints, weekday_offset].transpose.map {|x| x.reduce(:+)}     
    weekend_setpoints = [ weekend_setpoints, weekend_offset].transpose.map {|x| x.reduce(:+)}
    
    # Convert to month int or nil
    month_map = {"Jan"=>1, "Feb"=>2, "Mar"=>3, "Apr"=>4, "May"=>5, "Jun"=>6, "Jul"=>7, "Aug"=>8, "Sep"=>9, "Oct"=>10, "Nov"=>11, "Dec"=>12}
    if not season_start_month.is_initialized
      season_start_month = nil
    else
      season_start_month = month_map[season_start_month.get]
    end
    if not season_end_month.is_initialized
      season_end_month = nil
    else
      season_end_month = month_map[season_end_month.get]
    end
    
    success = HVAC.apply_heating_setpoints(model, runner, weather, weekday_setpoints, weekend_setpoints,
                                           use_auto_season, season_start_month, season_end_month)
    return false if not success
    
    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessHeatingSetpoints.new.registerWithApplication