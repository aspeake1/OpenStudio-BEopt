require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"
require "#{File.dirname(__FILE__)}/materials"
require "#{File.dirname(__FILE__)}/geometry"

class WallConstructions

    # Generic static methods for wall constructions

    def self.apply_wood_stud(surfaces, runner, model, constr_name, 
                             cavity_r, install_grade, cavity_depth_in, cavity_filled, 
                             framing_factor, drywall_thick_in, osb_thick_in, 
                             rigid_r, rigid_thick_in, mat_ext_finish)
    
        return true if surfaces.empty?
    
        # Validate inputs
        if cavity_r < 0.0
            runner.registerError("Cavity Insulation Installed R-value must be greater than or equal to 0.")
            return false
        end
        if cavity_depth_in <= 0.0
            runner.registerError("Cavity Depth must be greater than 0.")
            return false
        end
        if framing_factor < 0.0 or framing_factor >= 1.0
            runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
            return false
        end

        # Define materials
        if cavity_r > 0
            if cavity_filled
                # Insulation
                mat_cavity = Material.new(name=nil, thick_in=cavity_depth_in, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavity_depth_in / cavity_r)
            else
                # Insulation plus air gap when insulation thickness < cavity depth
                mat_cavity = Material.new(name=nil, thick_in=cavity_depth_in, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavity_depth_in / (cavity_r + Gas.AirGapRvalue))
            end
        else
            # Empty cavity
            mat_cavity = Material.AirCavityClosed(cavity_depth_in)
        end
        mat_framing = Material.new(name=nil, thick_in=cavity_depth_in, mat_base=BaseMaterial.Wood)
        mat_gap = Material.AirCavityClosed(cavity_depth_in)
        mat_drywall = nil
        if drywall_thick_in > 0
            mat_drywall = Material.GypsumWall(drywall_thick_in)
        end
        mat_osb = nil
        if osb_thick_in > 0
            mat_osb = Material.new(name="Sheathing", thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
        end
        mat_rigid = nil
        if rigid_r > 0 and rigid_thick_in > 0
            mat_rigid = Material.new(name="RigidIns", thick_in=rigid_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=rigid_thick_in/rigid_r)
        end

        # Set paths
        gapFactor = get_gap_factor(install_grade, framing_factor, cavity_r)
        path_fracs = [framing_factor, 1 - framing_factor - gapFactor, gapFactor]
        
        # Define construction
        constr = Construction.new(constr_name, path_fracs)
        constr.add_layer(Material.AirFilmVertical)
        if not mat_drywall.nil?
            constr.add_layer(mat_drywall)
        end
        constr.add_layer([mat_framing, mat_cavity, mat_gap], "StudAndCavity") 
        if not mat_osb.nil?
            constr.add_layer(mat_osb)
        end
        if not mat_rigid.nil?
            constr.add_layer(mat_rigid)
        end
        if not mat_ext_finish.nil?
            constr.add_layer(mat_ext_finish)
            constr.add_layer(Material.AirFilmOutside)
        else # interior wall
            constr.add_layer(Material.AirFilmVertical)
        end

        # Create and assign construction to surfaces
        if not constr.create_and_assign_constructions(surfaces, runner, model)
            return false
        end
        
        # Store info for HVAC Sizing measure
        (surfaces).each do |surface|
            model.getBuildingUnits.each do |unit|
                next if unit.spaces.size == 0
                unit.setFeature(Constants.SizingInfoWallType(surface), "WoodStud")
                unit.setFeature(Constants.SizingInfoStudWallCavityRvalue(surface), cavity_r)
            end
        end
        
        return true
    end
    
    def self.apply_double_stud(surfaces, runner, model, constr_name, 
                               cavity_r, install_grade, stud_depth, gap_depth,
                               framing_factor, framing_spacing, is_staggered,
                               drywall_thick_in, osb_thick_in, rigid_r,
                               rigid_thick_in, mat_ext_finish)
    
        return true if surfaces.empty?
    
        # Validate inputs
        if cavity_r <= 0.0
            runner.registerError("Cavity Insulation Nominal R-value must be greater than 0.")
            return false
        end
        if stud_depth <= 0.0
            runner.registerError("Stud Depth must be greater than 0.")
            return false
        end
        if gap_depth < 0.0
            runner.registerError("Gap Depth must be greater than or equal to 0.")
            return false
        end
        if framing_factor < 0.0 or framing_factor >= 1.0
            runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
            return false
        end
        if framing_spacing <= 0.0
            runner.registerError("Framing Spacing must be greater than 0.")
            return false
        end
    
        # Define materials
        cavityDepth = 2.0 * stud_depth + gap_depth
        mat_ins_inner_outer = Material.new(name=nil, thick_in=stud_depth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavityDepth / cavity_r)
        mat_ins_middle = Material.new(name=nil, thick_in=gap_depth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavityDepth / cavity_r)
        mat_framing_inner_outer = Material.new(name=nil, thick_in=stud_depth, mat_base=BaseMaterial.Wood)
        mat_framing_middle = Material.new(name=nil, thick_in=gap_depth, mat_base=BaseMaterial.Wood)
        mat_stud = Material.new(name=nil, thick_in=stud_depth, mat_base=BaseMaterial.Wood)
        mat_gap_total = Material.AirCavityClosed(cavityDepth)
        mat_gap_inner_outer = Material.new(name=nil, thick_in=stud_depth, mat_base=nil, k_in=stud_depth / (mat_gap_total.rvalue * stud_depth / cavityDepth), rho=Gas.Air.rho, cp=Gas.Air.cp)
        mat_gap_middle = Material.new(name=nil, thick_in=gap_depth, mat_base=nil, k_in=gap_depth / (mat_gap_total.rvalue * gap_depth / cavityDepth), rho=Gas.Air.rho, cp=Gas.Air.cp)
        mat_drywall = nil
        if drywall_thick_in > 0
            mat_drywall = Material.GypsumWall(drywall_thick_in)
        end
        mat_osb = nil
        if osb_thick_in > 0
            mat_osb = Material.new(name="Sheathing", thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
        end
        mat_rigid = nil
        if rigid_r > 0 and rigid_thick_in > 0
            mat_rigid = Material.new(name="RigidIns", thick_in=rigid_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=rigid_thick_in/rigid_r)
        end
        
        # Set paths
        stud_frac = 1.5 / framing_spacing
        misc_framing_factor = framing_factor - stud_frac
        if misc_framing_factor < 0
            runner.registerError("Framing Factor (#{framing_factor.to_s}) is less than the framing solely provided by the studs (#{stud_frac.to_s}).")
            return false
        end
        dsGapFactor = get_gap_factor(install_grade, framing_factor, cavity_r)
        path_fracs = [misc_framing_factor, stud_frac, stud_frac, dsGapFactor, (1.0 - (2 * stud_frac + misc_framing_factor + dsGapFactor))] 

        # Define construction
        constr = Construction.new(constr_name, path_fracs)
        constr.add_layer(Material.AirFilmVertical)
        if not mat_drywall.nil?
            constr.add_layer(mat_drywall)
        end
        constr.add_layer([mat_framing_inner_outer, mat_stud, mat_ins_inner_outer, mat_gap_inner_outer, mat_ins_inner_outer], "StudandCavityInner")
        if gap_depth > 0
            constr.add_layer([mat_framing_middle, mat_ins_middle, mat_ins_middle, mat_gap_middle, mat_ins_middle], "Cavity")
        end
        if is_staggered
            constr.add_layer([mat_framing_inner_outer, mat_ins_inner_outer, mat_stud, mat_gap_inner_outer, mat_ins_inner_outer], "StudandCavityOuter")
        else
            constr.add_layer([mat_framing_inner_outer, mat_stud, mat_ins_inner_outer, mat_gap_inner_outer, mat_ins_inner_outer], "StudandCavityOuter")
        end
        if not mat_osb.nil?
            constr.add_layer(mat_osb)
        end
        if not mat_rigid.nil?
            constr.add_layer(mat_rigid)
        end
        if not mat_ext_finish.nil?
            constr.add_layer(mat_ext_finish)
            constr.add_layer(Material.AirFilmOutside)
        else # interior wall
            constr.add_layer(Material.AirFilmVertical)
        end

        # Create and assign construction to surfaces
        if not constr.create_and_assign_constructions(surfaces, runner, model)
            return false
        end
        
        # Store info for HVAC Sizing measure
        (surfaces).each do |surface|
            model.getBuildingUnits.each do |unit|
                next if unit.spaces.size == 0
                unit.setFeature(Constants.SizingInfoWallType(surface), "DoubleWoodStud")
            end
        end
        
        return true
    end
    
    def self.apply_cmu(surfaces, runner, model, constr_name,
                       thick_in, conductivity, density, framing_factor,
                       furring_r, furring_cavity_depth, furring_spacing,
                       drywall_thick_in, osb_thick_in, rigid_r,
                       rigid_thick_in, mat_ext_finish)
    
        return true if surfaces.empty?
    
        # Validate inputs
        if thick_in <= 0.0
            runner.registerError("CMU Block Thickness must be greater than 0.")
            return false
        end
        if conductivity <= 0.0
            runner.registerError("CMU Conductivity must be greater than 0.")
            return false
        end
        if density <= 0.0
            runner.registerError("CMU Density must be greater than 0.")
            return false
        end
        if framing_factor < 0.0 or framing_factor >= 1.0
            runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
            return false
        end
        if furring_r < 0.0
            runner.registerError("Furring Insulation R-value must be greater than or equal to 0.")
            return false
        end
        if furring_cavity_depth < 0.0
            runner.registerError("Furring Cavity Depth must be greater than or equal to 0.")
            return false
        end
        if furring_spacing < 0.0
            runner.registerError("Furring Stud Spacing must be greater than or equal to 0.")
            return false
        end
    
        # Define materials
        mat_cmu = Material.new(name=nil, thick_in=thick_in, mat_base=BaseMaterial.Concrete, k_in=conductivity, rho=density)
        mat_framing = Material.new(name=nil, thick_in=thick_in, mat_base=BaseMaterial.Wood)
        mat_furring = nil
        mat_furring_cavity = nil
        if furring_cavity_depth != 0
            mat_furring = Material.new(name=nil, thick_in=furring_cavity_depth, mat_base=BaseMaterial.Wood)
            if furring_r == 0
                mat_furring_cavity = Material.AirCavityClosed(furring_cavity_depth)
            else
                mat_furring_cavity = Material.new(name=nil, thick_in=furring_cavity_depth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=furring_cavity_depth / furring_r)
            end
        end
        mat_drywall = nil
        if drywall_thick_in > 0
            mat_drywall = Material.GypsumWall(drywall_thick_in)
        end
        mat_osb = nil
        if osb_thick_in > 0
            mat_osb = Material.new(name="Sheathing", thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
        end
        mat_rigid = nil
        if rigid_r > 0 and rigid_thick_in > 0
            mat_rigid = Material.new(name="RigidIns", thick_in=rigid_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=rigid_thick_in/rigid_r)
        end
        
        # Set paths
        if not mat_furring.nil?
            stud_frac = 1.5 / furring_spacing
            cavity_frac = 1.0 - (stud_frac + framing_factor)
            path_fracs = [framing_factor, stud_frac, cavity_frac]
        else # No furring:
            path_fracs = [framing_factor, 1.0 - framing_factor]
        end

        # Define construction
        constr = Construction.new(constr_name, path_fracs)
        constr.add_layer(Material.AirFilmVertical)
        if not mat_drywall.nil?
            constr.add_layer(mat_drywall)
        end
        if not mat_furring.nil?
            constr.add_layer([mat_furring, mat_furring, mat_furring_cavity], "Furring")
            constr.add_layer([mat_framing, mat_cmu, mat_cmu], "CMU")
        else
            constr.add_layer([mat_framing, mat_cmu], "CMU")
        end
        if not mat_osb.nil?
            constr.add_layer(mat_osb)
        end
        if not mat_rigid.nil?
            constr.add_layer(mat_rigid)
        end
        if not mat_ext_finish.nil?
            constr.add_layer(mat_ext_finish)
            constr.add_layer(Material.AirFilmOutside)
        else # interior wall
            constr.add_layer(Material.AirFilmVertical)
        end
        
        # Create and assign construction to surfaces
        if not constr.create_and_assign_constructions(surfaces, runner, model)
            return false
        end
        
        # Store info for HVAC Sizing measure
        (surfaces).each do |surface|
            model.getBuildingUnits.each do |unit|
                next if unit.spaces.size == 0
                unit.setFeature(Constants.SizingInfoWallType(surface), "CMU")
                unit.setFeature(Constants.SizingInfoCMUWallFurringInsRvalue(surface), furring_r)
            end
        end

        
        return true
    end
    
    def self.apply_icf(surfaces, runner, model, constr_name,
                       icf_r, ins_thick_in, concrete_thick_in, framing_factor,
                       drywall_thick_in, osb_thick_in, rigid_r,
                       rigid_thick_in, mat_ext_finish)
    
        return true if surfaces.empty?
    
        # Validate inputs
        if icf_r <= 0.0
            runner.registerError("Nominal Insulation R-value must be greater than 0.")
            return false
        end
        if ins_thick_in <= 0.0
            runner.registerError("Insulation Thickness must be greater than 0.")
            return false
        end
        if concrete_thick_in <= 0.0
            runner.registerError("Concrete Thickness must be greater than 0.")
            return false
        end
        if framing_factor < 0.0 or framing_factor >= 1.0
            runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
            return false
        end

        # Define materials
        mat_ins = Material.new(name=nil, thick_in=ins_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=ins_thick_in / icf_r)
        mat_conc = Material.new(name=nil, thick_in=concrete_thick_in, mat_base=BaseMaterial.Concrete)
        mat_framing_inner_outer = Material.new(name=nil, thick_in=ins_thick_in, mat_base=BaseMaterial.Wood)
        mat_framing_middle = Material.new(name=nil, thick_in=concrete_thick_in, mat_base=BaseMaterial.Wood)
        mat_drywall = nil
        if drywall_thick_in > 0
            mat_drywall = Material.GypsumWall(drywall_thick_in)
        end
        mat_osb = nil
        if osb_thick_in > 0
            mat_osb = Material.new(name="Sheathing", thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
        end
        mat_rigid = nil
        if rigid_r > 0 and rigid_thick_in > 0
            mat_rigid = Material.new(name="RigidIns", thick_in=rigid_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=rigid_thick_in/rigid_r)
        end
        
        # Set paths
        path_fracs = [framing_factor, 1.0 - framing_factor]
        
        # Define construction
        constr = Construction.new(constr_name, path_fracs)
        constr.add_layer(Material.AirFilmVertical)
        if not mat_drywall.nil?
            constr.add_layer(mat_drywall)
        end
        constr.add_layer([mat_framing_inner_outer, mat_ins], "ICFInsFormInner")
        constr.add_layer([mat_framing_middle, mat_conc], "ICFConcrete")
        constr.add_layer([mat_framing_inner_outer, mat_ins], "ICFInsFormOuter")
        if not mat_osb.nil?
            constr.add_layer(mat_osb)
        end
        if not mat_rigid.nil?
            constr.add_layer(mat_rigid)
        end
        if not mat_ext_finish.nil?
            constr.add_layer(mat_ext_finish)
            constr.add_layer(Material.AirFilmOutside)
        else # interior wall
            constr.add_layer(Material.AirFilmVertical)
        end
        
        # Create and assign construction to surfaces
        if not constr.create_and_assign_constructions(surfaces, runner, model)
            return false
        end
        
        # Store info for HVAC Sizing measure
        (surfaces).each do |surface|
            model.getBuildingUnits.each do |unit|
                next if unit.spaces.size == 0
                unit.setFeature(Constants.SizingInfoWallType(surface), "ICF")
            end
        end
        
        return true
    end
    
    def self.apply_sip(surfaces, runner, model, constr_name,
                       sip_r, sip_thick_in, framing_factor,
                       sheathing_type, sheathing_thick_in, 
                       drywall_thick_in, osb_thick_in, rigid_r,
                       rigid_thick_in, mat_ext_finish)
    
        return true if surfaces.empty?
    
        # Validate inputs
        if sip_r <= 0.0
            runner.registerError("Nominal Insulation R-value must be greater than 0.")
            return false
        end
        if sip_thick_in <= 0.0
            runner.registerError("Insulation Thickness must be greater than 0.")
            return false
        end
        if framing_factor < 0.0 or framing_factor >= 1.0
            runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
            return false
        end
        if sheathing_thick_in <= 0.0
            runner.registerError("Interior Sheathing Thickness must be greater than 0.")
            return false
        end

        # Define materials
        spline_thick_in = 0.5
        ins_thick_in = sip_thick_in - (2.0 * spline_thick_in) # in
        if sheathing_type == Constants.MaterialOSB
            mat_int_sheath = Material.new(name="IntSheathing", thick_in=sheathing_thick_in, mat_base=BaseMaterial.Wood)
        elsif sheathing_type == Constants.MaterialGypsum
            mat_int_sheath = Material.new(name="IntSheathing", thick_in=sheathing_thick_in, mat_base=BaseMaterial.Gypsum)
        elsif sheathing_type == Constants.MaterialGypcrete
            mat_int_sheath = Material.new(name="IntSheathing", thick_in=sheathing_thick_in, mat_base=BaseMaterial.Gypcrete)
        end
        mat_framing_inner_outer = Material.new(name=nil, thick_in=spline_thick_in, mat_base=BaseMaterial.Wood)
        mat_framing_middle = Material.new(name=nil, thick_in=ins_thick_in, mat_base=BaseMaterial.Wood)
        mat_spline = Material.new(name=nil, thick_in=spline_thick_in, mat_base=BaseMaterial.Wood)
        mat_ins_inner_outer = Material.new(name=nil, thick_in=spline_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=sip_thick_in / sip_r)
        mat_ins_middle = Material.new(name=nil, thick_in=ins_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=sip_thick_in / sip_r)
        mat_drywall = nil
        if drywall_thick_in > 0
            mat_drywall = Material.GypsumWall(drywall_thick_in)
        end
        mat_osb = nil
        if osb_thick_in > 0
            mat_osb = Material.new(name="Sheathing", thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
        end
        mat_rigid = nil
        if rigid_r > 0 and rigid_thick_in > 0
            mat_rigid = Material.new(name="RigidIns", thick_in=rigid_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=rigid_thick_in/rigid_r)
        end
        
        # Set paths
        spline_frac = 4.0 / 48.0 # One 4" spline for every 48" wide panel
        cavity_frac = 1.0 - (spline_frac + framing_factor)
        path_fracs = [framing_factor, spline_frac, cavity_frac]
        
        # Define construction
        constr = Construction.new(constr_name, path_fracs)
        constr.add_layer(Material.AirFilmVertical)
        if not mat_drywall.nil?
            constr.add_layer(mat_drywall)
        end
        constr.add_layer(mat_int_sheath)
        constr.add_layer([mat_framing_inner_outer, mat_spline, mat_ins_inner_outer], "SplineLayerInner")
        constr.add_layer([mat_framing_middle, mat_ins_middle, mat_ins_middle], "WallIns")
        constr.add_layer([mat_framing_inner_outer, mat_spline, mat_ins_inner_outer], "SplineLayerOuter")
        if not mat_osb.nil?
            constr.add_layer(mat_osb)
        end
        if not mat_rigid.nil?
            constr.add_layer(mat_rigid)
        end
        if not mat_ext_finish.nil?
            constr.add_layer(mat_ext_finish)
            constr.add_layer(Material.AirFilmOutside)
        else # interior wall
            constr.add_layer(Material.AirFilmVertical)
        end

        # Create and assign construction to surfaces
        if not constr.create_and_assign_constructions(surfaces, runner, model)
            return false
        end
        
        # Store info for HVAC Sizing measure
        (surfaces).each do |surface|
            model.getBuildingUnits.each do |unit|
                next if unit.spaces.size == 0
                unit.setFeature(Constants.SizingInfoWallType(surface), "SIP")
                unit.setFeature(Constants.SizingInfoSIPWallInsThickness(surface), sip_thick_in)
            end
        end
        
        return true
    end
    
    def self.apply_steel_stud(surfaces, runner, model, constr_name,
                              cavity_r, install_grade, cavity_depth,
                              cavity_filled, framing_factor, correction_factor,
                              drywall_thick_in, osb_thick_in, rigid_r,
                              rigid_thick_in, mat_ext_finish)
    
        return true if surfaces.empty?

        # Validate inputs
        if cavity_r < 0.0
            runner.registerError("Cavity Insulation Nominal R-value must be greater than or equal to 0.")
            return false
        end
        if cavity_depth <= 0.0
            runner.registerError("Cavity Depth must be greater than 0.")
            return false
        end
        if framing_factor < 0.0 or framing_factor >= 1.0
            runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
            return false
        end
        if correction_factor < 0.0 or correction_factor > 1.0
            runner.registerError("Correction Factor must be greater than or equal to 0 and less than or equal to 1.")
            return false
        end
        
        # Define materials
        eR = cavity_r * correction_factor # The effective R-value of the cavity insulation with steel stud framing
        if eR > 0
            if cavity_filled
                # Insulation
                mat_cavity = Material.new(name=nil, thick_in=cavity_depth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavity_depth / eR)
            else
                # Insulation plus air gap when insulation thickness < cavity depth
                mat_cavity = Material.new(name=nil, thick_in=cavity_depth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavity_depth / (eR + Gas.AirGapRvalue))
            end
        else
            # Empty cavity
            mat_cavity = Material.AirCavityClosed(cavity_depth)
        end
        mat_gap = Material.AirCavityClosed(cavity_depth)
        mat_drywall = nil
        if drywall_thick_in > 0
            mat_drywall = Material.GypsumWall(drywall_thick_in)
        end
        mat_osb = nil
        if osb_thick_in > 0
            mat_osb = Material.new(name="Sheathing", thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
        end
        mat_rigid = nil
        if rigid_r > 0 and rigid_thick_in > 0
            mat_rigid = Material.new(name="RigidIns", thick_in=rigid_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=rigid_thick_in/rigid_r)
        end
        
        # Set paths
        gapFactor = get_gap_factor(install_grade, framing_factor, cavity_r)
        path_fracs = [1 - gapFactor, gapFactor]
        
        # Define construction
        constr = Construction.new(constr_name, path_fracs)
        constr.add_layer(Material.AirFilmVertical)
        if not mat_drywall.nil?
            constr.add_layer(mat_drywall)
        end
        constr.add_layer([mat_cavity, mat_gap], "StudAndCavity")
        if not mat_osb.nil?
            constr.add_layer(mat_osb)
        end
        if not mat_rigid.nil?
            constr.add_layer(mat_rigid)
        end
        if not mat_ext_finish.nil?
            constr.add_layer(mat_ext_finish)
            constr.add_layer(Material.AirFilmOutside)
        else # interior wall
            constr.add_layer(Material.AirFilmVertical)
        end

        # Create and assign construction to surfaces
        if not constr.create_and_assign_constructions(surfaces, runner, model)
            return false
        end
        
        # Store info for HVAC Sizing measure
        (surfaces).each do |surface|
            model.getBuildingUnits.each do |unit|
                next if unit.spaces.size == 0
                unit.setFeature(Constants.SizingInfoWallType(surface), "SteelStud")
                unit.setFeature(Constants.SizingInfoStudWallCavityRvalue(surface), cavity_r)
            end
        end
        
        return true
    end
    
    def self.apply_generic(surfaces, runner, model, constr_name,
                           thick_ins, conds, denss, specheats,
                           drywall_thick_in, osb_thick_in, rigid_r,
                           rigid_thick_in, mat_ext_finish)
    
        return true if surfaces.empty?
    
        # Validate inputs
        for idx in 0..4
            if thick_ins[idx].nil? != conds[idx].nil? or thick_ins[idx].nil? != denss[idx].nil? or thick_ins[idx].nil? != specheats[idx].nil?
                runner.registerError("Layer #{idx+1} does not have all four properties (thickness, conductivity, density, specific heat) entered.")
                return false
            end
        end
        thick_ins.each_with_index do |thick_in, idx|
            if not thick_in.nil? and thick_in <= 0.0
                runner.registerError("Thickness #{idx+1} must be greater than 0.")
                return false
            end
        end
        conds.each_with_index do |cond, idx|
            if not cond.nil? and cond <= 0.0
                runner.registerError("Conductivity #{idx+1} must be greater than 0.")
                return false
            end
        end
        denss.each_with_index do |dens, idx|
            if not dens.nil? and dens <= 0.0
                runner.registerError("Density #{idx+1} must be greater than 0.")
                return false
            end
        end
        specheats.each_with_index do |specheat, idx|
            if not specheat.nil? and specheat <= 0.0
                runner.registerError("Specific Heat #{idx+1} must be greater than 0.")
                return false
            end
        end
    
        # Define materials
        mats = []
        mats << Material.new(name="Layer1", thick_in=thick_ins[0], mat_base=nil, k_in=conds[0], rho=denss[0], cp=specheats[0])
        if not thick_ins[1].nil?
            mats << Material.new(name="Layer2", thick_in=thick_ins[1], mat_base=nil, k_in=conds[1], rho=denss[1], cp=specheats[1])
        end
        if not thick_ins[2].nil?
            mats << Material.new(name="Layer3", thick_in=thick_ins[2], mat_base=nil, k_in=conds[2], rho=denss[2], cp=specheats[2])
        end
        if not thick_ins[3].nil?
            mats << Material.new(name="Layer4", thick_in=thick_ins[3], mat_base=nil, k_in=conds[3], rho=denss[3], cp=specheats[3])
        end
        if not thick_ins[4].nil?
            mats << Material.new(name="Layer5", thick_in=thick_ins[4], mat_base=nil, k_in=conds[4], rho=denss[4], cp=specheats[4])
        end
        mat_drywall = nil
        if drywall_thick_in > 0
            mat_drywall = Material.GypsumWall(drywall_thick_in)
        end
        mat_osb = nil
        if osb_thick_in > 0
            mat_osb = Material.new(name="Sheathing", thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
        end
        mat_rigid = nil
        if rigid_r > 0 and rigid_thick_in > 0
            mat_rigid = Material.new(name="RigidIns", thick_in=rigid_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=rigid_thick_in/rigid_r)
        end
        
        # Set paths
        path_fracs = [1]
        
        # Define construction
        constr = Construction.new(constr_name, path_fracs)
        constr.add_layer(Material.AirFilmVertical)
        if not mat_drywall.nil?
            constr.add_layer(mat_drywall)
        end
        mats.each do |mat|
            constr.add_layer(mat)
        end
        if not mat_osb.nil?
            constr.add_layer(mat_osb)
        end
        if not mat_rigid.nil?
            constr.add_layer(mat_rigid)
        end
        if not mat_ext_finish.nil?
            constr.add_layer(mat_ext_finish)
            constr.add_layer(Material.AirFilmOutside)
        else # interior wall
            constr.add_layer(Material.AirFilmVertical)
        end
        
        # Create and assign construction to surfaces
        if not constr.create_and_assign_constructions(surfaces, runner, model)
            return false
        end
        
        # Store info for HVAC Sizing measure
        (surfaces).each do |surface|
            model.getBuildingUnits.each do |unit|
                next if unit.spaces.size == 0
                unit.setFeature(Constants.SizingInfoWallType(surface), "Generic")
            end
        end
        
        return true
    end
    
    def self.apply_uninsulated(surfaces_by_type, runner, model,
                               osb_thick_in, drywall_thick_in, mat_ext_finish)

        if not apply_uninsulated_exterior_unfinished_wall(surfaces_by_type[Constants.SurfaceTypeWallExtUninsUnfin], 
                                                          runner, model, Constants.SurfaceTypeWallExtUninsUnfin,
                                                          osb_thick_in, mat_ext_finish)
            return false
        end

        if not apply_uninsulated_interior_finished_wall(surfaces_by_type[Constants.SurfaceTypeWallIntFinUninsFin], 
                                                        runner, model, Constants.SurfaceTypeWallIntFinUninsFin,
                                                        drywall_thick_in)
            return false
        end
        
        if not apply_uninsulated_interior_unfinished_wall(surfaces_by_type[Constants.SurfaceTypeWallIntUnfinUninsUnfin], 
                                                          runner, model, Constants.SurfaceTypeWallIntUnfinUninsUnfin)
            return false
        end
        
        return true
    end
    
    def self.get_exterior_finish_materials
        mats = []
        mats << Material.ExtFinishStuccoMedDark
        mats << Material.ExtFinishBrickLight
        mats << Material.ExtFinishBrickMedDark
        mats << Material.ExtFinishWoodLight
        mats << Material.ExtFinishWoodMedDark
        mats << Material.ExtFinishAluminumLight
        mats << Material.ExtFinishAluminumMedDark
        mats << Material.ExtFinishVinylLight
        mats << Material.ExtFinishVinylMedDark
        mats << Material.ExtFinishFiberCementLight
        mats << Material.ExtFinishFiberCementMedDark
        return mats
    end
    
    def self.get_exterior_finish_material(name)
        get_exterior_finish_materials.each do |mat|
            next if mat.name != name
            return mat
        end
        return nil
    end
    
    private 
            
        def self.apply_uninsulated_exterior_unfinished_wall(surfaces, runner, model, constr_name,
                                                            osb_thick_in, mat_ext_finish)
        
            return true if surfaces.empty?
            
            # Define materials
            mat_cavity = Material.AirCavityClosed(Material.Stud2x4.thick_in)
            mat_framing = Material.new(name=nil, thick_in=Material.Stud2x4.thick_in, mat_base=BaseMaterial.Wood)
            mat_osb = nil
            if osb_thick_in > 0
                mat_osb = Material.new(name="Sheathing", thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
            end
            
            # Set paths
            path_fracs = [Constants.DefaultFramingFactorInterior, 1 - Constants.DefaultFramingFactorInterior]
            
            # Define construction
            constr = Construction.new(constr_name, path_fracs)
            constr.add_layer(Material.AirFilmVertical)
            constr.add_layer([mat_framing, mat_cavity], "ExtStudAndAirWall")
            if not mat_osb.nil?
                constr.add_layer(mat_osb)
            end
            if not mat_ext_finish.nil?
                constr.add_layer(mat_ext_finish)
            end
            constr.add_layer(Material.AirFilmOutside)

            # Create and assign construction to wall surfaces
            if not constr.create_and_assign_constructions(surfaces, runner, model)
                return false
            end
            
            return true
        end
        
        def self.apply_uninsulated_interior_finished_wall(surfaces, runner, model, constr_name,
                                                          drywall_thick_in)
        
            return true if surfaces.empty?
        
            # Define materials
            mat_cavity = Material.AirCavityClosed(Material.Stud2x4.thick_in)
            mat_framing = Material.new(name=nil, thick_in=Material.Stud2x4.thick_in, mat_base=BaseMaterial.Wood)
            mat_drywall = nil
            if drywall_thick_in > 0
                mat_drywall = Material.GypsumWall(drywall_thick_in)
            end
            
            # Set paths
            path_fracs = [Constants.DefaultFramingFactorInterior, 1 - Constants.DefaultFramingFactorInterior]
            
            # Define construction
            constr = Construction.new(constr_name, path_fracs)
            constr.add_layer(Material.AirFilmVertical)
            if not mat_drywall.nil?
                constr.add_layer(mat_drywall)
            end
            constr.add_layer([mat_framing, mat_cavity], "IntStudAndAirWall")
            if not mat_drywall.nil?
                constr.add_layer(mat_drywall)
            end
            constr.add_layer(Material.AirFilmVertical)
        
            # Create and assign construction to surfaces
            if not constr.create_and_assign_constructions(surfaces, runner, model)
                return false
            end
            
            return true
        end
        
        def self.apply_uninsulated_interior_unfinished_wall(surfaces, runner, model, constr_name)
        
            return true if surfaces.empty?
        
            # Define materials
            mat_cavity = Material.AirCavityClosed(Material.Stud2x4.thick_in)
            mat_framing = Material.new(name=nil, thick_in=Material.Stud2x4.thick_in, mat_base=BaseMaterial.Wood)
            
            # Set paths
            path_fracs = [Constants.DefaultFramingFactorInterior, 1 - Constants.DefaultFramingFactorInterior]
            
            # Define construction
            constr = Construction.new(constr_name, path_fracs)
            constr.add_layer(Material.AirFilmVertical)
            constr.add_layer([mat_framing, mat_cavity], "IntStudAndAirWall")
            constr.add_layer(Material.AirFilmVertical)
        
            # Create and apply construction to unfinished surfaces
            if not constr.create_and_assign_constructions(surfaces, runner, model)
                return false
            end
            
            return true
        end
        
end

class RoofConstructions

    # Generic static methods for roof constructions
    
    def self.apply_unfinished_attic(surfaces, runner, model, constr_name,
                                    cavity_r, install_grade, cavity_ins_thick_in,
                                    framing_factor, framing_thick_in,
                                    osb_thick_in, rigid_r, rigid_thick_in,
                                    mat_roofing, has_radiant_barrier)
    
        return true if surfaces.empty?
        
        # Validate Inputs
        if cavity_r < 0.0
            runner.registerError("Roof Cavity Insulation Nominal R-value must be greater than or equal to 0.")
            return false
        end
        if cavity_ins_thick_in < 0.0
            runner.registerError("Roof Cavity Insulation Thickness must be greater than or equal to 0.")
            return false
        end
        if framing_factor < 0.0 or framing_factor >= 1.0
            runner.registerError("Roof Framing Factor must be greater than or equal to 0 and less than 1.")
            return false
        end
        if framing_thick_in <= 0.0
            runner.registerError("Roof Framing Thickness must be greater than 0.")
            return false
        end
        
        # Define materials
        roof_ins_thickness_in = [cavity_ins_thick_in, framing_thick_in].max
        if cavity_r == 0
            mat_cavity = Material.AirCavityOpen(roof_ins_thickness_in)
        else
            cavity_k = cavity_ins_thick_in / cavity_r
            if cavity_ins_thick_in < framing_thick_in
                cavity_k = cavity_k * framing_thick_in / cavity_ins_thick_in
            end
            mat_cavity = Material.new(name=nil, thick_in=roof_ins_thickness_in, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavity_k)
        end
        if cavity_ins_thick_in > framing_thick_in and framing_thick_in > 0
            wood_k = BaseMaterial.Wood.k_in * cavity_ins_thick_in / framing_thick_in
        else
            wood_k = BaseMaterial.Wood.k_in
        end
        mat_framing = Material.new(name=nil, thick_in=roof_ins_thickness_in, mat_base=BaseMaterial.Wood, k_in=wood_k)
        mat_gap = Material.AirCavityOpen(roof_ins_thickness_in)
        mat_osb = nil
        if osb_thick_in > 0
            mat_osb = Material.new(name="Sheathing", thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
        end
        mat_rigid = nil
        if rigid_r > 0 and rigid_thick_in > 0
            mat_rigid = Material.new(name="RigidIns", thick_in=rigid_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=rigid_thick_in/rigid_r)
        end
        mat_rb = nil
        if has_radiant_barrier
            mat_rb = Material.RadiantBarrier
        end
        
        # Set paths
        gapFactor = get_gap_factor(install_grade, framing_factor, cavity_r)
        path_fracs = [framing_factor, 1 - framing_factor - gapFactor, gapFactor]
        
        # Define construction
        constr = Construction.new(constr_name, path_fracs)
        constr.add_layer(Material.AirFilmRoof(Geometry.get_roof_pitch(surfaces)))
        if not mat_rb.nil?
            constr.add_layer(mat_rb)
        end
        constr.add_layer([mat_framing, mat_cavity, mat_gap], "UARoofIns")
        if not mat_osb.nil?
            constr.add_layer(mat_osb)
        end
        if not mat_rigid.nil?
            constr.add_layer(mat_rigid)
        end
        if not mat_roofing.nil?
            constr.add_layer(mat_roofing)
        end
        constr.add_layer(Material.AirFilmOutside)

        # Create and assign construction to roof surfaces
        if not constr.create_and_assign_constructions(surfaces, runner, model)
            return false
        end
    
        return true
    end
    
    def self.apply_finished_roof(surfaces, runner, model, constr_name,
                                 cavity_r, install_grade, cavity_depth,
                                 filled_cavity, framing_factor, drywall_thick_in,
                                 osb_thick_in, rigid_r, rigid_thick_in, mat_roofing)
    
        return true if surfaces.empty?
    
        # Validate Inputs
        if cavity_r < 0.0
            runner.registerError("Cavity Insulation Installed R-value must be greater than or equal to 0.")
            return false
        end
        if cavity_depth <= 0.0
            runner.registerError("Cavity Depth must be greater than 0.")
            return false
        end    
        if framing_factor < 0.0 or framing_factor >= 1.0
            runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
            return false
        end

        # Define materials
        if cavity_r > 0
            if filled_cavity
                # Insulation
                mat_cavity = Material.new(name=nil, thick_in=cavity_depth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavity_depth / cavity_r)
            else
                # Insulation plus air gap when insulation thickness < cavity depth
                mat_cavity = Material.new(name=nil, thick_in=cavity_depth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavity_depth / (cavity_r + Gas.AirGapRvalue))
            end
        else
            # Empty cavity
            mat_cavity = Material.AirCavityClosed(cavity_depth)
        end
        mat_framing = Material.new(name=nil, thick_in=cavity_depth, mat_base=BaseMaterial.Wood)
        mat_gap = Material.AirCavityClosed(cavity_depth)
        mat_drywall = nil
        if drywall_thick_in > 0
            mat_drywall = Material.GypsumWall(drywall_thick_in)
        end
        mat_osb = nil
        if osb_thick_in > 0
            mat_osb = Material.new(name="Sheathing", thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
        end
        mat_rigid = nil
        if rigid_r > 0 and rigid_thick_in > 0
            mat_rigid = Material.new(name="RigidIns", thick_in=rigid_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=rigid_thick_in/rigid_r)
        end
        
        # Set paths
        gapFactor = get_gap_factor(install_grade, framing_factor, cavity_r)
        path_fracs = [framing_factor, 1 - framing_factor - gapFactor, gapFactor]
        
        # Define construction
        constr = Construction.new(constr_name, path_fracs)
        constr.add_layer(Material.AirFilmRoof(Geometry.get_roof_pitch(surfaces)))
        if not mat_drywall.nil?
            constr.add_layer(mat_drywall)
        end
        constr.add_layer([mat_framing, mat_cavity, mat_gap], "RoofIns")
        if not mat_osb.nil?
            constr.add_layer(mat_osb)
        end
        if not mat_rigid.nil?
            constr.add_layer(mat_rigid)
        end
        if not mat_roofing.nil?
            constr.add_layer(mat_roofing)
        end
        constr.add_layer(Material.AirFilmOutside)
        
        # Create and assign construction to surfaces
        if not constr.create_and_assign_constructions(surfaces, runner, model)
            return false
        end

        # Store info for HVAC Sizing measure
        surfaces.each do |surface|
            model.getBuildingUnits.each do |unit|
                next if unit.spaces.size == 0
                unit.setFeature(Constants.SizingInfoRoofCavityRvalue(surface), cavity_r)
            end
        end
        
        return true
    end
    
    def self.apply_uninsulated_roofs(surfaces, runner, model, constr_name,
                                 framing_thick_in, framing_factor,
                                 osb_thick_in, mat_roofing)
                                 
        return true if surfaces.empty?
    
        # Define materials
        mat_cavity = Material.AirCavityOpen(framing_thick_in)
        mat_framing = Material.new(name=nil, thick_in=framing_thick_in, mat_base=BaseMaterial.Wood)
        mat_osb = nil
        if osb_thick_in > 0
            mat_osb = Material.new(name="Sheathing", thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
        end

        # Set paths
        path_fracs = [framing_factor, 1 - framing_factor]
        
        # Define construction
        constr = Construction.new(constr_name, path_fracs)
        constr.add_layer(Material.AirFilmOutside)
        if not mat_roofing.nil?
            constr.add_layer(mat_roofing)
        end
        constr.add_layer(mat_osb)
        constr.add_layer([mat_framing, mat_cavity], "StudAndAirRoof")
        constr.add_layer(Material.AirFilmRoof(Geometry.get_roof_pitch(surfaces)))

        # Create and assign construction to surfaces
        if not constr.create_and_assign_constructions(surfaces, runner, model)
            return false
        end
    
        return true
    end

    def self.get_roofing_materials
        mats = []
        mats << Material.RoofingAsphaltShinglesDark
        mats << Material.RoofingAsphaltShinglesMed
        mats << Material.RoofingAsphaltShinglesLight
        mats << Material.RoofingAsphaltShinglesWhiteCool
        mats << Material.RoofingTileDark
        mats << Material.RoofingTileMed
        mats << Material.RoofingTileLight
        mats << Material.RoofingTileWhite
        mats << Material.RoofingMetalDark
        mats << Material.RoofingMetalMed
        mats << Material.RoofingMetalLight
        mats << Material.RoofingMetalWhite
        mats << Material.RoofingGalvanizedSteel
        return mats
    end
    
    def self.get_roofing_material(name)
        get_roofing_materials.each do |mat|
            next if mat.name != name
            return mat
        end
        return nil
    end
    
end

class FloorConstructions

    # Generic static methods for floor constructions
    
    def self.apply_unfinished_attic(surfaces, runner, model, constr_name,
                                    cavity_r, install_grade, ins_thick_in,
                                    framing_factor, joist_height_in,
                                    drywall_thick_in)
                                    
        return true if surfaces.empty?

        # Validate Inputs
        if cavity_r < 0.0
            runner.registerError("Ceiling Insulation Nominal R-value must be greater than or equal to 0.")
            return false
        end
        if ins_thick_in < 0.0
            runner.registerError("Ceiling Insulation Thickness must be greater than or equal to 0.")
            return false
        end
        if framing_factor < 0.0 or framing_factor >= 1.0
            runner.registerError("Ceiling Framing Factor must be greater than or equal to 0 and less than 1.")
            return false
        end
        if joist_height_in <= 0.0
            runner.registerError("Ceiling Joist Height must be greater than 0.")
            return false
        end
        
        # TODO: Attic perimeter derate is currently disabled
        # <- implementation goes here ->
      
        # Define materials
        mat_addtl_ins = nil
        if ins_thick_in >= joist_height_in
            # If the ceiling insulation thickness is greater than the joist thickness
            cavity_k = ins_thick_in / cavity_r
            if ins_thick_in > joist_height_in
                # If there is additional insulation beyond the rafter height,
                # these inputs are used for defining an additional layer
                mat_addtl_ins = Material.new(name="UAAdditionalCeilingIns", thick_in=(ins_thick_in - joist_height_in), mat_base=BaseMaterial.InsulationGenericLoosefill, k_in=cavity_k)
            end
            mat_cavity = Material.new(name=nil, thick_in=joist_height_in, mat_base=BaseMaterial.InsulationGenericLoosefill, k_in=cavity_k)
        else
            # Else the joist thickness is greater than the ceiling insulation thickness
            if cavity_r == 0
                mat_cavity = Material.AirCavityOpen(joist_height_in)
            else
                mat_cavity = Material.new(name=nil, thick_in=joist_height_in, mat_base=BaseMaterial.InsulationGenericLoosefill, k_in=joist_height_in / cavity_r)
            end
        end
        mat_framing = Material.new(name=nil, thick_in=joist_height_in, mat_base=BaseMaterial.Wood)
        mat_gap = Material.AirCavityOpen(joist_height_in)
        mat_drywall = nil
        if drywall_thick_in > 0
            mat_drywall = Material.GypsumWall(drywall_thick_in)
        end
        
        # Set paths
        gapFactor = get_gap_factor(install_grade, framing_factor, cavity_r)
        path_fracs = [framing_factor, 1 - framing_factor - gapFactor, gapFactor]
        
        # Define construction
        constr = Construction.new(constr_name, path_fracs)
        constr.add_layer(Material.AirFilmFloorAverage)
        if not mat_addtl_ins.nil?
            constr.add_layer(mat_addtl_ins)
        end
        constr.add_layer([mat_framing, mat_cavity, mat_gap], "UATrussandIns")
        if not mat_drywall.nil?
            constr.add_layer(mat_drywall)
        end
        constr.add_layer(Material.AirFilmFloorAverage)
        
        # Create and assign construction to ceiling surfaces
        if not constr.create_and_assign_constructions(surfaces, runner, model)
            return false
        end
        
        return true
    end

end

class Kiva

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
  
  private
  
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

class Construction

    # Facilitates creating and assigning an OpenStudio construction (with accompanying 
    # OpenStudio Materials) from Material objects. Handles parallel paths as well.

    def initialize(name, path_widths)
        @name = name
        @path_widths = path_widths
        @path_fracs = []
        @sum_path_fracs = @path_widths.inject(:+)
        path_widths.each do |path_width|
            @path_fracs << path_width / path_widths.inject{ |sum, n| sum + n }
        end
        @layers_names = []
        @layers_materials = []
    end
    
    def add_layer(materials, name=nil)
        # materials: Either a Material object or a list of Material objects
        # include_in_construction: false if the layer that should not be included in the
        #                          resulting construction but is used to calculate the 
        #                          effective R-value.
        # name: Name of the layer; required if multiple materials are provided. Otherwise the 
        #       Material.name will be used.
        if not materials.kind_of?(Array)
            @layers_materials << [materials]
            if not name.nil?
                @layers_names << name
            else
                @layers_names << materials.name
            end
        else
            @layers_materials << materials
            if not name.nil?
                @layers_names << name
            else
                @layers_names << "ParallelMaterial"
            end
        end
    end
    
    def assembly_rvalue(runner)
        # Calculate overall R-value for assembly
        if not validated?(runner)
            return nil
        end
        u_overall = 0
        @path_fracs.each_with_index do |path_frac,path_num|
            # For each parallel path, sum series:
            r_path = 0
            @layers_materials.each do |layer_materials|
                if layer_materials.size == 1
                    # One material for this layer
                    r_path += layer_materials[0].rvalue
                else
                    # Multiple parallel materials for this layer, use appropriate one
                    r_path += layer_materials[path_num].rvalue
                end
            end
            u_overall += 1.0 / r_path * path_frac
        end
        r_overall = 1.0 / u_overall
        return r_overall
    end
    
    # Creates constructions as needed and assigns to surfaces.
    # Leave name as nil if the materials (e.g., exterior finish) apply to multiple constructions.
    def create_and_assign_constructions(surfaces, runner, model)
    
        if not validated?(runner)
            return false
        end
        
        # Create list of OpenStudio materials
        materials = construct_materials(model, runner)
        
        # Create OpenStudio construction and assign to surface
        constr = OpenStudio::Model::Construction.new(model)
        constr.setName(@name)
        constr.setLayers(materials)
        revconstr = nil
        
        printed_constr = false
        printed_revconstr = false
        
        # Assign constructions to surfaces
        surfaces.each do |surface|
            surface.setConstruction(constr)
            if not printed_constr
                print_construction_creation(runner, surface)
                printed_constr = true
            end
            print_construction_assignment(runner, surface)

            # Assign reverse construction to adjacent surface as needed
            next if surface.is_a? OpenStudio::Model::SubSurface or surface.is_a? OpenStudio::Model::InternalMassDefinition or not surface.adjacentSurface.is_initialized
            if revconstr.nil?
                revconstr = constr.reverseConstruction
            end
            adjacent_surface = surface.adjacentSurface.get
            adjacent_surface.setConstruction(revconstr)
            if not printed_revconstr
                print_construction_creation(runner, adjacent_surface)
                printed_revconstr = true
            end
            print_construction_assignment(runner, adjacent_surface)
        end
        return true
    end
    
    private
    
        def get_parallel_material(curr_layer_num, runner, name)
            # Returns a Material object with effective properties for the specified
            # parallel path layer of the construction.
        
            mat = Material.new(name)
            
            curr_layer_materials = @layers_materials[curr_layer_num]
            
            r_overall = assembly_rvalue(runner)
            
            # Calculate individual R-values for each layer
            sum_r_all_layers = 0
            sum_r_parallel_layers = 0
            layer_rvalues = []
            @layers_materials.each do |layer_materials|
                u_path = 0
                layer_materials.each_with_index do |layer_material, idx|
                    if layer_materials.size > 1
                        u_path += @path_fracs[idx] / (layer_material.thick / layer_material.k)
                    else
                        u_path += 1.0 / (layer_material.thick / layer_material.k)
                    end
                end
                r_path = 1.0 / u_path
                layer_rvalues << r_path
                sum_r_all_layers += r_path
                if layer_materials.size > 1
                    sum_r_parallel_layers += r_path
                end
            end
            
            # Material R-value
            # Apportion R-value to the current parallel path layer
            mat.rvalue = layer_rvalues[curr_layer_num] + (r_overall - sum_r_all_layers) * layer_rvalues[curr_layer_num] / sum_r_parallel_layers
            
            # Material thickness and conductivity
            mat.thick_in = curr_layer_materials[0].thick_in # All paths have equal thickness
            mat.thick = curr_layer_materials[0].thick # All paths have equal thickness
            mat.k = mat.thick / mat.rvalue
            
            # Material density
            mat.rho = 0
            @path_fracs.each_with_index do |path_frac,path_num|
                mat.rho += curr_layer_materials[path_num].rho * path_frac
            end
            
            # Material specific heat
            mat.cp = 0
            @path_fracs.each_with_index do |path_frac,path_num|
                mat.cp += (curr_layer_materials[path_num].cp * curr_layer_materials[path_num].rho * path_frac) / mat.rho
            end
            
            return mat
        end

        def construct_materials(model, runner)
            # Create materials
            materials = []
            @layers_materials.each_with_index do |layer_materials,layer_num|
                if layer_materials.size == 1
                    next if layer_materials[0].name == Constants.AirFilm # Do not include air films in construction
                    mat = create_os_material(model, runner, layer_materials[0])
                else
                    parallel_path_mat = get_parallel_material(layer_num, runner, @layers_names[layer_num])
                    mat = create_os_material(model, runner, parallel_path_mat)
                end
                materials << mat
            end
            return materials
        end
        
        def validated?(runner)
            # Check that sum of path fracs equal 1
            if @sum_path_fracs <= 0.999 or @sum_path_fracs >= 1.001
                runner.registerError("Invalid construction: Sum of path fractions (#{@sum_path_fracs.to_s}) is not 1.")
                return false
            end
            
            # Check that all path fractions are not negative
            @path_fracs.each do |path_frac|
                if path_frac < 0
                    runner.registerError("Invalid construction: Path fraction (#{path_frac.to_s}) must be greater than or equal to 0.")
                    return false
                end
            end
            
            # Check if all materials are GlazingMaterial
            all_glazing = true
            @layers_materials.each do |layer_materials|
                layer_materials.each do |mat|
                    if not mat.is_a? GlazingMaterial
                        all_glazing = false
                    end
                end
            end
            if all_glazing
                # Check that no parallel materials
                @layers_materials.each do |layer_materials|
                    if layer_materials.size > 1
                        runner.registerError("Invalid construction: Cannot have multiple GlazingMaterials in a single layer.")
                        return false
                    end
                end
                return true
            end
        
            # Check for valid object types
            @layers_materials.each do |layer_materials|
                layer_materials.each do |mat|
                    if not mat.is_a? SimpleMaterial and not mat.is_a? Material
                        runner.registerError("Invalid construction: Materials must be instances of SimpleMaterial or Material classes.")
                        return false
                    end
                end
            end
            
            # Check if invalid number of materials in a layer
            @layers_materials.each do |layer_materials|
                if layer_materials.size > 1 and layer_materials.size < @path_fracs.size
                    runner.registerError("Invalid construction: Layer must either have one material or same number of materials as paths.")
                    return false
                end
            end
        
            # Check if multiple materials in a given layer have differing thicknesses
            @layers_materials.each do |layer_materials|
                if layer_materials.size > 1
                    thick_in = nil
                    layer_materials.each do |mat|
                        if thick_in.nil?
                            thick_in = mat.thick_in
                        elsif thick_in != mat.thick_in
                            runner.registerError("Invalid construction: Materials in a layer have different thicknesses.")
                            return false
                        end
                    end
                end
            end
            
            # Check if multiple non-contiguous parallel layers
            found_parallel = false
            last_parallel = false
            @layers_materials.each do |layer_materials|
                if layer_materials.size > 1
                    if not found_parallel
                        found_parallel = true
                    elsif not last_parallel
                        runner.registerError("Invalid construction: Non-contiguous parallel layers found.")
                        return false
                    end
                end
                last_parallel = (layer_materials.size > 1)
            end
            
            # If we got this far, we're good
            return true
        end
        
        # Creates (or returns an existing) OpenStudio Material from our own Material object
        def create_os_material(model, runner, material)
            name = material.name
            tolerance = 0.0001
            if material.is_a? SimpleMaterial
                # Material already exists?
                model.getMasslessOpaqueMaterials.each do |mat|
                    next if mat.name.to_s != name.to_s
                    next if mat.roughness.downcase.to_s != "rough"
                    next if (mat.thermalResistance - UnitConversions.convert(material.rvalue,"hr*ft^2*F/Btu","m^2*K/W")).abs > tolerance
                    return mat
                end
                # New material
                mat = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
                mat.setName(name)
                mat.setRoughness("Rough")
                mat.setThermalResistance(UnitConversions.convert(material.rvalue,"hr*ft^2*F/Btu","m^2*K/W"))
            elsif material.is_a? GlazingMaterial
                # Material already exists?
                model.getSimpleGlazings.each do |mat|
                    next if mat.name.to_s != name.to_s
                    next if (mat.uFactor - material.ufactor).abs > tolerance
                    next if (mat.solarHeatGainCoefficient - material.shgc).abs > tolerance
                    return mat
                end
                # New material
                mat = OpenStudio::Model::SimpleGlazing.new(model)
                mat.setName(name)
                mat.setUFactor(material.ufactor)
                mat.setSolarHeatGainCoefficient(material.shgc)
            else
                # Material already exists?
                model.getStandardOpaqueMaterials.each do |mat|
                    next if mat.name.to_s != name.to_s
                    next if mat.roughness.downcase.to_s != "rough"
                    next if (mat.thickness - UnitConversions.convert(material.thick_in,"in","m")).abs > tolerance
                    next if (mat.conductivity - UnitConversions.convert(material.k,"Btu/(hr*ft*R)","W/(m*K)")).abs > tolerance
                    next if (mat.density - UnitConversions.convert(material.rho,"lbm/ft^3","kg/m^3")).abs > tolerance
                    next if (mat.specificHeat - UnitConversions.convert(material.cp,"Btu/(lbm*R)","J/(kg*K)")).abs > tolerance
                    next if not material.tAbs.nil? and (mat.thermalAbsorptance - material.tAbs).abs > tolerance
                    next if not material.sAbs.nil? and (mat.solarAbsorptance - material.sAbs).abs > tolerance
                    next if not material.vAbs.nil? and (mat.visibleAbsorptance - material.vAbs).abs > tolerance
                    return mat
                end
                # New material
                mat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
                mat.setName(name)
                mat.setRoughness("Rough")
                mat.setThickness(UnitConversions.convert(material.thick_in,"in","m"))
                mat.setConductivity(UnitConversions.convert(material.k,"Btu/(hr*ft*R)","W/(m*K)"))
                mat.setDensity(UnitConversions.convert(material.rho,"lbm/ft^3","kg/m^3"))
                mat.setSpecificHeat(UnitConversions.convert(material.cp,"Btu/(lbm*R)","J/(kg*K)"))
                if not material.tAbs.nil?
                    mat.setThermalAbsorptance(material.tAbs)
                end
                if not material.sAbs.nil?
                    mat.setSolarAbsorptance(material.sAbs)
                end
                if not material.vAbs.nil?
                    mat.setVisibleAbsorptance(material.vAbs)
                end
            end
            runner.registerInfo("Material '#{mat.name.to_s}' was created.")
            return mat
        end

        def print_construction_creation(runner, surface)
            s = ""
            num_layers = surface.construction.get.to_LayeredConstruction.get.layers.size
            if num_layers > 1
                s = "s"
            end
            mats_s = ""
            surface.construction.get.to_LayeredConstruction.get.layers.each do |layer|
                mats_s += layer.name.to_s + " | "
            end
            mats_s.chomp!(" | ")
            runner.registerInfo("Construction '#{surface.construction.get.name.to_s}' was created with #{num_layers.to_s} material#{s.to_s} (#{mats_s.to_s}).")
        end
    
        def print_construction_assignment(runner, surface)
            if surface.is_a? OpenStudio::Model::SubSurface
                type_s = "SubSurface"
            elsif surface.is_a? OpenStudio::Model::InternalMassDefinition
                type_s = "InternalMassDefinition"
            else
                type_s = "Surface"
            end
            runner.registerInfo("#{type_s.to_s} '#{surface.name.to_s}' has been assigned construction '#{surface.construction.get.name.to_s}'.")
        end
        
end

def get_gap_factor(install_grade, framing_factor, cavity_r)
    if cavity_r <= 0
        return 0 # Gap factor only applies when there is cavity insulation
    elsif install_grade == 1
        return 0
    elsif install_grade == 2
        return 0.02 * (1 - framing_factor)
    elsif install_grade == 3
        return 0.05 * (1 - framing_factor)
    end
    return 0
end


def get_wall_surfaces_by_type(model, runner)

    surfaces = {
                Constants.SurfaceTypeWallExtInsFin=>[],
                Constants.SurfaceTypeWallExtInsUnfin=>[],
                Constants.SurfaceTypeWallExtUninsUnfin=>[],
                Constants.SurfaceTypeWallIntFinUninsFin=>[],
                Constants.SurfaceTypeWallIntUnfinUninsUnfin=>[],
                Constants.SurfaceTypeWallIntFinInsUnfin=>[],
               }
               
    model.getSpaces.each do |space|
        
        is_finished = Geometry.space_is_finished(space)
        
        space.surfaces.each do |surface|
        
            next if surface.surfaceType.downcase != "wall"
            
            is_exterior = (surface.outsideBoundaryCondition.downcase == "outdoors")
            is_adiabatic = (surface.outsideBoundaryCondition.downcase == "adiabatic")
        
            adjacent_space = nil
            if surface.adjacentSurface.is_initialized and surface.adjacentSurface.get.space.is_initialized
                adjacent_space = surface.adjacentSurface.get.space.get
            end
            is_interior = (not adjacent_space.nil?)
        
            # Exterior insulated finished
            if is_finished and is_exterior
                surfaces[Constants.SurfaceTypeWallExtInsFin] << surface
                
            # Exterior insulated unfinished
            elsif not is_finished and is_exterior and Geometry.is_unfinished_attic(space) and get_space_r_value(runner, space, "roofceiling").to_f > 5
                surfaces[Constants.SurfaceTypeWallExtInsUnfin] << surface
                
            # Exterior uninsulated unfinished
            elsif not is_finished and is_exterior
                surfaces[Constants.SurfaceTypeWallExtUninsUnfin] << surface
                
            # Interior finished uninsulated finished
            elsif is_finished and is_interior and Geometry.space_is_finished(adjacent_space)
                surfaces[Constants.SurfaceTypeWallIntFinUninsFin] << surface
                
            # Interior unfinished uninsulated unfinished
            elsif not is_finished and is_interior and Geometry.space_is_unfinished(adjacent_space)
                surfaces[Constants.SurfaceTypeWallIntUnfinUninsUnfin] << surface
            
            # Interior finished insulated unfinished
            elsif is_finished and is_interior and Geometry.space_is_unfinished(adjacent_space)
                surfaces[Constants.SurfaceTypeWallIntFinInsUnfin] << surface
            
            # Adiabatic finished
            elsif is_adiabatic and is_finished
                surfaces[Constants.SurfaceTypeWallIntFinUninsFin] << surface
            
            # Adiabatic unfinished
            elsif is_adiabatic and not is_finished
                surfaces[Constants.SurfaceTypeWallIntUnfinUninsUnfin] << surface
            
            end
        
        end
        
    end
    
    return surfaces
end

def get_roof_surfaces_by_type(model, runner)

    surfaces = {
                Constants.SurfaceTypeRoofFinInsExt=>[],
                Constants.SurfaceTypeRoofUnfinInsExt=>[],
                Constants.SurfaceTypeRoofUnfinUninsExt=>[],
               }
               
    model.getSpaces.each do |space|
        
        is_finished = Geometry.space_is_finished(space)
        above_grade = Geometry.space_is_above_grade(space)
        
        space.surfaces.each do |surface|
        
            next if surface.surfaceType.downcase != "roofceiling"
            
            is_exterior = (surface.outsideBoundaryCondition.downcase == "outdoors")
            is_adiabatic = (surface.outsideBoundaryCondition.downcase == "adiabatic")
        
            adjacent_space = nil
            if surface.adjacentSurface.is_initialized and surface.adjacentSurface.get.space.is_initialized
                adjacent_space = surface.adjacentSurface.get.space.get
            end
            is_interior = (not adjacent_space.nil?)
            
            # Exterior insulated finished
            if is_exterior and is_finished and above_grade
                surfaces[Constants.SurfaceTypeRoofFinInsExt] << surface
            
            # Exterior insulated unfinished
            elsif is_exterior and Geometry.is_unfinished_attic(space)
                surfaces[Constants.SurfaceTypeRoofUnfinInsExt] << surface
            
            # Exterior uninsulated unfinished
            elsif is_exterior
                surfaces[Constants.SurfaceTypeRoofUnfinUninsExt] << surface

            # Adiabatic
            elsif is_adiabatic
                surfaces[Constants.SurfaceTypeRoofUnfinUninsExt] << surface

            end
            
        end
        
    end
    
    return surfaces
end

def get_floor_surfaces_by_type(model, runner)

    surfaces = {
                Constants.SurfaceTypeFloorFinInsUnfin=>[],
               }
               
    model.getSpaces.each do |space|
        
        is_finished = Geometry.space_is_finished(space)
        above_grade = Geometry.space_is_above_grade(space)
        
        space.surfaces.each do |surface|
        
            next if surface.surfaceType.downcase != "floor"
            
            is_exterior = (surface.outsideBoundaryCondition.downcase == "outdoors")
            is_adiabatic = (surface.outsideBoundaryCondition.downcase == "adiabatic")
        
            adjacent_space = nil
            if surface.adjacentSurface.is_initialized and surface.adjacentSurface.get.space.is_initialized
                adjacent_space = surface.adjacentSurface.get.space.get
            end
            is_interior = (not adjacent_space.nil?)
        
            # Interior unfinished insulated finished
            if is_interior and Geometry.is_unfinished_attic(space) and Geometry.space_is_finished(adjacent_space)
                surfaces[Constants.SurfaceTypeFloorFinInsUnfin] << surface
               
            end
            
        end
        
    end
    
    return surfaces
end

def get_constructions_from_surfaces(surfaces)
    constructions = []
    surfaces.each do |surface|
        next if not surface.construction.is_initialized
        next if constructions.include?(surface.construction.get)
        constructions << surface.construction.get
    end
    return constructions
end

def get_materials_from_constructions(constructions)
    materials = []
    constructions.each do |construction|
        construction.to_LayeredConstruction.get.layers.each do |material|
            next if materials.include?(material)
            materials << material
        end
    end
    return materials
end

def get_space_r_value(runner, space, surface_type)
    # Get area-weighted space r-value
    sum_surface_ua = 0.0
    total_area = 0.0
    space.surfaces.each do |surface|
        next if surface.surfaceType.downcase != surface_type
        surf_area = UnitConversions.convert(surface.netArea,"m^2","ft^2")
        ufactor = get_surface_ufactor(runner, surface, surface_type)
        return nil if ufactor.nil?
        sum_surface_ua += surf_area * ufactor
        total_area += surf_area
    end
    return total_area / sum_surface_ua
end

def get_surface_ufactor(runner, surface, surface_type)
    if surface_type.downcase.include?("window")
        simple_glazing = get_window_simple_glazing(runner, surface)
        return nil if simple_glazing.nil?
        return UnitConversions.convert(simple_glazing.uFactor,"W/(m^2*K)","Btu/(hr*ft^2*F)")
    else
        if not surface.construction.is_initialized
            runner.registerError("Construction not assigned to '#{surface.name.to_s}'.")
            return nil
        end
        ufactor = UnitConversions.convert(surface.uFactor.get,"W/(m^2*K)","Btu/(hr*ft^2*F)")
        if surface.class.method_defined?('adjacentSurface') and surface.adjacentSurface.is_initialized
            # Use average u-factor of adjacent surface, as OpenStudio returns
            # two different values for, e.g., floor vs adjacent roofceiling
            if not surface.adjacentSurface.get.construction.is_initialized
                runner.registerError("Construction not assigned to '#{surface.adjacentSurface.get.name.to_s}'.")
                return nil
            end
            adjacent_ufactor = UnitConversions.convert(surface.adjacentSurface.get.uFactor.get,"W/(m^2*K)","Btu/(hr*ft^2*F)")
            return (ufactor + adjacent_ufactor) / 2.0
        end
        return ufactor
    end
end

def get_window_simple_glazing(runner, surface)
    if not surface.construction.is_initialized
        runner.registerError("Construction not assigned to '#{surface.name.to_s}'.")
        return nil
    end
    construction = surface.construction.get
    if not construction.to_LayeredConstruction.is_initialized
        runner.registerError("Expected LayeredConstruction for '#{surface.name.to_s}'.")
        return nil
    end
    window_layered_construction = construction.to_LayeredConstruction.get
    if not window_layered_construction.getLayer(0).to_SimpleGlazing.is_initialized
        runner.registerError("Expected SimpleGlazing for '#{surface.name.to_s}'.")
        return nil
    end
    simple_glazing = window_layered_construction.getLayer(0).to_SimpleGlazing.get
    return simple_glazing
end
