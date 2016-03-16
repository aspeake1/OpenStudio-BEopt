# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class SetResidentialExteriorFinish < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Exterior Finish"
  end

  # human readable description
  def description
    return "This measure assigns the exterior finish to all above-grade exterior walls."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Assigns material layer properties for all above-grade walls adjacent to outside."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

	#make a double argument for solar absorptivity
	solar_abs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("solar_abs", true)
	solar_abs.setDisplayName("Solar Absorptivity")
	solar_abs.setDescription("Fraction of the incident radiation that is absorbed.")
	solar_abs.setDefaultValue(0.3)
	args << solar_abs

	#make a double argument for conductivity
	cond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cond", true)
	cond.setDisplayName("Conductivity")
    cond.setUnits("Btu-in/h-ft^2-R")
	cond.setDescription("Conductivity of the exterior finish assembly.")
	cond.setDefaultValue(0.62)
	args << cond

	#make a double argument for density
	dens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("dens", true)
	dens.setDisplayName("Density")
    dens.setUnits("lb/ft^3")
	dens.setDescription("Density of the exterior finish assembly.")
	dens.setDefaultValue(11.1)
	args << dens

    #make a double argument for specific heat
	specheat = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("specheat", true)
	specheat.setDisplayName("Specific Heat")
    specheat.setUnits("Btu/lb-R")
	specheat.setDescription("Specific heat of the exterior finish assembly.")
	specheat.setDefaultValue(0.25)
	args << specheat

    #make a double argument for thickness
	thick_in = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("thick_in", true)
	thick_in.setDisplayName("Thickness")
    thick_in.setUnits("in")
	thick_in.setDescription("Thickness of the exterior finish assembly.")
	thick_in.setDefaultValue(0.375)
	args << thick_in

    #make a double argument for emissivity
	emiss = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("emiss", true)
	emiss.setDisplayName("Emissivity")
	emiss.setDescription("Measure of the exterior finish's ability to emit infrared energy.")
	emiss.setDefaultValue(0.9)
	args << emiss
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Above-grade walls adjacent to outdoors
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            if surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors"
                surfaces << surface
            end
        end
    end
    if surfaces.empty?
        return true
    end
    
    # assign the user inputs to variables
    solar_abs = runner.getDoubleArgumentValue("solar_abs",user_arguments)
    cond = runner.getDoubleArgumentValue("cond",user_arguments)
    dens = runner.getDoubleArgumentValue("dens",user_arguments)
    specheat = runner.getDoubleArgumentValue("specheat",user_arguments)
    thick_in = runner.getDoubleArgumentValue("thick_in",user_arguments)
    emiss = runner.getDoubleArgumentValue("emiss",user_arguments)

    # Define materials
    mat = Material.new(name=Constants.MaterialWallExtFinish, thick_in=thick_in, mat_base=nil, cond=OpenStudio::convert(cond,"in","ft").get, dens=dens, sh=specheat, tAbs=emiss, sAbs=solar_abs, vAbs=solar_abs)
    
    # Define construction
    ext_fin = Construction.new([1])
    ext_fin.addlayer(mat, true)
    
    # Create and apply construction to surfaces
    if not ext_fin.create_and_assign_constructions(surfaces, runner, model)
        return false
    end
    
    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)
    
    return true

  end
  
end

# register the measure to be used by the application
SetResidentialExteriorFinish.new.registerWithApplication
