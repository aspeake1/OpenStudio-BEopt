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
    return 'Description.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Modeler description.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make an argument for the simulation timesteps per hour
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("timesteps_per_hr", true)
    arg.setDisplayName("Simulation Timesteps Per Hour")
    arg.setDefaultValue(6)
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

    if timesteps_per_hr < 1 or timesteps_per_hr > 60
      runner.registerError("User-entered #{timesteps_per_hr} timesteps per hour must be between 1 and 60.")
      return false
    end

    if 60 % timesteps_per_hr != 0
      runner.registerError("User-entered #{timesteps_per_hr} timesteps per hour does not divide evenly into 60.")
      return false
    end

    timesteps_per_hr = timesteps_per_hr.to_i

    success = Simulation.apply(model, runner, timesteps_per_hr)
    return false if not success

    runner.registerInfo("Set the simulation timesteps per hour to #{timesteps_per_hr}.")

    return true
  end
end

# register the measure to be used by the application
SimulationControls.new.registerWithApplication
