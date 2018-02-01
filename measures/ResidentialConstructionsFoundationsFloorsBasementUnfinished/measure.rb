#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/kiva"

#start the measure
class ProcessConstructionsFoundationsFloorsBasementUnfinished < OpenStudio::Measure::ModelMeasure
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Foundations/Floors - Unfinished Basement Constructions"
  end
  
  def description
    return "This measure assigns constructions to the unfinished basement ceilings, walls, and floors.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of constructions for: 1) ceilings above below-grade unfinished space, 2) walls between below-grade unfinished space and ground, and 3) floors below below-grade unfinished space."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for wall insulation height
    wall_ins_height = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_ins_height", true)
    wall_ins_height.setDisplayName("Wall Insulation Height")
    wall_ins_height.setUnits("ft")
    wall_ins_height.setDescription("Height of the insulation on the basement wall.")
    wall_ins_height.setDefaultValue(8)
    args << wall_ins_height

    #make a double argument for wall cavity R-value
    wall_cavity_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_cavity_r", true)
    wall_cavity_r.setDisplayName("Wall Cavity Insulation Installed R-value")
    wall_cavity_r.setUnits("h-ft^2-R/Btu")
    wall_cavity_r.setDescription("Refers to the R-value of the cavity insulation as installed and not the overall R-value of the assembly. If batt insulation must be compressed to fit within the cavity (e.g. R19 in a 5.5\" 2x6 cavity), use an R-value that accounts for this effect (see HUD Mobile Home Construction and Safety Standards 3280.509 for reference).")
    wall_cavity_r.setDefaultValue(0)
    args << wall_cavity_r

    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"

    #make a choice argument for wall cavity insulation installation grade
    wall_cavity_grade = OpenStudio::Measure::OSArgument::makeChoiceArgument("wall_cavity_grade", installgrade_display_names, true)
    wall_cavity_grade.setDisplayName("Wall Cavity Install Grade")
    wall_cavity_grade.setDescription("Installation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    wall_cavity_grade.setDefaultValue("I")
    args << wall_cavity_grade

    #make a double argument for wall cavity depth
    wall_cavity_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_cavity_depth", true)
    wall_cavity_depth.setDisplayName("Wall Cavity Depth")
    wall_cavity_depth.setUnits("in")
    wall_cavity_depth.setDescription("Depth of the stud cavity. 3.5\" for 2x4s, 5.5\" for 2x6s, etc.")
    wall_cavity_depth.setDefaultValue(0)
    args << wall_cavity_depth

    #make a bool argument for whether the cavity insulation fills the wall cavity
    wall_cavity_insfills = OpenStudio::Measure::OSArgument::makeBoolArgument("wall_cavity_insfills", true)
    wall_cavity_insfills.setDisplayName("Wall Insulation Fills Cavity")
    wall_cavity_insfills.setDescription("When the insulation does not completely fill the depth of the cavity, air film resistances are added to the insulation R-value.")
    wall_cavity_insfills.setDefaultValue(false)
    args << wall_cavity_insfills

    #make a double argument for wall framing factor
    wall_ff = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_ff", true)
    wall_ff.setDisplayName("Wall Framing Factor")
    wall_ff.setUnits("frac")
    wall_ff.setDescription("The fraction of a basement wall assembly that is comprised of structural framing.")
    wall_ff.setDefaultValue(0)
    args << wall_ff
    
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
    exposed_perim.setDescription("Total length of the basement's perimeter that is on the exterior of the building's footprint.")
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

    ceiling_surfaces, wall_surfaces, floor_surfaces, spaces = get_unfinished_basement_surfaces(model)

    # Continue if no applicable surfaces
    if wall_surfaces.empty? and floor_surfaces.empty? and ceiling_surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end   
    
    # Get Inputs
    ufbsmtWallInsHeight = runner.getDoubleArgumentValue("wall_ins_height",user_arguments)
    ufbsmtWallCavityInsRvalueInstalled = runner.getDoubleArgumentValue("wall_cavity_r",user_arguments)
    ufbsmtWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("wall_cavity_grade",user_arguments)]
    ufbsmtWallCavityDepth = runner.getDoubleArgumentValue("wall_cavity_depth",user_arguments)
    ufbsmtWallCavityInsFillsCavity = runner.getBoolArgumentValue("wall_cavity_insfills",user_arguments)
    ufbsmtWallFramingFactor = runner.getDoubleArgumentValue("wall_ff",user_arguments)
    ufbsmtWallContInsRvalue = runner.getDoubleArgumentValue("wall_rigid_r",user_arguments)
    ufbsmtWallContInsThickness = runner.getDoubleArgumentValue("wall_rigid_thick_in",user_arguments)
    ufbsmtCeilingCavityInsRvalueNominal = runner.getDoubleArgumentValue("ceil_cavity_r",user_arguments)
    ufbsmtCeilingInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("ceil_cavity_grade",user_arguments)]
    ufbsmtCeilingFramingFactor = runner.getDoubleArgumentValue("ceil_ff",user_arguments)
    ufbsmtCeilingJoistHeight = runner.getDoubleArgumentValue("ceil_joist_height",user_arguments)
    exposed_perim = runner.getStringArgumentValue("exposed_perim",user_arguments)

    # Validate Inputs
    if ufbsmtWallInsHeight < 0.0
        runner.registerError("Wall Insulation Height must be greater than or equal to 0.")
        return false
    end
    if ufbsmtWallCavityInsRvalueInstalled < 0.0
        runner.registerError("Wall Cavity Insulation Installed R-value must be greater than or equal to 0.")
        return false
    end
    if ufbsmtWallCavityDepth < 0.0
        runner.registerError("Wall Cavity Depth must be greater than or equal to 0.")
        return false
    end
    if ufbsmtWallFramingFactor < 0.0 or ufbsmtWallFramingFactor >= 1.0
        runner.registerError("Wall Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if ufbsmtWallContInsRvalue < 0.0
        runner.registerError("Wall Continuous Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if ufbsmtWallContInsThickness < 0.0
        runner.registerError("Wall Continuous Insulation Thickness must be greater than or equal to 0.")
        return false
    end
    if ufbsmtCeilingCavityInsRvalueNominal < 0.0
        runner.registerError("Ceiling Cavity Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if ufbsmtCeilingFramingFactor < 0.0 or ufbsmtCeilingFramingFactor >= 1.0
        runner.registerError("Ceiling Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if ufbsmtCeilingJoistHeight <= 0.0
        runner.registerError("Ceiling Joist Height must be greater than 0.")
        return false
    end
    if exposed_perim != Constants.Auto and (not MathTools.valid_float?(exposed_perim) or exposed_perim.to_f < 0)
        runner.registerError("Exposed Perimeter must be #{Constants.Auto} or a number greater than or equal to 0.")
        return false
    end
    if exposed_perim != Constants.Auto and Geometry.get_building_units(model, runner).size > 1
        runner.registerError("Exposed Perimeter must be #{Constants.Auto} for a multifamily building.")
        return false
    end
    
    # Calculate interior wall R-value
    int_wall_Rvalue = calc_wall_r_value(runner, ufbsmtWallCavityDepth, ufbsmtWallCavityInsRvalueInstalled, 
                                                ufbsmtWallCavityInsFillsCavity, ufbsmtWallFramingFactor, 
                                                ufbsmtWallInstallGrade, ufbsmtWallContInsRvalue, 
                                                ufbsmtWallContInsThickness)
    if int_wall_Rvalue.nil?
        return false
    end
    
    # Create Kiva foundation
    basement_height = Geometry.spaces_avg_height(spaces)
    foundation = Kiva.create_crawl_or_basement_foundation(model, int_wall_Rvalue, basement_height,
                                                          ufbsmtWallContInsRvalue, ufbsmtWallInsHeight)
    
    # -------------------------------
    # Process the basement walls
    # -------------------------------
    
    if not wall_surfaces.empty?
        # Define construction
        ufbsmt_wall = Construction.new([1])
        ufbsmt_wall.add_layer(Material.Concrete8in, true)

        # Create and assign construction to surfaces
        if not ufbsmt_wall.create_and_assign_constructions(wall_surfaces, runner, model, name="GrndInsUnfinBWall")
            return false
        end
        
        # Assign surfaces to Kiva foundation
        wall_surfaces.each do |wall_surface|
            wall_surface.setAdjacentFoundation(foundation)
        end
    end

    # -------------------------------
    # Process the basement floor
    # -------------------------------

    if not floor_surfaces.empty? and not wall_surfaces.empty?
        # Define construction
        ub_floor = Construction.new([1.0])
        ub_floor.add_layer(Material.Concrete4in, true)
        
        # Create and assign construction to surfaces
        if not ub_floor.create_and_assign_constructions(floor_surfaces, runner, model, name="GrndUninsUnfinBFloor")
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
    # Process the basement ceiling
    # -------------------------------
    
    if not ceiling_surfaces.empty?
        # Define materials
        mat_2x = Material.Stud2x(ufbsmtCeilingJoistHeight)
        if ufbsmtCeilingCavityInsRvalueNominal == 0
            mat_cavity = Material.AirCavityOpen(mat_2x.thick_in)
        else    
            mat_cavity = Material.new(name=nil, thick_in=mat_2x.thick_in, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=mat_2x.thick_in / ufbsmtCeilingCavityInsRvalueNominal)
        end
        mat_framing = Material.new(name=nil, thick_in=mat_2x.thick_in, mat_base=BaseMaterial.Wood)
        mat_gap = Material.AirCavityOpen(ufbsmtCeilingJoistHeight)
        
        # Set paths
        gapFactor = Construction.get_wall_gap_factor(ufbsmtCeilingInstallGrade, ufbsmtCeilingFramingFactor, ufbsmtCeilingCavityInsRvalueNominal)
        path_fracs = [ufbsmtCeilingFramingFactor, 1 - ufbsmtCeilingFramingFactor - gapFactor, gapFactor]
        
        # Define construction
        ub_ceiling = Construction.new(path_fracs)
        ub_ceiling.add_layer(Material.AirFilmFloorReduced, false)
        ub_ceiling.add_layer([mat_framing, mat_cavity, mat_gap], true, "UFBsmtCeilingIns")
        ub_ceiling.add_layer(Material.DefaultFloorSheathing, false) # sheathing added in separate measure
        ub_ceiling.add_layer(Material.DefaultFloorMass, false) # thermal mass added in separate measure
        ub_ceiling.add_layer(Material.DefaultFloorCovering, false) # floor covering added in separate measure
        ub_ceiling.add_layer(Material.AirFilmFloorReduced, false)
        
        # Create and assign construction to surfaces
        if not ub_ceiling.create_and_assign_constructions(ceiling_surfaces, runner, model, name="UnfinBInsFinFloor")
            return false
        end
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true
 
  end #end the run method
  
  def get_unfinished_basement_surfaces(model)
    wall_surfaces = []
    floor_surfaces = []
    ceiling_surfaces = []
    spaces = Geometry.get_unfinished_basement_spaces(model.getSpaces)
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
    return ceiling_surfaces, wall_surfaces, floor_surfaces, spaces
  end
  
  def calc_wall_r_value(runner, cavityDepth, cavityInsRvalue, cavityInsFillsCavity,
                        framingFactor, installGrade, contInsRvalue, contInsThickness)
    # Define materials
    mat_framing = nil
    mat_cavity = nil
    mat_gap = nil
    mat_rigid = nil
    if cavityDepth > 0
        if cavityInsRvalue > 0
            if cavityInsFillsCavity
                # Insulation
                mat_cavity = Material.new(name=nil, thick_in=cavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavityDepth / cavityInsRvalue)
            else
                # Insulation plus air gap when insulation thickness < cavity depth
                mat_cavity = Material.new(name=nil, thick_in=cavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavityDepth / (cavityInsRvalue + Gas.AirGapRvalue))
            end
        else
            # Empty cavity
            mat_cavity = Material.AirCavityClosed(cavityDepth)
        end
        mat_framing = Material.new(name=nil, thick_in=cavityDepth, mat_base=BaseMaterial.Wood)
        mat_gap = Material.AirCavityClosed(cavityDepth)
    end
    if contInsRvalue > 0 and contInsThickness > 0
        mat_rigid = Material.new(name=nil, thick_in=contInsThickness, mat_base=BaseMaterial.InsulationRigid, k_in=contInsThickness / contInsRvalue)
    end
    
    # Set paths
    gapFactor = Construction.get_wall_gap_factor(installGrade, framingFactor, cavityInsRvalue)
    path_fracs = [framingFactor, 1 - framingFactor - gapFactor, gapFactor]

    # Define construction (only used to calculate assembly R-value)
    ufbsmt_wall = Construction.new(path_fracs)
    if not mat_framing.nil? and not mat_cavity.nil? and not mat_gap.nil?
        ufbsmt_wall.add_layer(Material.DefaultWallMass, false)
        ufbsmt_wall.add_layer(Material.AirFilmVertical, false)
        ufbsmt_wall.add_layer([mat_framing, mat_cavity, mat_gap], false)
    end
    if not mat_rigid.nil?
        ufbsmt_wall.add_layer(mat_rigid, false)
    end

    return ufbsmt_wall.assembly_rvalue(runner) - contInsRvalue
  end
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsFoundationsFloorsBasementUnfinished.new.registerWithApplication