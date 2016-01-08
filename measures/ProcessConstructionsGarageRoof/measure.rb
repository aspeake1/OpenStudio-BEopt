#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessConstructionsGarageRoof < OpenStudio::Ruleset::ModelUserScript

  class GrgRoofStudandAir
    def initialize
    end
    attr_accessor(:grg_roof_thickness, :grg_roof_conductivity, :grg_roof_density, :grg_roof_spec_heat)
  end

  class RadiantBarrier
    def initialize(hasRadiantBarrier)
      @hasRadiantBarrier = hasRadiantBarrier
    end

    def HasRadiantBarrier
      return @hasRadiantBarrier
    end
  end

  class RoofingMaterial
    def initialize(roofMatEmissivity, roofMatAbsorptivity)
      @roofMatEmissivity = roofMatEmissivity
      @roofMatAbsorptivity = roofMatAbsorptivity
    end

    def RoofMatEmissivity
      return @roofMatEmissivity
    end

    def RoofMatAbsorptivity
      return @roofMatAbsorptivity
    end
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Assign Residential Garage Roof Construction"
  end
  
  def description
    return "This measure assigns a construction to the garage roof."
  end
  
  def modeler_description
    return "Calculates material layer properties of uninsulated, unfinished, stud and air constructions for the garage roof. Finds surfaces adjacent to the garage and sets applicable constructions."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a bool argument for radiant barrier of roof cavity
    userdefined_hasradiantbarrier = OpenStudio::Ruleset::OSArgument::makeBoolArgument("userdefinedhasradiantbarrier", false)
    userdefined_hasradiantbarrier.setDisplayName("Has Radiant Barrier")
	userdefined_hasradiantbarrier.setDescription("Layers of reflective material used to reduce heat transfer between the attic roof and the ceiling insulation and ductwork (if present).")
	userdefined_hasradiantbarrier.setDefaultValue(false)
    args << userdefined_hasradiantbarrier

    #make a double argument for roofing material thermal absorptance of unfinished attic
    userdefined_roofmatthermalabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatthermalabs", false)
    userdefined_roofmatthermalabs.setDisplayName("Roof Material: Emissivity")
	userdefined_roofmatthermalabs.setDescription("Infrared emissivity of the outside surface of the roof.")
    userdefined_roofmatthermalabs.setDefaultValue(0.91)
    args << userdefined_roofmatthermalabs

    #make a double argument for roofing material solar/visible absorptance of unfinished attic
    userdefined_roofmatabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatabs", false)
    userdefined_roofmatabs.setDisplayName("Roof Material: Absorptivity")
	userdefined_roofmatabs.setDescription("The solar radiation absorptance of the outside roof surface, specified as a value between 0 and 1.")
    userdefined_roofmatabs.setDefaultValue(0.85)
    args << userdefined_roofmatabs

    #make a choice argument for garage space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.GarageSpaceType)
        space_type_args << Constants.GarageSpaceType
    end
    garage_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("garage_space_type", space_type_args, true)
    garage_space_type.setDisplayName("Garage space type")
    garage_space_type.setDescription("Select the garage space type")
    garage_space_type.setDefaultValue(Constants.GarageSpaceType)
    args << garage_space_type

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Space Type
	garage_space_type_r = runner.getStringArgumentValue("garage_space_type",user_arguments)
    garage_space_type = HelperMethods.get_space_type_from_string(model, garage_space_type_r, runner, false)
    if garage_space_type.nil?
        # If the building has no garage, no constructions are assigned and we continue by returning True
        return true
    end

    # Radiant Barrier
    userdefined_hasradiantbarrier = runner.getBoolArgumentValue("userdefinedhasradiantbarrier",user_arguments)

    # Exterior Finish
    userdefined_roofmatthermalabs = runner.getDoubleArgumentValue("userdefinedroofmatthermalabs",user_arguments)
    userdefined_roofmatabs = runner.getDoubleArgumentValue("userdefinedroofmatabs",user_arguments)

    # Radiant Barrier
    hasRadiantBarrier = userdefined_hasradiantbarrier

    # Roofing Material
    roofMatEmissivity = userdefined_roofmatthermalabs
    roofMatAbsorptivity = userdefined_roofmatabs

    # Create the material class instances
    gsa = GrgRoofStudandAir.new
    radiant_barrier = RadiantBarrier.new(hasRadiantBarrier)
    roofing_material = RoofingMaterial.new(roofMatEmissivity, roofMatAbsorptivity)

    # Create the sim object
    sim = Sim.new(model, runner)

    # Process the slab
    gsa = sim._processConstructionsGarageRoof(gsa)

    # RoofingMaterial
    mat_roof_mat = get_mat_roofing_mat(roofing_material)
    roofmat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    roofmat.setName("RoofingMaterial")
    roofmat.setRoughness("Rough")
    roofmat.setThickness(OpenStudio::convert(mat_roof_mat.thick,"ft","m").get)
    roofmat.setConductivity(OpenStudio::convert(mat_roof_mat.k,"Btu/hr*ft*R","W/m*K").get)
    roofmat.setDensity(OpenStudio::convert(mat_roof_mat.rho,"lb/ft^3","kg/m^3").get)
    roofmat.setSpecificHeat(OpenStudio::convert(mat_roof_mat.Cp,"Btu/lb*R","J/kg*K").get)
    roofmat.setThermalAbsorptance(mat_roof_mat.TAbs)
    roofmat.setSolarAbsorptance(mat_roof_mat.SAbs)
    roofmat.setVisibleAbsorptance(mat_roof_mat.VAbs)

    # Plywood-3_4in
    ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_4.setName("Plywood-3_4in")
    ply3_4.setRoughness("Rough")
    ply3_4.setThickness(OpenStudio::convert(get_mat_plywood3_4in(get_mat_wood).thick,"ft","m").get)
    ply3_4.setConductivity(OpenStudio::convert(get_mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_4.setDensity(OpenStudio::convert(get_mat_wood.rho,"lb/ft^3","kg/m^3").get)
    ply3_4.setSpecificHeat(OpenStudio::convert(get_mat_wood.Cp,"Btu/lb*R","J/kg*K").get)

    # RadiantBarrier
    mat_radiant_barrier = get_mat_radiant_barrier
    radbar = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    radbar.setName("RadiantBarrier")
    radbar.setRoughness("Rough")
    radbar.setThickness(OpenStudio::convert(mat_radiant_barrier.thick,"ft","m").get)
    radbar.setConductivity(OpenStudio::convert(mat_radiant_barrier.k,"Btu/hr*ft*R","W/m*K").get)
    radbar.setDensity(OpenStudio::convert(mat_radiant_barrier.rho,"lb/ft^3","kg/m^3").get)
    radbar.setSpecificHeat(OpenStudio::convert(mat_radiant_barrier.Cp,"Btu/lb*R","J/kg*K").get)
    radbar.setThermalAbsorptance(mat_radiant_barrier.TAbs)
    radbar.setSolarAbsorptance(mat_radiant_barrier.SAbs)
    radbar.setVisibleAbsorptance(mat_radiant_barrier.VAbs)

    # GrgRoofStudandAir
    gsaThickness = gsa.grg_roof_thickness
    gsaConductivity = gsa.grg_roof_conductivity
    gsaDensity = gsa.grg_roof_density
    gsaSpecificHeat = gsa.grg_roof_spec_heat
    gsa = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    gsa.setName("GrgRoofStudandAir")
    gsa.setRoughness("Rough")
    gsa.setThickness(OpenStudio::convert(gsaThickness,"ft","m").get)
    gsa.setConductivity(OpenStudio::convert(gsaConductivity,"Btu/hr*ft*R","W/m*K").get)
    gsa.setDensity(OpenStudio::convert(gsaDensity,"lb/ft^3","kg/m^3").get)
    gsa.setSpecificHeat(OpenStudio::convert(gsaSpecificHeat,"Btu/lb*R","J/kg*K").get)

    # UnfinUninsExtGrgRoof
	materials = []
    materials << roofmat
    materials << ply3_4
    materials << gsa
    if radiant_barrier.HasRadiantBarrier
      materials << radbar
    end
    unfinuninsextgrgroof = OpenStudio::Model::Construction.new(materials)
    unfinuninsextgrgroof.setName("UnfinUninsExtGrgRoof")	

	garage_space_type.spaces.each do |garage_space|
	  garage_space.surfaces.each do |garage_surface|
		next unless garage_surface.surfaceType.downcase == "roofceiling" and garage_surface.outsideBoundaryCondition.downcase == "outdoors"
		garage_surface.setConstruction(unfinuninsextgrgroof)
		runner.registerInfo("Surface '#{garage_surface.name}', of Space Type '#{garage_space_type_r}' and with Surface Type '#{garage_surface.surfaceType}' and Outside Boundary Condition '#{garage_surface.outsideBoundaryCondition}', was assigned Construction '#{unfinuninsextgrgroof.name}'")
	  end	
	end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsGarageRoof.new.registerWithApplication