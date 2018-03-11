require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"
require "#{File.dirname(__FILE__)}/schedules"

class MiscLoads

  def self.apply_plug()
      # TODO
  end

  def self.apply_electric(model, unit, runner, annual_energy, mult,
                          weekday_sch, weekend_sch, monthly_sch, sch, space,
                          unit_obj_name, scale_energy)
  
      #check for valid inputs
      if annual_energy < 0
          runner.registerError("Annual energy must be greater than or equal to 0.")
          return false
      end
      if mult < 0
          runner.registerError("Energy multiplier must be greater than or equal to 0.")
          return false
      end
      
      #Calculate annual energy use
      ann_e = annual_energy * mult # kWh/yr
      
      if scale_energy
          # Get unit beds/baths
          nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
          if nbeds.nil? or nbaths.nil?
              return false
          end
          
          # Get unit ffa
          ffa = Geometry.get_finished_floor_area_from_spaces(unit.spaces, false, runner)
          if ffa.nil?
              return false
          end
          
          #Scale energy use by num beds and floor area
          constant = 1.0/2
          nbr_coef = 1.0/4/3
          ffa_coef = 1.0/4/1920
          ann_e = ann_e * (constant + nbr_coef * nbeds + ffa_coef * ffa) # kWh/yr
      end

      if ann_e > 0
      
          if sch.nil?
              # Create schedule
              sch = MonthWeekdayWeekendSchedule.new(model, runner, unit_obj_name + " schedule", weekday_sch, weekend_sch, monthly_sch)
              if not sch.validated?
                  return false
              end
          end
          
          design_level = sch.calcDesignLevelFromDailykWh(ann_e/365.0)
          
          #Add electric equipment for the load
          load_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
          load = OpenStudio::Model::ElectricEquipment.new(load_def)
          load.setName(unit_obj_name)
          load.setEndUseSubcategory(unit_obj_name)
          if space.nil?
              # Use arbitrary space with FractionLost=1
              load.setSpace(model.getSpaces[0])
              load_def.setFractionLost(1)
          else
              load.setSpace(space)
              load_def.setFractionLost(0)
          end
          load_def.setFractionRadiant(0)
          load_def.setFractionLatent(0)
          load_def.setName(unit_obj_name)
          load_def.setDesignLevel(design_level)
          load.setSchedule(sch.schedule)
          
      end
      
      return true, ann_e, sch

  end
    
  def self.apply_gas(model, unit, runner, annual_energy, mult,
                     weekday_sch, weekend_sch, monthly_sch, sch, space,
                     unit_obj_name, scale_energy)
  
      #check for valid inputs
      if annual_energy < 0
          runner.registerError("Annual energy must be greater than or equal to 0.")
          return false
      end
      if mult < 0
          runner.registerError("Energy multiplier must be greater than or equal to 0.")
          return false
      end
      
      #Calculate annual energy use
      ann_g = annual_energy * mult # therm/yr
      
      if scale_energy
          # Get unit beds/baths
          nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
          if nbeds.nil? or nbaths.nil?
              return false
          end
          
          # Get unit ffa
          ffa = Geometry.get_finished_floor_area_from_spaces(unit.spaces, false, runner)
          if ffa.nil?
              return false
          end
          
          #Scale energy use by num beds and floor area
          constant = 1.0/2
          nbr_coef = 1.0/4/3
          ffa_coef = 1.0/4/1920
          ann_g = ann_g * (constant + nbr_coef * nbeds + ffa_coef * ffa) # therm/yr
      end

      if ann_g > 0
      
          if sch.nil?
              # Create schedule
              sch = MonthWeekdayWeekendSchedule.new(model, runner, unit_obj_name + " schedule", weekday_sch, weekend_sch, monthly_sch)
              if not sch.validated?
                  return false
              end
          end
          
          design_level = sch.calcDesignLevelFromDailyTherm(ann_g/365.0)
          
          #Add gas equipment for the load
          load_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
          load = OpenStudio::Model::GasEquipment.new(load_def)
          load.setName(unit_obj_name)
          load.setEndUseSubcategory(unit_obj_name)
          if space.nil?
              # Use arbitrary space with FractionLost=1
              load.setSpace(model.getSpaces[0])
              load_def.setFractionLost(1)
          else
              load.setSpace(space)
              load_def.setFractionLost(0)
          end
          load_def.setFractionRadiant(0)
          load_def.setFractionLatent(0)
          load_def.setName(unit_obj_name)
          load_def.setDesignLevel(design_level)
          load.setSchedule(sch.schedule)
          
      end
      
      return true, ann_g, sch

  end
    
  def self.remove(runner, space, obj_names)
      # Remove any existing large, uncommon loads
      objects_to_remove = []
      space.electricEquipment.each do |space_equipment|
          found = false
          obj_names.each do |obj_name|
              next if not space_equipment.name.to_s.start_with? obj_name
              found = true
          end
          next if not found
          objects_to_remove << space_equipment
          objects_to_remove << space_equipment.electricEquipmentDefinition
          if space_equipment.schedule.is_initialized
              objects_to_remove << space_equipment.schedule.get
          end
      end
      space.gasEquipment.each do |space_equipment|
          found = false
          obj_names.each do |obj_name|
              next if not space_equipment.name.to_s.start_with? obj_name
              found = true
          end
          next if not found
          objects_to_remove << space_equipment
          objects_to_remove << space_equipment.gasEquipmentDefinition
          if space_equipment.schedule.is_initialized
              objects_to_remove << space_equipment.schedule.get
          end
      end
      if objects_to_remove.size > 0
          runner.registerInfo("Removed existing large, uncommon loads from space '#{space.name.to_s}'.")
      end
      objects_to_remove.uniq.each do |object|
          begin
              object.remove
          rescue
              # no op
          end
      end
  end

end
