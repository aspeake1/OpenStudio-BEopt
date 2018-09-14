#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/constructions"

#start the measure
class ProcessConstructionsSlab < OpenStudio::Measure::ModelMeasure
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Slab Construction"
  end
  
  def description
    return "This measure assigns a construction to slabs.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of slab constructions of finished spaces. Any existing constructions for these surfaces will be removed."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for slab perimeter insulation R-value
    perimeter_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("perimeter_r", true)
    perimeter_r.setDisplayName("Perimeter Insulation Nominal R-value")
    perimeter_r.setUnits("hr-ft^2-R/Btu")
    perimeter_r.setDescription("Perimeter insulation is placed horizontally below the perimeter of the slab.")
    perimeter_r.setDefaultValue(0.0)
    args << perimeter_r
    
    #make a double argument for slab perimeter insulation width
    perimeter_width = OpenStudio::Measure::OSArgument::makeDoubleArgument("perimeter_width", true)
    perimeter_width.setDisplayName("Perimeter Insulation Width")
    perimeter_width.setUnits("ft")
    perimeter_width.setDescription("The distance from the perimeter of the house where the perimeter insulation ends.")
    perimeter_width.setDefaultValue(0.0)
    args << perimeter_width

    #make a double argument for whole slab insulation R-value
    whole_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("whole_r", true)
    whole_r.setDisplayName("Whole Slab Insulation Nominal R-value")
    whole_r.setUnits("hr-ft^2-R/Btu")
    whole_r.setDescription("Whole slab insulation is placed horizontally below the entire slab.")
    whole_r.setDefaultValue(0.0)
    args << whole_r
    
    #make a double argument for slab gap R-value
    gap_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("gap_r", true)
    gap_r.setDisplayName("Gap Insulation Nominal R-value")
    gap_r.setUnits("hr-ft^2-R/Btu")
    gap_r.setDescription("Gap insulation is placed vertically between the edge of the slab and the foundation wall.")
    gap_r.setDefaultValue(0.0)
    args << gap_r

    #make a double argument for slab exterior insulation R-value
    exterior_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("exterior_r", true)
    exterior_r.setDisplayName("Exterior Insulation Nominal R-value")
    exterior_r.setUnits("hr-ft^2-R/Btu")
    exterior_r.setDescription("Exterior insulation is placed vertically on the exterior of the foundation wall.")
    exterior_r.setDefaultValue(0.0)
    args << exterior_r
    
    #make a double argument for slab exterior insulation depth
    exterior_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("exterior_depth", true)
    exterior_depth.setDisplayName("Exterior Insulation Depth")
    exterior_depth.setUnits("ft")
    exterior_depth.setDescription("The depth of the exterior foundation insulation.")
    exterior_depth.setDefaultValue(0.0)
    args << exterior_depth

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    floors_by_type = SurfaceTypes.get_floors(model, runner)

    # Get Inputs
    perimeter_r = runner.getDoubleArgumentValue("perimeter_r",user_arguments)
    perimeter_width = runner.getDoubleArgumentValue("perimeter_width",user_arguments)
    whole_r = runner.getDoubleArgumentValue("whole_r",user_arguments)
    gap_r = runner.getDoubleArgumentValue("gap_r",user_arguments)
    exterior_r = runner.getDoubleArgumentValue("exterior_r",user_arguments)
    exterior_depth = runner.getDoubleArgumentValue("exterior_depth",user_arguments)

    # Apply constructions
    floors_by_type[Constants.SurfaceTypeFloorFndGrndFinSlab].each do |floor_surface|
        if not FoundationConstructions.apply_slab(runner, model, 
                                                  floor_surface,
                                                  Constants.SurfaceTypeFloorFndGrndFinSlab,
                                                  perimeter_r, perimeter_width, gap_r, 
                                                  exterior_r, exterior_depth, whole_r, 4.0, 
                                                  Material.CoveringBare, false, nil, nil)
            return false
        end
    end
    
    floors_by_type[Constants.SurfaceTypeFloorFndGrndUnfinSlab].each do |surface|
        if not FoundationConstructions.apply_slab(runner, model, 
                                                  surface,
                                                  Constants.SurfaceTypeFloorFndGrndUnfinSlab,
                                                  0, 0, 0, 0, 0, 0, 4.0, nil, false, nil, nil)
            return false
        end
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsSlab.new.registerWithApplication