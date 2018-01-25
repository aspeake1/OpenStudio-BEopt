require "#{File.dirname(__FILE__)}/util"
require "#{File.dirname(__FILE__)}/unit_conversions"

class Kiva

  def self.apply_settings(model, soil_mat)
    # Set the Foundation:Kiva:Settings object
    settings = model.getFoundationKivaSettings
    settings.setSoilConductivity(UnitConversions.convert(soil_mat.k_in,"Btu*in/(hr*ft^2*R)","W/(m*K)"))
    settings.setSoilDensity(UnitConversions.convert(soil_mat.rho,"lbm/ft^3","kg/m^3"))
    settings.setSoilSpecificHeat(UnitConversions.convert(soil_mat.cp,"Btu/(lbm*R)","J/(kg*K)"))
    settings.setGroundSolarAbsorptivity(0.9)
    settings.setGroundThermalAbsorptivity(0.9)
    settings.setGroundSurfaceRoughness(0.03)
    settings.setFarFieldWidth(40) # TODO: Set based on neighbor distances
    settings.setDeepGroundBoundaryCondition('ZeroFlux')
    settings.setDeepGroundDepth(40)
    settings.setMinimumCellDimension(0.02)
    settings.setMaximumCellGrowthCoefficient(1.5)
    settings.setSimulationTimestep("Hourly")
  end
  
  def self.create_slab_foundation(model, int_horiz_r, int_horiz_width, int_vert_r, int_vert_depth, 
                                  ext_vert_r, ext_vert_depth)
    # Create the Foundation:Kiva object for slab foundations
    foundation = OpenStudio::Model::FoundationKiva.new(model)
    
    # Interior horizontal insulation
    if int_horiz_r > 0 and int_horiz_width > 0
      int_horiz_mat = self.create_insulation_material(model, "FoundationIntHorizIns", int_horiz_r)
      foundation.setInteriorHorizontalInsulationMaterial(int_horiz_mat)
      foundation.setInteriorHorizontalInsulationDepth(0)
      foundation.setInteriorHorizontalInsulationWidth(UnitConversions.convert(int_horiz_width,"ft","m"))
    end
    
    # Interior vertical insulation
    if int_vert_r > 0
      int_vert_mat = self.create_insulation_material(model, "FoundationIntVertIns", int_vert_r)
      foundation.setInteriorVerticalInsulationMaterial(int_vert_mat)
      foundation.setInteriorVerticalInsulationDepth(UnitConversions.convert(int_vert_depth,"ft","m"))
    end
    
    # Exterior vertical insulation
    if ext_vert_r > 0 and ext_vert_depth > 0
      ext_vert_mat = self.create_insulation_material(model, "FoundationExtVertIns", ext_vert_r)
      foundation.setExteriorVerticalInsulationMaterial(ext_vert_mat)
      foundation.setExteriorVerticalInsulationDepth(UnitConversions.convert(ext_vert_depth,"ft","m"))
    end
    
    foundation.setWallHeightAboveGrade(UnitConversions.convert(8.0,"in","m"))
    foundation.setWallDepthBelowSlab(UnitConversions.convert(8.0,"in","m"))
    
    # Footing wall construction
    footing_mat = self.create_footing_material(model, "FootingMaterial")
    footing_constr = OpenStudio::Model::Construction.new([footing_mat])
    footing_constr.setName("FootingConstruction") 
    foundation.setFootingWallConstruction(footing_constr)
    
    Kiva.apply_settings(model, BaseMaterial.Soil)
    
    return foundation
  end
  
  def self.create_crawl_or_basement_foundation(model, int_vert_r, int_vert_depth, 
                                               ext_vert_r, ext_vert_depth)
    # Create the Foundation:Kiva object for crawl/basement foundations
    foundation = OpenStudio::Model::FoundationKiva.new(model)
    
    # Interior vertical insulation
    if int_vert_r > 0 and int_vert_depth > 0
      int_vert_mat = self.create_insulation_material(model, "FoundationIntVertIns", int_vert_r)
      foundation.setInteriorVerticalInsulationMaterial(int_vert_mat)
      foundation.setInteriorVerticalInsulationDepth(UnitConversions.convert(int_vert_depth,"ft","m"))
    end
    
    # Exterior vertical insulation
    if ext_vert_r > 0 and ext_vert_depth > 0
      ext_vert_mat = self.create_insulation_material(model, "FoundationExtVertIns", ext_vert_r)
      foundation.setExteriorVerticalInsulationMaterial(ext_vert_mat)
      foundation.setExteriorVerticalInsulationDepth(UnitConversions.convert(ext_vert_depth,"ft","m"))
    end
    
    foundation.setWallHeightAboveGrade(UnitConversions.convert(8.0,"in","m"))
    foundation.setWallDepthBelowSlab(UnitConversions.convert(8.0,"in","m"))
    
    Kiva.apply_settings(model, BaseMaterial.Soil)
    
    return foundation
  end
  
  def self.create_insulation_material(model, name, rvalue)
    rigid_mat = BaseMaterial.InsulationRigid
    mat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    mat.setName(name)
    mat.setRoughness("Rough")
    mat.setThickness(UnitConversions.convert(rvalue*rigid_mat.k_in,"in","m"))
    mat.setConductivity(UnitConversions.convert(rigid_mat.k_in,"Btu*in/(hr*ft^2*R)","W/(m*K)"))
    mat.setDensity(UnitConversions.convert(rigid_mat.rho,"lbm/ft^3","kg/m^3"))
    mat.setSpecificHeat(UnitConversions.convert(rigid_mat.cp,"Btu/(lbm*R)","J/(kg*K)"))
    return mat
  end
  
  def self.create_footing_material(model, name)
    footing_mat = Material.Concrete8in
    mat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    mat.setName(name)
    mat.setRoughness("Rough")
    mat.setThickness(UnitConversions.convert(footing_mat.thick_in,"in","m"))
    mat.setConductivity(UnitConversions.convert(footing_mat.k_in,"Btu*in/(hr*ft^2*R)","W/(m*K)"))
    mat.setDensity(UnitConversions.convert(footing_mat.rho,"lbm/ft^3","kg/m^3"))
    mat.setSpecificHeat(UnitConversions.convert(footing_mat.cp,"Btu/(lbm*R)","J/(kg*K)"))
    mat.setThermalAbsorptance(footing_mat.tAbs)
     return mat
  end
      
end