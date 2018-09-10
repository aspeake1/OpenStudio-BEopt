# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/simulation"

# start the measure
class SimulationControls < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SimulationControls'
  end

  # human readable description
  def description
    return 'Set the simulation timesteps per hour and the run period begin and end months and days.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Set the simulation timesteps per hour and the run period begin and end months and days.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make an argument for the simulation timesteps per hour
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("timesteps_per_hr", true)
    arg.setDisplayName("Simulation Timesteps Per Hour")
    arg.setDefaultValue(6)
    args << arg

    #make an argument for the run period begin month
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("begin_month", true)
    arg.setDisplayName("Run Period Begin Month")
    arg.setDefaultValue(1)
    args << arg

    #make an argument for the run period begin day of month
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("begin_day_of_month", true)
    arg.setDisplayName("Run Period Begin Day of Month")
    arg.setDefaultValue(1)
    args << arg

    #make an argument for the run period end month
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("end_month", true)
    arg.setDisplayName("Run Period End Month")
    arg.setDefaultValue(12)
    args << arg

    #make an argument for the run period end day of month
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("end_day_of_month", true)
    arg.setDisplayName("Run Period End Day of Month")
    arg.setDefaultValue(31)
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    timesteps_per_hr = runner.getDoubleArgumentValue("timesteps_per_hr",user_arguments)
    begin_month = runner.getDoubleArgumentValue("begin_month",user_arguments)
    begin_day_of_month = runner.getDoubleArgumentValue("begin_day_of_month",user_arguments)
    end_month = runner.getDoubleArgumentValue("end_month",user_arguments)
    end_day_of_month = runner.getDoubleArgumentValue("end_day_of_month",user_arguments)

    # Error checking
    if timesteps_per_hr < 1 or timesteps_per_hr > 60
      runner.registerError("User-entered #{timesteps_per_hr} timesteps per hour must be between 1 and 60.")
      return false
    end

    if 60 % timesteps_per_hr != 0
      runner.registerError("User-entered #{timesteps_per_hr} timesteps per hour does not divide evenly into 60.")
      return false
    end

    timesteps_per_hr = timesteps_per_hr.to_i
    begin_month = begin_month.to_i
    begin_day_of_month = begin_day_of_month.to_i
    end_month = end_month.to_i
    end_day_of_month = end_day_of_month.to_i

    if not (1..12).to_a.include? begin_month or not (1..12).to_a.include? end_month
      runner.registerError("Invalid begin month (#{begin_month}) and/or end month (#{end_month}) entered.")
      return false
    end

    {begin_month=>begin_day_of_month, end_month=>end_day_of_month}.each_with_index do |(month, day), i|
      day_of_month_valid = false
      case month
      when 1
        day_of_month_valid = (1..31).to_a.include? day
      when 2
        day_of_month_valid = (1..29).to_a.include? day
      when 3
        day_of_month_valid = (1..31).to_a.include? day
      when 4
        day_of_month_valid = (1..30).to_a.include? day
      when 5
        day_of_month_valid = (1..31).to_a.include? day
      when 6
        day_of_month_valid = (1..30).to_a.include? day
      when 7
        day_of_month_valid = (1..31).to_a.include? day
      when 8
        day_of_month_valid = (1..31).to_a.include? day
      when 9
        day_of_month_valid = (1..30).to_a.include? day
      when 10
        day_of_month_valid = (1..31).to_a.include? day
      when 11
        day_of_month_valid = (1..30).to_a.include? day
      when 12
        day_of_month_valid = (1..31).to_a.include? day
      end

      unless day_of_month_valid
        if i == 0
          runner.registerError("Invalid begin day of month (#{begin_day_of_month}) entered.")
        elsif i == 1
          runner.registerError("Invalid end day of month (#{end_day_of_month}) entered.")
        end
        return false
      end
    end

    success = Simulation.apply(model, runner, timesteps_per_hr)
    return false if not success

    runner.registerInfo("Set the simulation timesteps per hour to #{timesteps_per_hr}.")

    run_period = model.getRunPeriod
    run_period.setBeginMonth(begin_month)
    run_period.setBeginDayOfMonth(begin_day_of_month)
    run_period.setEndMonth(end_month)
    run_period.setEndDayOfMonth(end_day_of_month)

    runner.registerInfo("Set the run period begin and end month/day to #{begin_month}/#{begin_day_of_month} and #{end_month}/#{end_day_of_month}, respectively.")

    return true
  end
end

# register the measure to be used by the application
SimulationControls.new.registerWithApplication
