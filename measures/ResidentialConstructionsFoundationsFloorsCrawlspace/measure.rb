#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/kiva"

#start the measure
class ProcessConstructionsFoundationsFloorsCrawlspace < OpenStudio::Measure::ModelMeasure
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Foundations/Floors - Crawlspace Constructions"
  end
  
  def description
    return "This measure assigns constructions to the crawlspace ceilings, walls, and floors.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of constructions for: 1) ceilings above below-grade unfinished space, 2) walls between below-grade unfinished space and ground, and 3) floors below below-grade unfinished space."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for crawlspace ceilings, walls, and floors
    wall_surfaces, floor_surfaces, ceiling_surfaces, spaces = get_crawlspace_surfaces(model)
    surfaces_args = OpenStudio::StringVector.new
    surfaces_args << Constants.Auto
    (ceiling_surfaces + wall_surfaces).each do |surface|
      surfaces_args << surface.name.to_s
    end
    surface = OpenStudio::Measure::OSArgument::makeChoiceArgument("surface", surfaces_args, false)
    surface.setDisplayName("Surface(s)")
    surface.setDescription("Select the surface(s) to assign constructions.")
    surface.setDefaultValue(Constants.Auto)
    args << surface
    
    #make a double argument for wall continuous insulation R-value
    wall_rigid_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_rigid_r", true)
    wall_rigid_r.setDisplayName("Wall Continuous Insulation Nominal R-value")
    wall_rigid_r.setUnits("hr-ft^2-R/Btu")
    wall_rigid_r.setDescription("The R-value of the continuous insulation.")
    wall_rigid_r.setDefaultValue(10.0)
    args << wall_rigid_r

    #make a double argument for wall continuous insulation thickness
    wall_rigid_thick_in = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_rigid_thick_in", true)
    wall_rigid_thick_in.setDisplayName("Wall Continuous Insulation Thickness")
    wall_rigid_thick_in.setUnits("in")
    wall_rigid_thick_in.setDescription("The thickness of the continuous insulation.")
    wall_rigid_thick_in.setDefaultValue(2.0)
    args << wall_rigid_thick_in

    #make a double argument for ceiling cavity R-value
    ceil_cavity_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("ceil_cavity_r", true)
    ceil_cavity_r.setDisplayName("Ceiling Cavity Insulation Nominal R-value")
    ceil_cavity_r.setUnits("h-ft^2-R/Btu")
    ceil_cavity_r.setDescription("Refers to the R-value of the cavity insulation and not the overall R-value of the assembly.")
    ceil_cavity_r.setDefaultValue(0)
    args << ceil_cavity_r

    #make a choice argument for ceiling cavity insulation installation grade
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"
    ceil_cavity_grade = OpenStudio::Measure::OSArgument::makeChoiceArgument("ceil_cavity_grade", installgrade_display_names, true)
    ceil_cavity_grade.setDisplayName("Ceiling Cavity Install Grade")
    ceil_cavity_grade.setDescription("Installation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    ceil_cavity_grade.setDefaultValue("I")
    args << ceil_cavity_grade

    #make a choice argument for ceiling framing factor
    ceil_ff = OpenStudio::Measure::OSArgument::makeDoubleArgument("ceil_ff", true)
    ceil_ff.setDisplayName("Ceiling Framing Factor")
    ceil_ff.setUnits("frac")
    ceil_ff.setDescription("Fraction of ceiling that is framing.")
    ceil_ff.setDefaultValue(0.13)
    args << ceil_ff

    #make a choice argument for ceiling joist height
    ceil_joist_height = OpenStudio::Measure::OSArgument::makeDoubleArgument("ceil_joist_height", true)
    ceil_joist_height.setDisplayName("Ceiling Joist Height")
    ceil_joist_height.setUnits("in")
    ceil_joist_height.setDescription("Height of the joist member.")
    ceil_joist_height.setDefaultValue(9.25)
    args << ceil_joist_height    
    
    #make a string argument for exposed perimeter
    exposed_perim = OpenStudio::Measure::OSArgument::makeStringArgument("exposed_perim", true)
    exposed_perim.setDisplayName("Exposed Perimeter")
    exposed_perim.setUnits("ft")
    exposed_perim.setDescription("Total length of the crawlspace's perimeter that is on the exterior of the building's footprint.")
    exposed_perim.setDefaultValue(Constants.Auto)
    args << exposed_perim    
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    surface_s = runner.getOptionalStringArgumentValue("surface",user_arguments)
    if not surface_s.is_initialized
      surface_s = Constants.Auto
    else
      surface_s = surface_s.get
    end
    
    wall_surfaces, floor_surfaces, ceiling_surfaces, spaces = get_crawlspace_surfaces(model)

    unless surface_s == Constants.Auto
      ceiling_surfaces.delete_if { |surface| surface.name.to_s != surface_s }
      wall_surfaces.delete_if { |surface| surface.name.to_s != surface_s }
    end
    
    # Continue if no applicable surfaces
    if wall_surfaces.empty? and floor_surfaces.empty? and ceiling_surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end    
    
    # Get Inputs
    crawlWallContInsRvalueNominal = runner.getDoubleArgumentValue("wall_rigid_r",user_arguments)
    crawlWallContInsThickness = runner.getDoubleArgumentValue("wall_rigid_thick_in",user_arguments)
    crawlCeilingCavityInsRvalueNominal = runner.getDoubleArgumentValue("ceil_cavity_r",user_arguments)
    crawlCeilingInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("ceil_cavity_grade",user_arguments)]
    crawlCeilingFramingFactor = runner.getDoubleArgumentValue("ceil_ff",user_arguments)
    crawlCeilingJoistHeight = runner.getDoubleArgumentValue("ceil_joist_height",user_arguments)
    exposed_perim = runner.getStringArgumentValue("exposed_perim",user_arguments)
    
    # Validate Inputs
    if crawlWallContInsRvalueNominal < 0.0
        runner.registerError("Wall Continuous Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if crawlWallContInsThickness < 0.0
        runner.registerError("Wall Continuous Insulation Thickness must be greater than or equal to 0.")
        return false
    end
    if crawlCeilingCavityInsRvalueNominal < 0.0
        runner.registerError("Ceiling Cavity Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if crawlCeilingFramingFactor < 0.0 or crawlCeilingFramingFactor >= 1.0
        runner.registerError("Ceiling Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if crawlCeilingJoistHeight <= 0.0
        runner.registerError("Ceiling Joist Height must be greater than 0.")
        return false
    end    
    if exposed_perim != Constants.Auto and (not MathTools.valid_float?(exposed_perim) or exposed_perim.to_f < 0)
        runner.registerError("Exposed Perimeter must be #{Constants.Auto} or a number greater than or equal to 0.")
        return false
    end
    if exposed_perim != Constants.Auto and Geometry.get_building_units(model, runner) > 1
        runner.registerError("Exposed Perimeter must be #{Constants.Auto} for a multifamily building.")
        return false
    end
    
    # Create Kiva foundation
    crawl_height = Geometry.spaces_avg_height(spaces)
    foundation = Kiva.create_crawl_or_basement_foundation(model, 0, 0, crawlWallContInsRvalueNominal, crawl_height)
    
    # -------------------------------
    # Process the crawl walls
    # -------------------------------
    
    if not wall_surfaces.empty?
        # Define construction
        cs_wall = Construction.new([1.0])
        cs_wall.add_layer(Material.Concrete8in, true)
        
        # Create and assign construction to surfaces
        if not cs_wall.create_and_assign_constructions(wall_surfaces, runner, model, name="GrndInsUnfinCSWall")
            return false
        end
        
        # Assign surfaces to Kiva foundation
        wall_surfaces.each do |wall_surface|
            wall_surface.setAdjacentFoundation(foundation)
        end
    end
    
    # -------------------------------
    # Process the crawl floor
    # -------------------------------
    
    if not floor_surfaces.empty? and not wall_surfaces.empty?
        # Define construction
        cs_floor = Construction.new([1.0])
        cs_floor.add_layer(Material.Concrete4in, true)
        
        # Create and assign construction to surfaces
        if not cs_floor.create_and_assign_constructions(floor_surfaces, runner, model, name="GrndUninsUnfinCSFloor")
            return false
        end
        
        # Assign surfaces to Kiva foundation
        floor_surfaces.each do |floor_surface|
            # Exposed perimeter
            if exposed_perim == Constants.Auto
                surfaceExtPerimeter = Geometry.calculate_exposed_perimeter(model, [floor_surface], has_foundation_walls=true)
            else
                surfaceExtPerimeter = exposed_perim.to_f
            end
            
            if surfaceExtPerimeter <= 0
              runner.registerError("Calculated an exposed perimeter <= 0 for surface '#{floor_surface.name.to_s}'.")
              return false
            end
            
            floor_surface.setAdjacentFoundation(foundation)
            floor_surface.createSurfacePropertyExposedFoundationPerimeter("TotalExposedPerimeter", UnitConversions.convert(surfaceExtPerimeter,"ft","m"))
        end
    end

    # -------------------------------
    # Process the crawl ceiling
    # -------------------------------
    
    if not ceiling_surfaces.empty?
        # Define materials
        mat_2x = Material.Stud2x(crawlCeilingJoistHeight)
        if crawlCeilingCavityInsRvalueNominal == 0
            mat_cavity = Material.AirCavityOpen(thick_in=mat_2x.thick_in)
        else    
            mat_cavity = Material.new(name=nil, thick_in=mat_2x.thick_in, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=mat_2x.thick_in / crawlCeilingCavityInsRvalueNominal)
        end
        mat_framing = Material.new(name=nil, thick_in=mat_2x.thick_in, mat_base=BaseMaterial.Wood)
        mat_gap = Material.AirCavityOpen(mat_2x.thick_in)
        
        # Set paths
        csGapFactor = Construction.get_wall_gap_factor(crawlCeilingInstallGrade, crawlCeilingFramingFactor, crawlCeilingCavityInsRvalueNominal)
        path_fracs = [crawlCeilingFramingFactor, 1 - crawlCeilingFramingFactor - csGapFactor, csGapFactor]
        
        # Define construction
        cs_ceiling = Construction.new(path_fracs)
        cs_ceiling.add_layer(Material.AirFilmFloorReduced, false)
        cs_ceiling.add_layer([mat_framing, mat_cavity, mat_gap], true, "CrawlCeilingIns")
        cs_ceiling.add_layer(Material.DefaultFloorSheathing, false) # sheathing added in separate measure
        cs_ceiling.add_layer(Material.DefaultFloorMass, false) # thermal mass added in separate measure
        cs_ceiling.add_layer(Material.DefaultFloorCovering, false) # floor covering added in separate measure
        cs_ceiling.add_layer(Material.AirFilmFloorReduced, false)

        # Create and assign construction to surfaces
        if not cs_ceiling.create_and_assign_constructions(ceiling_surfaces, runner, model, name="UnfinCSInsFinFloor")
            return false
        end
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end #end the run method

  def get_crawlspace_surfaces(model)
    wall_surfaces = []
    floor_surfaces = []
    ceiling_surfaces = []
    spaces = Geometry.get_crawl_spaces(model.getSpaces)
    spaces.each do |space|
        space.surfaces.each do |surface|
            # Wall between below-grade unfinished space and ground
            if surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "foundation"
                wall_surfaces << surface
            end
            # Floor below below-grade unfinished space
            if surface.surfaceType.downcase == "floor" and surface.outsideBoundaryCondition.downcase == "foundation"
                floor_surfaces << surface
            end
            # Ceiling above below-grade unfinished space and below finished space
            if surface.surfaceType.downcase == "roofceiling" and surface.adjacentSurface.is_initialized and surface.adjacentSurface.get.space.is_initialized
                adjacent_space = surface.adjacentSurface.get.space.get
                if Geometry.space_is_finished(adjacent_space)
                    ceiling_surfaces << surface
                end
            end
        end
    end
    return wall_surfaces, floor_surfaces, ceiling_surfaces, spaces
  end
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsFoundationsFloorsCrawlspace.new.registerWithApplication