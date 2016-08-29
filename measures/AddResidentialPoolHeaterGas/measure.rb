require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ResidentialPoolHeaterGas < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Set Residential Pool Gas Heater"
  end
  
  def description
    return "Adds (or replaces) a residential pool heater with the specified efficiency and schedule. The pool is assumed to be outdoors. For multifamily buildings, the pool heater is set for all units of the building."
  end
  
  def modeler_description
    return "Since there is no Pool Heater object in OpenStudio/EnergyPlus, we look for a GasEquipment or ElectricEquipment object with the name that denotes it is a residential pool heater. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#make a double argument for Base Energy Use
	base_energy = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("base_energy")
	base_energy.setDisplayName("Base Energy Use")
    base_energy.setUnits("therm/yr")
	base_energy.setDescription("The national average (Building America Benchmark) energy use.")
	base_energy.setDefaultValue(222)
	args << base_energy

	#make a double argument for Energy Multiplier
	mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult")
	mult.setDisplayName("Energy Multiplier")
	mult.setDescription("Sets the annual energy use equal to the base energy use times this multiplier.")
	mult.setDefaultValue(1)
	args << mult
	
    #make a boolean argument for Scale Energy Use
	scale_energy = OpenStudio::Ruleset::OSArgument::makeBoolArgument("scale_energy",true)
	scale_energy.setDisplayName("Scale Energy Use")
	scale_energy.setDescription("If true, scales the energy use relative to a 3-bedroom, 1920 sqft house using the following equation: Fscale = (0.5 + 0.25 x Nbr/3 + 0.25 x FFA/1920) where Nbr is the number of bedrooms and FFA is the finished floor area.")
	scale_energy.setDefaultValue(true)
	args << scale_energy

	#Make a string argument for 24 weekday schedule values
	weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch")
	weekday_sch.setDisplayName("Weekday schedule")
	weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
	weekday_sch.setDefaultValue("0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003")
	args << weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch")
	weekend_sch.setDisplayName("Weekend schedule")
	weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	weekend_sch.setDefaultValue("0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003")
	args << weekend_sch

	#Make a string argument for 12 monthly schedule values
	monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch")
	monthly_sch.setDisplayName("Month schedule")
	monthly_sch.setDescription("Specify the 12-month schedule.")
	monthly_sch.setDefaultValue("1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154")
	args << monthly_sch

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
    #assign the user inputs to variables
    base_energy = runner.getDoubleArgumentValue("base_energy",user_arguments)
	mult = runner.getDoubleArgumentValue("mult",user_arguments)
    scale_energy = runner.getBoolArgumentValue("scale_energy",user_arguments)
	weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
	weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
	monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
    
    #check for valid inputs
    if base_energy < 0
		runner.registerError("Base energy use must be greater than or equal to 0.")
		return false
    end
    if mult < 0
		runner.registerError("Energy multiplier must be greater than or equal to 0.")
		return false
    end
    
    # Get number of units
    num_units = Geometry.get_num_units(model, runner)
    if num_units.nil?
        return false
    end

    #hard coded convective, radiative, latent, and lost fractions
    ph_lat = 0
    ph_rad = 0
    ph_conv = 0
    ph_lost = 1 - ph_lat - ph_rad - ph_conv
    
    tot_ph_ann_g = 0
    info_msgs = []
    sch = nil
    (1..num_units).to_a.each do |unit_num|
    
        # Get unit beds/baths/spaces
        nbeds, nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num, runner)
        if unit_spaces.nil?
            runner.registerError("Could not determine the spaces associated with unit #{unit_num}.")
            return false
        end
        if nbeds.nil? or nbaths.nil?
            runner.registerError("Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
            return false
        end
        
        # Get unit ffa
        ffa = Geometry.get_unit_finished_floor_area(model, unit_spaces, runner)
        if ffa.nil?
            return false
        end
        
        # Get space
        space = Geometry.get_space_from_string(unit_spaces, Constants.Auto)
        next if space.nil?

        unit_obj_name_e = Constants.ObjectNamePoolHeater(Constants.FuelTypeElectric, unit_num)
        unit_obj_name_g = Constants.ObjectNamePoolHeater(Constants.FuelTypeGas, unit_num)
    
        # Remove any existing pool heater
        ph_removed = false
        space.electricEquipment.each do |space_equipment|
            if space_equipment.name.to_s == unit_obj_name_e
                space_equipment.remove
                ph_removed = true
            end
        end
        space.gasEquipment.each do |space_equipment|
            if space_equipment.name.to_s == unit_obj_name_g
                space_equipment.remove
                ph_removed = true
            end
        end
        if ph_removed
            runner.registerInfo("Removed existing pool heater from outside.")
        end
    
        #Calculate annual energy use
        ann_g = base_energy * mult # therm/yr
        
        if scale_energy
            #Scale energy use by num beds and floor area
            constant = ann_g/2
            nbr_coef = ann_g/4/3
            ffa_coef = ann_g/4/1920
            ph_ann_g = constant + nbr_coef * nbeds + ffa_coef * ffa # therm/yr
        else
            ph_ann_g = ann_g # therm/yr
        end

        if ph_ann_g > 0
            
            if sch.nil?
                # Create schedule
                sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNamePoolHeater(Constants.FuelTypeGas) + " schedule", weekday_sch, weekend_sch, monthly_sch)
                if not sch.validated?
                    return false
                end
            end
            
            design_level = sch.calcDesignLevelFromDailyTherm(ph_ann_g/365.0)
            
            #Add gas equipment for the pool heater
            ph_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
            ph = OpenStudio::Model::GasEquipment.new(ph_def)
            ph.setName(unit_obj_name_g)
            ph.setSpace(space)
            ph_def.setName(unit_obj_name_g)
            ph_def.setDesignLevel(design_level)
            ph_def.setFractionRadiant(ph_rad)
            ph_def.setFractionLatent(ph_lat)
            ph_def.setFractionLost(ph_lost)
            sch.setSchedule(ph)
            
            info_msgs << "A pool heater with #{ph_ann_g.round} therms annual energy consumption has been assigned to outside."
            
            tot_ph_ann_g += ph_ann_g
        end
        
    end
    
    # Reporting
    if info_msgs.size > 1
        info_msgs.each do |info_msg|
            runner.registerInfo(info_msg)
        end
        runner.registerFinalCondition("The building has been assigned pool heaters totaling #{tot_ph_ann_g.round} therms annual energy consumption across #{num_units} units.")
    elsif info_msgs.size == 1
        runner.registerFinalCondition(info_msgs[0])
    else
        runner.registerFinalCondition("No pool heater has been assigned.")
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialPoolHeaterGas.new.registerWithApplication