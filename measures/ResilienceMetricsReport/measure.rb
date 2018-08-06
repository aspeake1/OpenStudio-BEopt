# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/unit_conversions"

# start the measure
class ResilienceMetricsReport < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Resilience Metrics Report'
  end

  # human readable description
  def description
    return 'Reports resilience metric(s) of interest.'
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Measure::OSArgumentVector.new

    #make an argument for optional output variables
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("output_vars", true)
    arg.setDisplayName("Output Variables")
    arg.setDescription("Output variables to request.")
    arg.setDefaultValue("Zone Mean Air Temperature, Zone Air Relative Humidity, Wet Bulb Globe Temperature")
    args << arg

    #make a double argument for minimum comfortable temperature
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("min_vals", true)
    arg.setDisplayName("Minimum Value")
    arg.setDescription("Lower threshold. Use 'NA' if a lower threshold is not applicable.")
    arg.setDefaultValue("60, NA, NA")
    args << arg

    #make a double argument for maximum comfortable temperature
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("max_vals", true)
    arg.setDisplayName("Maximum Value")
    arg.setDescription("Upper threshold. Use 'NA' if an upper threshold is not applicable.")
    arg.setDefaultValue("80, 60, 88")
    args << arg

    return args
  end
  
  def thermal_zones
    return ["Living Zone", "Finished Basement Zone"]
  end

  # define the outputs that the measure will create
  def outputs
    output_vars = ["Zone Mean Air Temperature", "Zone Air Relative Humidity"] # possible list that the user can enter limits for; should get blank column for ones that aren't entered into output_vars arg
    buildstock_outputs = []
    output_vars.each do |output_var|
      thermal_zones.each do |zone|
        buildstock_outputs << "#{OpenStudio::toUnderscoreCase(zone)}_#{OpenStudio::toUnderscoreCase(output_var)}_below" # hours below lower threshold
        buildstock_outputs << "#{OpenStudio::toUnderscoreCase(zone)}_#{OpenStudio::toUnderscoreCase(output_var)}_above" # hours above upper threshold
      end
    end
    result = OpenStudio::Measure::OSOutputVector.new
    buildstock_outputs.each do |output|
      result << OpenStudio::Measure::OSOutput.makeDoubleOutput(output)
    end
    return result
  end
  
  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  # Warning: Do not change the name of this method to be snake_case. The method must be lowerCamelCase.
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new

    # use the built-in error checking
    if !runner.validateUserArguments(arguments, user_arguments)
      return result
    end

    output_vars = runner.getStringArgumentValue("output_vars",user_arguments).split(",")

    # TODO: request this from E+ team
    if output_vars == "Wet Bulb Globe Temperature"
      outputs_vars.delete("Wet Bulb Globe Temperature")
      outputs_vars << "Zone Outdoor Air Wetbulb Temperature"
      outputs_vars << "Zone Mean Radiant Temperature"
    end

    output_vars.each do |output_var|
      result << OpenStudio::IdfObject.load("Output:Variable,*,#{output_var.strip},Hourly;").get
    end

    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    # Assign the user inputs to variables
    output_vars = runner.getStringArgumentValue("output_vars",user_arguments).split(",")
    min_vals = runner.getStringArgumentValue("min_vals", user_arguments).split(",")
    max_vals = runner.getStringArgumentValue("max_vals", user_arguments).split(",")

    # Error checking
    if output_vars.length != min_vals.length or output_vars.length != max_vals.length
      runner.registerError("Number of output variable elements specified inconsistent with either number of minimum or maximum values.")
      return false
    end

    # Get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get
    
    # Get the last sql file
    sql = runner.lastEnergyPlusSqlFile
    if sql.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sql = sql.get
    model.setSqlFile(sql)

    # Get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sql.availableEnvPeriods.each do |env_pd|
      env_type = sql.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          ann_env_pd = env_pd
        end
      end
    end
    if ann_env_pd == false
      runner.registerError("Can't find a weather runperiod, make sure you ran an annual simulation, not just the design days.")
      return false
    end

    output_vars.each_with_index do |output_var, i|
      sql.availableKeyValues(ann_env_pd, "Hourly", output_var.strip).each do |key_value|

        next unless thermal_zones.any? { |zone| zone.casecmp(key_value) == 0 }

        if output_var != "Wet Bulb Globe Temperature"
          timeseries = get_timeseries(sql, ann_env_pd, output_var, key_value)
        else
          t_w = get_timeseries(sql, ann_env_pd, "Zone Outdoor Air Wetbulb Temperature", key_value)
          t_g = get_timeseries(sql, ann_env_pd, "Zone Mean Radiant Temperature", key_value)
          timeseries = 0.7 * t_w + 0.3 * t_g # https://en.wikipedia.org/wiki/Wet-bulb_globe_temperature
        end

        unless timeseries
          runner.registerError("No data found for Hourly #{key_value} #{output_var.strip}.")
          return false
        end

        # Hours above or below threshold

        resilience_metric_below, resilience_metric_above = calc_resilience_metric(output_var.strip, values, min_vals[i].strip, max_vals[i].strip)

        unless resilience_metric_below.nil?
          report_output(runner, "#{key_value} #{output_var.strip} below", resilience_metric_below)
        end

        unless resilience_metric_above.nil?
          report_output(runner, "#{key_value} #{output_var.strip} above", resilience_metric_above)
        end

        # Coast times

        coast_time_below, coast_time_above = calc_coast_time(output_var.strip, values, min_vals[i].strip, max_vals[i].strip)

        unless coast_time_below.nil?
          report_output(runner, "#{key_value} #{output_var.strip} below", coast_time_below)
        end

        unless coast_time_above.nil?
          report_output(runner, "#{key_value} #{output_var.strip} above", coast_time_above)
        end

      end
    end

    sql.close()

    return true
  end

  def convert_val(output_var, val)
    if output_var == "Zone Mean Air Temperature"
      unless val == "NA"
        val = UnitConversions.convert(val, "F", "C")
      end
    end
    return val
  end

  def calc_resilience_metric(output_var, values, min_val, max_val) # hours spend below, above specified thresholds

    min_val = convert_val(output_var, min_val)
    max_val = convert_val(output_var, max_val)

    min_val == "NA" ? resilience_metric_below = nil : resilience_metric_below = 0
    unless resilience_metric_below.nil?
      (0...values.length).to_a.each do |i|
        if values[i] < min_val
          resilience_metric_below += 1
        end
      end
    end

    max_val == "NA" ? resilience_metric_above = nil : resilience_metric_above = 0
    unless resilience_metric_above.nil?
      (0...values.length).to_a.each do |i|
        if values[i] > max_val
          resilience_metric_above += 1
        end
      end
    end

    return resilience_metric_below, resilience_metric_above

  end

  def calc_coast_time(output_var, values, min_val, max_val) # hours until hitting below, above specified thresholds

    ix_outage_start = 0 # TODO: get outage start hour index from AdditionalProperties when available

    min_val = convert_val(output_var, min_val)
    max_val = convert_val(output_var, max_val)

    min_val == "NA" ? coast_time_below = nil : coast_time_below = 0
    hit_below = false
    unless coast_time_below.nil?
      (ix_outage_start...values.length).to_a.each do |i|
        if values[i] > min_val
          coast_time_below += 1
        elsif values[i] <= min_val
          hit_below = true
          break
        end
      end
    end

    unless hit_below
      coast_time_below = nil
    end

    max_val == "NA" ? coast_time_above = nil : coast_time_above = 0
    hit_above = false
    unless coast_time_above.nil?
      (ix_outage_start...values.length).to_a.each do |i|
        if values[i] < max_val
          coast_time_above += 1
        elsif values[i] >= max_val
          hit_above = true
          break
        end
      end
    end

    unless hit_above
      coast_time_above = nil
    end

    return coast_time_below, coast_time_above

  end

  def get_timeseries(sql, ann_env_pd, output_var, key_value)
    timeseries = sql.timeSeries(ann_env_pd, "Hourly", output_var.strip, key_value)
    if timeseries.empty?
      return false
    else
      values = timeseries.get.values
    end
    return timeseries
  end

  def report_output(runner, name, val)
    runner.registerValue(name, val)
    runner.registerInfo("Registering #{val} for #{name}.")
  end

end

# register the measure to be used by the application
ResilienceMetricsReport.new.registerWithApplication
