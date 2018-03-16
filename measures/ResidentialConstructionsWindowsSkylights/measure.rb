#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/hvac"
require "#{File.dirname(__FILE__)}/resources/constructions"

#start the measure
class ProcessConstructionsWindowsSkylights < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Window Construction"
  end
  
  def description
    return "This measure assigns a construction to windows. This measure also creates the interior shading schedule, which is based on shade multipliers and the heating and cooling season logic defined in the Building America House Simulation Protocols.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Calculates material layer properties of constructions for windows. Finds sub-surfaces and sets applicable constructions. Using interior heating and cooling shading multipliers and the Building America heating and cooling season logic, creates schedule rulesets for window shade and shading control."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make an argument for entering front window u-factor
    ufactor = OpenStudio::Measure::OSArgument::makeDoubleArgument("ufactor",true)
    ufactor.setDisplayName("Windows: U-Factor")
    ufactor.setUnits("Btu/hr-ft^2-R")
    ufactor.setDescription("The heat transfer coefficient of the windows.")
    ufactor.setDefaultValue(0.37)
    args << ufactor

    #make an argument for entering front window shgc
    shgc = OpenStudio::Measure::OSArgument::makeDoubleArgument("shgc",true)
    shgc.setDisplayName("Windows: SHGC")
    shgc.setDescription("The ratio of solar heat gain through a glazing system compared to that of an unobstructed opening, for windows.")
    shgc.setDefaultValue(0.3)
    args << shgc

    #make an argument for entering heating shade multiplier
    heat_shade_mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("heat_shade_mult",true)
    heat_shade_mult.setDisplayName("Windows: Heating Shade Multiplier")
    heat_shade_mult.setDescription("Interior shading multiplier for heating season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    heat_shade_mult.setDefaultValue(0.7)
    args << heat_shade_mult

    #make an argument for entering cooling shade multiplier
    cool_shade_mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("cool_shade_mult",true)
    cool_shade_mult.setDisplayName("Windows: Cooling Shade Multiplier")
    cool_shade_mult.setDescription("Interior shading multiplier for cooling season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    cool_shade_mult.setDefaultValue(0.7)
    args << cool_shade_mult

    #make an argument for entering front window u-factor
    ufactor = OpenStudio::Measure::OSArgument::makeDoubleArgument("skylight_ufactor",true)
    ufactor.setDisplayName("Skylights: U-Factor")
    ufactor.setUnits("Btu/hr-ft^2-R")
    ufactor.setDescription("The heat transfer coefficient of the skylights.")
    ufactor.setDefaultValue(0.37)
    args << ufactor

    #make an argument for entering front window shgc
    shgc = OpenStudio::Measure::OSArgument::makeDoubleArgument("skylight_shgc",true)
    shgc.setDisplayName("Skylights: SHGC")
    shgc.setDescription("The ratio of solar heat gain through a glazing system compared to that of an unobstructed opening, for skylights.")
    shgc.setDefaultValue(0.3)
    args << shgc

    #make an argument for entering heating shade multiplier
    heat_shade_mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("skylight_heat_shade_mult",true)
    heat_shade_mult.setDisplayName("Skylights: Heating Shade Multiplier")
    heat_shade_mult.setDescription("Interior shading multiplier for heating season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    heat_shade_mult.setDefaultValue(0.7)
    args << heat_shade_mult

    #make an argument for entering cooling shade multiplier
    cool_shade_mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("skylight_cool_shade_mult",true)
    cool_shade_mult.setDisplayName("Skylights: Cooling Shade Multiplier")
    cool_shade_mult.setDescription("Interior shading multiplier for cooling season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    cool_shade_mult.setDefaultValue(0.7)
    args << cool_shade_mult
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    ufactor = runner.getDoubleArgumentValue("ufactor",user_arguments)
    shgc = runner.getDoubleArgumentValue("shgc",user_arguments)
    heat_shade_mult = runner.getDoubleArgumentValue("heat_shade_mult",user_arguments)
    cool_shade_mult = runner.getDoubleArgumentValue("cool_shade_mult",user_arguments)
    skylight_ufactor = runner.getDoubleArgumentValue("skylight_ufactor",user_arguments)
    skylight_shgc = runner.getDoubleArgumentValue("skylight_shgc",user_arguments)
    skylight_heat_shade_mult = runner.getDoubleArgumentValue("skylight_heat_shade_mult",user_arguments)
    skylight_cool_shade_mult = runner.getDoubleArgumentValue("skylight_cool_shade_mult",user_arguments)

    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
        return false
    end
    
    heating_season, cooling_season = HVAC.calc_heating_and_cooling_seasons(model, weather, runner)
    if heating_season.nil? or cooling_season.nil?
        return false
    end
    
    subsurfaces = {"WindowConstruction"=>{"subsurfaces"=>[], "ufactor"=>ufactor, "shgc"=>shgc, "heat_shade_mult"=>heat_shade_mult, "cool_shade_mult"=>cool_shade_mult, "int_shading_sch_name"=>"#{Constants.ObjectNameWindowShading} schedule"},
                   "SkylightConstruction"=>{"subsurfaces"=>[], "ufactor"=>skylight_ufactor, "shgc"=>skylight_shgc, "heat_shade_mult"=>skylight_heat_shade_mult, "cool_shade_mult"=>skylight_cool_shade_mult, "int_shading_sch_name"=>"#{Constants.ObjectNameSkylightShading} schedule"}}
    model.getSubSurfaces.each do |subsurface|
      if subsurface.subSurfaceType.downcase.include? "window"
        subsurfaces["WindowConstruction"]["subsurfaces"] << subsurface
      elsif subsurface.subSurfaceType.downcase.include? "skylight"
        subsurfaces["SkylightConstruction"]["subsurfaces"] << subsurface
      end
    end   
    
    # Apply constructions
    if not SubsurfaceConstructions.apply_window_skylight(runner, model, subsurfaces, weather, cooling_season)
        return false
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    # Reporting
    runner.registerFinalCondition("All windows and skylights have been assigned constructions.")
    
    return true
 
  end #end the run method
  
  def get_window_sub_surfaces(model)
  end  

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsWindowsSkylights.new.registerWithApplication