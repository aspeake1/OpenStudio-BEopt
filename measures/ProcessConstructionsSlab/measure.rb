#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsSlab < OpenStudio::Ruleset::ModelUserScript
  
	class Slab
		def initialize(slabThickness, slabConductivity, slabDensity, slabSpecificHeat, slabPerimeterRvalue, slabPerimeterInsWidth, slabExtRvalue, slabExtInsDepth, slabGapRvalue, slabWholeInsRvalue)
			@slabThickness = slabThickness
			@slabConductivity = slabConductivity
			@slabDensity = slabDensity
			@slabSpecificHeat = slabSpecificHeat
			@slabPerimeterRvalue = slabPerimeterRvalue
			@slabPerimeterInsWidth = slabPerimeterInsWidth
			@slabExtRvalue = slabExtRvalue
			@slabExtInsDepth = slabExtInsDepth
			@slabGapRvalue = slabGapRvalue
			@slabWholeInsRvalue = slabWholeInsRvalue
		end
		
		attr_accessor(:SlabHasWholeInsulation, :SlabCarpetPerimeterConduction, :SlabBarePerimeterConduction, :ext_perimeter, :area, :slab_carp_ext_perimeter, :bare_ext_perimeter, :area_perimeter_ratio, :fictitious_carpet_Rvalue, :carp_slab_factor, :fictitious_bare_Rvalue, :bare_slab_factor, :fictitious_slab_Rvalue, :slab_factor)
		
		def SlabMassThickness
			return @slabThickness
		end
		
		def SlabMassConductivity
			return @slabConductivity
		end
		
		def SlabMassDensity
			return @slabDensity
		end

		def SlabMassSpecificHeat
			return @slabSpecificHeat
		end

		def SlabPerimeterRvalue
			return @slabPerimeterRvalue
		end

		def SlabPerimeterInsWidth
			return @slabPerimeterInsWidth
		end		
		
		def SlabExtRvalue
			return @slabExtRvalue
		end

		def SlabExtInsDepth
			return @slabExtInsDepth
		end
		
		def SlabGapRvalue
			return @slabGapRvalue
		end
		
		def SlabWholeInsRvalue
			return @slabWholeInsRvalue
		end
	end  
	
	class Carpet
		def initialize(carpetFloorFraction, carpetPadRValue)
			@carpetFloorFraction = carpetFloorFraction
			@carpetPadRValue = carpetPadRValue
		end
		
		attr_accessor(:floor_bare_fraction)
		
		def CarpetFloorFraction
			return @carpetFloorFraction
		end
		
		def CarpetPadRValue
			return @carpetPadRValue
		end
	end
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Assign Residential Slab Construction"
  end
  
  def description
    return "This measure assigns a construction to the living space slab."
  end
  
  def modeler_description
    return "Calculates material layer properties of slab constructions for the living space floor. Finds surfaces adjacent to the living space and sets applicable constructions."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

	#make a choice argument for model objects
	slabins_display_names = OpenStudio::StringVector.new
	slabins_display_names << "Uninsulated"
	slabins_display_names << "Perimeter"
	slabins_display_names << "Exterior"
	slabins_display_names << "Whole Slab"
	
	#make a choice argument for slab insulation type
	selected_slabins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedslabins", slabins_display_names, true)
	selected_slabins.setDisplayName("Slab: Insulation Type")
	selected_slabins.setDescription("The type of insulation.")
	selected_slabins.setDefaultValue("Uninsulated")
	args << selected_slabins

	#make a double argument for slab perimeter / exterior insulation R-value
	userdefined_slabperiextr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabperiextr", false)
	userdefined_slabperiextr.setDisplayName("Slab: Perimeter/Exterior Insulation Nominal R-value")
	userdefined_slabperiextr.setUnits("hr-ft^2-R/Btu")
	userdefined_slabperiextr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_slabperiextr.setDefaultValue(0.0)
	args << userdefined_slabperiextr
	
	#make a double argument for slab perimeter insulation width / exterior insulation depth
	userdefined_slabperiextwidthdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabperiextwidthdepth", false)
	userdefined_slabperiextwidthdepth.setDisplayName("Slab: Perimeter/Exterior Insulation Width/Depth")
	userdefined_slabperiextwidthdepth.setUnits("ft")
	userdefined_slabperiextwidthdepth.setDescription("The width or depth of the perimeter or exterior insulation.")
	userdefined_slabperiextwidthdepth.setDefaultValue(0.0)
	args << userdefined_slabperiextwidthdepth
	
	#make a double argument for slab perimeter gap R-value
	userdefined_slabgapr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabgapr", false)
	userdefined_slabgapr.setDisplayName("Slab: Gap Insulation Nominal R-value")
	userdefined_slabgapr.setUnits("hr-ft^2-R/Btu")
	userdefined_slabgapr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_slabgapr.setDefaultValue(0.0)
	args << userdefined_slabgapr

	# Whole Slab Insulation
	#make a double argument for whole slab insulation R-value
	userdefined_slabwholer = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabwholer", false)
	userdefined_slabwholer.setDisplayName("Slab: Whole Slab Insulation Nominal R-value")
	userdefined_slabwholer.setUnits("hr-ft^2-R/Btu")
	userdefined_slabwholer.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_slabwholer.setDefaultValue(0.0)
	args << userdefined_slabwholer
	
    #make a double argument for carpet pad R-value
    userdefined_carpetr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetr", false)
    userdefined_carpetr.setDisplayName("Carpet: Carpet Pad R-value")
	userdefined_carpetr.setUnits("hr-ft^2-R/Btu")
	userdefined_carpetr.setDescription("The combined R-value of the carpet and the pad.")
    userdefined_carpetr.setDefaultValue(2.08)
    args << userdefined_carpetr

    #make a double argument for carpet floor fraction
    userdefined_carpetfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetfrac", false)
    userdefined_carpetfrac.setDisplayName("Carpet: Floor Carpet Fraction")
	userdefined_carpetfrac.setUnits("frac")
	userdefined_carpetfrac.setDescription("Defines the fraction of a floor which is covered by carpet.")
    userdefined_carpetfrac.setDefaultValue(0.8)
    args << userdefined_carpetfrac

    # Geometry
    userdefinedslabarea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabarea", true)
    userdefinedslabarea.setDisplayName("Slab Area")
	userdefinedslabarea.setUnits("ft^2")
	userdefinedslabarea.setDescription("The area of the slab.")
    userdefinedslabarea.setDefaultValue(1200.0)
    args << userdefinedslabarea

    userdefinedslabextperim = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabextperim", true)
    userdefinedslabextperim.setDisplayName("Slab Perimeter")
	userdefinedslabextperim.setUnits("ft")
	userdefinedslabextperim.setDescription("The perimeter of the slab.")
    userdefinedslabextperim.setDefaultValue(140.0)
    args << userdefinedslabextperim
	
    #make a choice argument for living space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.LivingSpaceType)
        space_type_args << Constants.LivingSpaceType
    end
    living_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_space_type", space_type_args, true)
    living_space_type.setDisplayName("Living space type")
    living_space_type.setDescription("Select the living space type")
    living_space_type.setDefaultValue(Constants.LivingSpaceType)
    args << living_space_type

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	slabPerimeterRvalue = 0
	slabPerimeterInsWidth = nil
	slabExtRvalue = 0
	slabExistInsDepth = nil
	slabGapRvalue = nil
	slabWholeInsRvalue = 0
	carpetPadRValue = 0

    # Space Type
	living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end

	# Slab Insulation
	selected_slabins = runner.getStringArgumentValue("selectedslabins",user_arguments)
	
	# Perimeter / Exterior Insulation
	if ["Perimeter", "Exterior"].include? selected_slabins.to_s
		userdefined_slabperiextr = runner.getDoubleArgumentValue("userdefinedslabperiextr",user_arguments)
		userdefined_slabperiextwidthdepth = runner.getDoubleArgumentValue("userdefinedslabperiextwidthdepth",user_arguments)
	end
		
	# Gap
	if ["Perimeter", "Whole Slab"].include? selected_slabins.to_s
		userdefined_slabgapr = runner.getDoubleArgumentValue("userdefinedslabgapr",user_arguments)
	end
	
	# Whole Slab Insulation
	if selected_slabins.to_s == "Whole Slab"
		userdefined_slabwholer = runner.getDoubleArgumentValue("userdefinedslabwholer",user_arguments)
	end
	
	# Carpet
	userdefined_carpetr = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
	userdefined_carpetfrac = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)

	# Insulation
	if selected_slabins == "Perimeter"
		slabPerimeterRvalue = userdefined_slabperiextr
		slabPerimeterInsWidth = userdefined_slabperiextwidthdepth
	elsif selected_slabins == "Exterior"
		slabExtRvalue = userdefined_slabperiextr
		slabExtInsDepth = userdefined_slabperiextwidthdepth
	elsif selected_slabins == "Whole Slab"
		slabWholeInsRvalue = userdefined_slabwholer	
	end

	# Gap
	if ["Perimeter", "Whole Slab"].include? selected_slabins.to_s
		slabGapRvalue = userdefined_slabgapr
	end
	
	# Carpet
	carpetPadRValue = userdefined_carpetr
	carpetFloorFraction = userdefined_carpetfrac

	# Create the material class instances
	slabThickness = 4.0
	slabConductivity = 9.1
	slabDensity = 140.0
	slabSpecificHeat = 0.2
	slab = Slab.new(slabThickness, slabConductivity, slabDensity, slabSpecificHeat, slabPerimeterRvalue, slabPerimeterInsWidth, slabExtRvalue, slabExtInsDepth, slabGapRvalue, slabWholeInsRvalue)
	carpet = Carpet.new(carpetFloorFraction, carpetPadRValue)

	# Create the sim object
	sim = Sim.new(model, runner)

    slab.area = runner.getDoubleArgumentValue("userdefinedslabarea",user_arguments)
    slab.ext_perimeter = runner.getDoubleArgumentValue("userdefinedslabextperim",user_arguments)
	
	# Process the slab
	slab = sim._processConstructionsSlab(slab, carpet)
	
	# Mat-Fic-Slab
	if slab.fictitious_slab_Rvalue > 0
		# Fictitious layer below slab to achieve equivalent R-value. See Winkelmann article.
		mfs = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		mfs.setName("Mat-Fic-Slab")
		mfs.setRoughness("Rough")
		mfs.setThickness(OpenStudio::convert(1.0/12.0,"ft","m").get)
		mfs.setConductivity(OpenStudio::convert(1.0/12.0,"ft","m").get / (0.1761 * slab.fictitious_slab_Rvalue)) # tk used 0.1761 instead of OpenStudio::convert(slab.fictitious_slab_Rvalue,"Btu/hr*ft*R","W/m*K").get because not getting correct value
		mfs.setDensity(OpenStudio::convert(2.5,"lb/ft^3","kg/m^3").get)
		mfs.setSpecificHeat(OpenStudio::convert(0.29,"Btu/lb*R","J/kg*K").get)
	end
	
	# Slab Mass Material
	sm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	sm.setName("SlabMass")
	sm.setRoughness("Rough")
	sm.setThickness(OpenStudio::convert(slab.SlabMassThickness,"in","m").get)
	sm.setConductivity(OpenStudio::convert(OpenStudio::convert(slab.SlabMassConductivity,"in","ft").get,"Btu/hr*ft*R","W/m*K").get)
	sm.setDensity(OpenStudio::convert(slab.SlabMassDensity,"lb/ft^3","kg/m^3").get)
	sm.setSpecificHeat(OpenStudio::convert(slab.SlabMassSpecificHeat,"Btu/lb*R","J/kg*K").get)
	sm.setThermalAbsorptance(0.9)
	sm.setSolarAbsorptance(Constants.DefaultSolarAbsFloor)
	
	if carpet.CarpetFloorFraction > 0
		# Equivalent carpeted/bare material
		scbem = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		scbem.setName("SlabCarpetBareEquivalentMaterial")
		scbem.setRoughness("Rough")
		scbem.setThickness(OpenStudio::convert(1.0/12.0,"ft","m").get)
		scbem.setConductivity(OpenStudio::convert(1.0/12.0,"ft","m").get / (carpet.CarpetPadRValue * carpet.CarpetFloorFraction * slab.slab_factor * 0.1761)) # tk the 0.1761 in place of OpenStudio::convert(1.0,"hr*ft^2*F/Btu","m^2*K/W").get because wasn't returning correct value
		scbem.setDensity(OpenStudio::convert(2.5,"lb/ft^3","kg/m^3").get)
		scbem.setSpecificHeat(OpenStudio::convert(0.29,"Btu/lb*R","J/kg*K").get)
		scbem.setThermalAbsorptance(0.9)
		scbem.setSolarAbsorptance(Constants.DefaultSolarAbsFloor)
	end
		
	# Soil layer for simulated slab, copied from Winkelmann article
	ss = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	ss.setName("SlabSoil-12in")
	ss.setRoughness("Rough")
	ss.setThickness(OpenStudio::convert(slab.slab_factor,"ft","m").get)
	ss.setConductivity(OpenStudio::convert(1.0,"Btu/hr*ft*R","W/m*K").get)
	ss.setDensity(OpenStudio::convert(115.0,"lb/ft^3","kg/m^3").get)
	ss.setSpecificHeat(OpenStudio::convert(0.1,"Btu/lb*R","J/kg*K").get)
	
	# Living Area Slab with Equivalent Carpeted/Bare R-value
	materials = []

	if slab.fictitious_slab_Rvalue > 0
		materials << mfs
	end
    materials << ss
    materials << sm
	if carpet.CarpetFloorFraction > 0
		materials << scbem
	end
	s = OpenStudio::Model::Construction.new(materials)
    s.setName("Slab")
	
	living_space_type.spaces.each do |living_space|
	  living_space.surfaces.each do |living_surface|
	    next unless living_surface.surfaceType.downcase == "floor" and living_surface.outsideBoundaryCondition.downcase == "ground"
	    living_surface.setConstruction(s)
		runner.registerInfo("Surface '#{living_surface.name}', of Space Type '#{living_space_type_r}' and with Surface Type '#{living_surface.surfaceType}' and Outside Boundary Condition '#{living_surface.outsideBoundaryCondition}', was assigned Construction '#{s.name}'")
	  end	
	end

  return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsSlab.new.registerWithApplication