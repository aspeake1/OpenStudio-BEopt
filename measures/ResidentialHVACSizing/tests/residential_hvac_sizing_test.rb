require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

# TODO: Update expected_values due to windspeed and foundation (and internal gains?) changes.

class ProcessHVACSizingTest < MiniTest::Test

  def beopt_to_os_mapping
    return {
            "DehumidLoad_Inf_Sens"=>["Unit 1 Zone Loads","Dehumid Infil Sens"],
            "DehumidLoad_Inf_Lat"=>["Unit 1 Zone Loads","Dehumid Infil Lat"],
            "DehumidLoad_Int_Sens"=>["Unit 1 Zone Loads","Dehumid IntGains Sens"],
            "DehumidLoad_Int_Lat"=>["Unit 1 Zone Loads","Dehumid IntGains Lat"],
            "Heat Windows"=>["Unit 1 Zone Loads","Heat Windows"],
            "Heat Doors"=>["Unit 1 Zone Loads","Heat Doors"],
            "Heat Walls"=>["Unit 1 Zone Loads","Heat Walls"],
            "Heat Roofs"=>["Unit 1 Zone Loads","Heat Roofs"],
            "Heat Floors"=>["Unit 1 Zone Loads","Heat Floors"],
            "Heat Infil"=>["Unit 1 Zone Loads","Heat Infil"],
            "Dehumid Windows"=>["Unit 1 Zone Loads","Dehumid Windows"],
            "Dehumid Doors"=>["Unit 1 Zone Loads","Dehumid Doors"],
            "Dehumid Walls"=>["Unit 1 Zone Loads","Dehumid Walls"],
            "Dehumid Roofs"=>["Unit 1 Zone Loads","Dehumid Roofs"],
            "Dehumid Floors"=>["Unit 1 Zone Loads","Dehumid Floors"],
            "Cool Windows"=>["Unit 1 Zone Loads","Cool Windows"],
            "Cool Doors"=>["Unit 1 Zone Loads","Cool Doors"],
            "Cool Walls"=>["Unit 1 Zone Loads","Cool Walls"],
            "Cool Roofs"=>["Unit 1 Zone Loads","Cool Roofs"],
            "Cool Floors"=>["Unit 1 Zone Loads","Cool Floors"],
            "Cool Infil Sens"=>["Unit 1 Zone Loads","Cool Infil Sens"],
            "Cool Infil Lat"=>["Unit 1 Zone Loads","Cool Infil Lat"],
            "Cool IntGains Sens"=>["Unit 1 Zone Loads","Cool IntGains Sens"],
            "Cool IntGains Lat"=>["Unit 1 Zone Loads","Cool IntGains Lat"],
            "Heat Load"=>["Unit 1 Initial Results (w/o ducts)","Heat Load"],
            "Cool Load Sens"=>["Unit 1 Initial Results (w/o ducts)","Cool Load Sens"],
            "Cool Load Lat"=>["Unit 1 Initial Results (w/o ducts)","Cool Load Lat"],
            "Dehumid Load Sens"=>["Unit 1 Initial Results (w/o ducts)","Dehumid Load Sens"],
            "Dehumid Load Lat"=>["Unit 1 Initial Results (w/o ducts)","Dehumid Load Lat"],
            "Heat Airflow"=>["Unit 1 Initial Results (w/o ducts)","Heat Airflow"],
            "Cool Airflow"=>["Unit 1 Initial Results (w/o ducts)","Cool Airflow"],
            "HeatingLoad"=>["Unit 1 Final Results","Heat Load"],
            "HeatingDuctLoad"=>["Unit 1 Final Results","Heat Load Ducts"],
            "CoolingLoad_Lat"=>["Unit 1 Final Results","Cool Load Lat"],
            "CoolingLoad_Sens"=>["Unit 1 Final Results","Cool Load Sens"],
            "CoolingLoad_Ducts_Lat"=>["Unit 1 Final Results","Cool Load Ducts Lat"],
            "CoolingLoad_Ducts_Sens"=>["Unit 1 Final Results","Cool Load Ducts Sens"],
            "DehumidLoad_Sens"=>["Unit 1 Final Results","Dehumid Load Sens"],
            "DehumidLoad_Ducts_Lat"=>["Unit 1 Final Results","Dehumid Load Ducts Lat"],
            "Cool_Capacity"=>["Unit 1 Final Results","Cool Capacity"],
            "Cool_SensCap"=>["Unit 1 Final Results","Cool Capacity Sens"],
            "Heat_Capacity"=>["Unit 1 Final Results","Heat Capacity"],
            "SuppHeat_Capacity"=>["Unit 1 Final Results","Heat Capacity Supp"],
            "Cool_AirFlowRate"=>["Unit 1 Final Results","Cool Airflow"],
            "Heat_AirFlowRate"=>["Unit 1 Final Results","Heat Airflow"],
            "Dehumid_WaterRemoval_Auto"=>["Unit 1 Final Results","Dehumid WaterRemoval"]
           }
  end

  def volume_adj_factor(os_above_grade_finished_volume)
    # TODO: For buildings with finished attic space, BEopt calculates a larger volume
    # than OpenStudio, so we adjust here. Haven't looked into why this occurs.
    beopt_finished_attic_volume = 2644.625
    os_finished_attic_volume = 2392.6
    living_volume = os_above_grade_finished_volume - os_finished_attic_volume
    return (beopt_finished_attic_volume + living_volume) / (os_finished_attic_volume + living_volume)
  end

  def test_loads_2story_finished_basement_garage_finished_attic
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_2story_FB_GRG_FA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_loads_2story_finished_basement_garage_finished_attic_ducts_in_fininshed_basement
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_2story_FB_GRG_FA_ASHP_DuctsInFB.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_loads_2story_unfinished_basement_garage_finished_attic
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_2story_UB_GRG_FA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_loads_2story_unfinished_basement_garage_finished_attic_ducts_in_unfinished_basement
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_2story_UB_GRG_FA_ASHP_DuctsInUB.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_loads_2story_crawlspace_garage_finished_attic
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_2story_CS_GRG_FA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end
  
  def test_loads_2story_crawlspace_garage_finished_attic_skylights
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_2story_CS_GRG_FA_Skylights.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_loads_2story_crawlspace_garage_flat_roof_skylights
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_2story_CS_GRG_FlatRoof_Skylights.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_loads_2story_crawlspace_garage_finished_attic_ducts_in_crawl
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_2story_CS_GRG_FA_ASHP_DuctsInCS.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_loads_2story_crawlspace_garage_finished_attic_ducts_in_living
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_2story_CS_GRG_FA_ASHP_DuctsInLiv.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_loads_2story_crawlspace_garage_finished_attic_ducts_in_garage
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_2story_CS_GRG_FA_ASHP_DuctsInGRG.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_loads_2story_slab_garage_finished_attic
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_2story_S_GRG_FA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_loads_1story_slab_unfinished_attic_vented
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Vented.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_slab_unfinished_attic_unvented_roof_ins
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_InsRoof.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_slab_unfinished_attic_unvented_no_overhangs_no_interior_shading_no_mech_vent
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_NoOverhangs_NoIntShading_NoMechVent.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_slab_unfinished_attic_unvented_no_overhangs_no_interior_shading_supply_mech_vent
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_NoOverhangs_NoIntShading_SupplyMechVent.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_slab_unfinished_attic_unvented_no_overhangs_no_interior_shading_erv
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_NoOverhangs_NoIntShading_ERV.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_slab_unfinished_attic_unvented_no_overhangs_no_interior_shading_hrv
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Unvented_NoOverhangs_NoIntShading_HRV.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_slab_unfinished_attic_vented_atlanta_darkextfin
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Vented_Atlanta_ExtFinDark.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_slab_unfinished_attic_vented_losangeles
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_1story_S_UA_Vented_LosAngeles.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_pierbeam_unfinished_attic_vented
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_1story_PB_UA_Vented.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_pierbeam_unfinished_attic_vented_ducts_in_pierbeam
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_1story_PB_UA_Vented_ASHP_DuctsInPB.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_1story_pierbeam_unfinished_attic_vented_ducts_in_unfinished_attic
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Load_1story_PB_UA_Vented_ASHP_DuctsInUA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_single_family_attached
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFA_HVACSizing_Load_4units_1story_FB_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_loads_multifamily
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("MF_HVACSizing_Load_8units_1story_UB.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, false)
  end

  def test_equip_ASHP_one_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHP1_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_ASHP_one_speed_autosize_min_temp
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHP1_Autosize_MinTemp.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_ASHP_one_speed_autosize_for_max_load_min_temp
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHP1_AutosizeForMaxLoad_MinTemp.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_ASHP_one_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHP1_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_ASHP_two_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHP2_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_ASHP_two_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHP2_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_ASHP_variable_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHPV_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_ASHP_variable_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_ASHPV_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_GSHP_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_GSHP_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_GSHP_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_GSHP_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_electric_baseboard_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_BB_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_electric_baseboard_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_BB_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_electric_boiler_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_ElecBoiler_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_electric_boiler_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_ElecBoiler_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_gas_boiler_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_GasBoiler_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_gas_boiler_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_GasBoiler_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_unit_heater_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_UnitHeater_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_unit_heater_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_UnitHeater_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_unit_heater_fixedsize_with_fan
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_UnitHeater_Fixed_wFan.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_unit_heater_ac_one_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_UnitHeater_AC1_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_unit_heater_ac_one_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_UnitHeater_AC1_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_gas_furnace_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_gas_furnace_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_gas_furnace_and_ac_one_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_AC1_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_gas_furnace_and_ac_one_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_AC1_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_electric_furnace_and_ac_two_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_EF_AC2_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_electric_furnace_and_ac_two_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_EF_AC2_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_gas_furnace_and_ac_variable_speed_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_ACV_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_gas_furnace_and_ac_variable_speed_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_ACV_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_gas_furnace_and_room_air_conditioner_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_RAC_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_gas_furnace_and_room_air_conditioner_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_GF_RAC_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_mshp_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_MSHP_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_ducted_mshp_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_MSHPDucted_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_mshp_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_MSHP_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_mshp_autosize_for_max_load
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_MSHP_AutosizeForMaxLoad.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_mshp_and_electric_baseboard_autosize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_MSHP_BB_Autosize.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_mshp_and_electric_baseboard_fixedsize
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_MSHP_BB_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_dehumidifier_autosize_atlanta
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_Dehumidifier_Auto_Atlanta.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_equip_dehumidifier_fixedsize_atlanta
    args_hash = {}
    args_hash["show_debug_info"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {
                      }
    _test_measure("SFD_HVACSizing_Equip_Dehumidifier_Fixed_Atlanta.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, true)
  end

  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "No building geometry has been defined.")
  end

  def test_error_missing_weather
    args_hash = {}
    result = _test_error("SFD_2000sqft_2story_FB_UA.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Model has not been assigned a weather file.")
  end

  def test_error_missing_construction
    args_hash = {}
    result = _test_error("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Construction not assigned to 'Surface 13'.")
  end

  private

  def _test_error(osm_file_or_model, args_hash)

    print_debug_info = false # set to true for more detailed output

    # create an instance of the measure
    measure = ProcessHVACSizing.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    if print_debug_info
      show_output(result)
    end

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)

    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, apply_volume_adj=false)

    print_debug_info = false # set to true for more detailed output

    # create an instance of the measure
    measure = ProcessHVACSizing.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    
    if print_debug_info
        show_output(result)
    end

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)

    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)

    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get

        end
    end

    # TODO: Tighten these tolerances eventually?
    airflow_tolerance = 75 # cfm
    load_component_tolerance = 250 # Btu/hr
    load_total_tolerance = 2000 # Btu/hr
    water_removal_tolerance = 3 # L/day
    energy_factor_tolerance = 0.1 # L/kWh
    ua_tolerance = 20 # W/K
    length_tolerance = 30 # ft

    # Compare intermediate values to result.info values
    map = beopt_to_os_mapping()
    expected_values.each do |beopt_key, beopt_val|
        next if map[beopt_key].nil?
        os_header = map[beopt_key][0]
        os_key = map[beopt_key][1]
        os_val = 0.0
        os_val_found = false
        result.info.map{ |x| x.logMessage }.each do |info|
            next if not info.split("\n")[0].downcase.start_with?(os_header.downcase)
            info.split("\n").each do |info_line|
                infos = info_line.split('=')
                next if infos[0].strip != os_key
                os_val += infos[1].strip.to_f
                os_val_found = true
            end
        end
        assert(os_val_found)

        if apply_volume_adj
            if ['Heat Infil','Cool Infil Sens','Cool Infil Lat'].include?(beopt_key)
                os_above_grade_finished_volume = Geometry.get_above_grade_finished_volume(model)
                os_val = os_val * volume_adj_factor(os_above_grade_finished_volume)
            end
        end

        if print_debug_info
            puts "#{os_header}: #{os_key}: #{beopt_val.round(0)} (Expected) vs. #{os_val.round(0)} (Actual)"
        end

        if os_key.downcase.include?("water")
            assert_in_delta(beopt_val, os_val, water_removal_tolerance)
        elsif os_key.downcase.include?("airflow")
            assert_in_delta(beopt_val, os_val, airflow_tolerance)
        elsif os_header.downcase.include?("results")
            assert_in_delta(beopt_val, os_val, load_total_tolerance)
        else
            assert_in_delta(beopt_val, os_val, load_component_tolerance)
        end
    end

    # Check model object values
    flowrate_units = "{m3/s}"
    capacity_units = "{W}"
    water_removal_units = "{L/day}"
    energy_factor_units = "{L/kWh}"
    ua_units = "{W/K}"
    length_units = "{m}"
    expected_values.each do |beopt_key, beopt_val|
        next if !map[beopt_key].nil?
        os_val = 0.0
        htg_val = 0.0
        clg_val = 0.0

        is_flowrate = false
        is_capacity = false
        is_water_removal = false
        is_energy_factor = false
        is_ua = false
        is_length = false
        is_unitless = false
        if beopt_key.include?(flowrate_units)
            is_flowrate = true
        elsif beopt_key.include?(capacity_units)
            is_capacity = true
        elsif beopt_key.include?(water_removal_units)
            is_water_removal = true
        elsif beopt_key.include?(energy_factor_units)
            is_energy_factor = true
        elsif beopt_key.include?(ua_units)
            is_ua = true
        elsif beopt_key.include?(length_units)
            is_length = true
        elsif !beopt_key.include?("{") and !beopt_key.include?("}")
            is_unitless = true
        else
            puts "WARNING: Unhandled key type: #{beopt_key}."
            next
        end

        if beopt_key == 'AirLoopHVAC_Design Supply Air Flow rate {m3/s}'
            model.getAirLoopHVACUnitarySystems.each do |system|
                next unless system.airLoopHVAC.is_initialized
                if system.heatingCoil.is_initialized
                    htg_val += system.airLoopHVAC.get.designSupplyAirFlowRate.get
                elsif system.coolingCoil.is_initialized
                    clg_val += system.airLoopHVAC.get.designSupplyAirFlowRate.get
                end
            end
            os_val += [htg_val, clg_val].max
        
        elsif beopt_key == 'AirLoopHVAC:UnitarySystem_Supply Air Flow Rate During Cooling Operation {m3/s}'
            model.getAirLoopHVACUnitarySystems.each do |system|
                os_val += system.supplyAirFlowRateDuringCoolingOperation.get
            end

        elsif beopt_key.start_with?('AirLoopHVAC:UnitarySystem:MultiSpeed_Speed') and beopt_key.end_with?('Supply Air Flow Rate During Cooling Operation {m3/s}')
            next

        elsif beopt_key == 'AirLoopHVAC:UnitarySystem_Supply Air Flow Rate During Heating Operation {m3/s}'
            model.getAirLoopHVACUnitarySystems.each do |system|
                os_val += system.supplyAirFlowRateDuringHeatingOperation.get
            end

        elsif beopt_key.start_with?('AirLoopHVAC:UnitarySystem:MultiSpeed_Speed') and beopt_key.end_with?('Supply Air Flow Rate During Heating Operation {m3/s}')
            next

        elsif beopt_key == 'GroundHeatExchanger:Vertical_Design Flow Rate {m3/s}'
            model.getGroundHeatExchangerVerticals.each do |ghex|
                os_val += ghex.designFlowRate.get
            end

        elsif beopt_key == 'GroundHeatExchanger:Vertical_Bore Hole Length {m}'
            model.getGroundHeatExchangerVerticals.each do |ghex|
                length = ghex.boreHoleLength.get
                # Evaluate total bore length (bore hole length * num bore holes)
                numholes = ghex.numberofBoreHoles.get
                os_val += length * numholes
            end
            beopt_val *= expected_values['GroundHeatExchanger:Vertical_Number of Bore Holes']

        elsif beopt_key == 'GroundHeatExchanger:Vertical_Number of Bore Holes'
            next # captured above in total bore length

        elsif beopt_key == 'Coil:Heating:Fuel_Nominal Capacity {W}'
            model.getCoilHeatingGass.each do |coil|
                os_val += coil.nominalCapacity.get
            end

        elsif beopt_key == 'Coil:Heating:Electric_Nominal Capacity {W}'
            model.getCoilHeatingElectrics.each do |coil|
                os_val += coil.nominalCapacity.get
            end

        elsif beopt_key == 'Coil:Heating:DX:SingleSpeed_Rated Total Heating Capacity {W}'
            model.getCoilHeatingDXSingleSpeeds.each do |coil|
                os_val += coil.ratedTotalHeatingCapacity.get
            end

        elsif beopt_key.start_with?('Coil:Heating:DX:MultiSpeed_Speed') and beopt_key.end_with?('Rated Total Heating Capacity {W}')
            if model.getCoilHeatingDXMultiSpeeds.size > 0
                speed = beopt_key.split(" ")[1].to_i
                model.getCoilHeatingDXMultiSpeeds.each do |coil|
                    os_val += coil.stages[speed-1].grossRatedHeatingCapacity.get
                end
            elsif model.getCoilHeatingElectrics.size > 0
                # Electric furnace with multi-speed AC modeled as HP in BEopt
                model.getCoilHeatingElectrics.each do |coil|
                    os_val += coil.nominalCapacity.get
                end
            elsif model.getCoilHeatingGass.size > 0
                # Gas furnace with multi-speed AC modeled as HP in BEopt
                model.getCoilHeatingGass.each do |coil|
                    os_val += coil.nominalCapacity.get
                end
            end

        elsif beopt_key == 'Coil:Heating:DX:SingleSpeed_Rated Air Flow Rate {m3/s}'
            model.getCoilHeatingDXSingleSpeeds.each do |coil|
                os_val += coil.ratedAirFlowRate.get
            end

        elsif beopt_key == 'Coil:Heating:WaterToAirHeatPump:EquationFit_Rated Heating Capacity {W}'
            model.getCoilHeatingWaterToAirHeatPumpEquationFits.each do |coil|
                os_val += coil.ratedHeatingCapacity.get
            end

        elsif beopt_key == 'Coil:Cooling:WaterToAirHeatPump:EquationFit_Rated Total Cooling Capacity {W}'
            model.getCoilCoolingWaterToAirHeatPumpEquationFits.each do |coil|
                os_val += coil.ratedTotalCoolingCapacity.get
            end

        elsif beopt_key.start_with?('Coil:Heating:DX:MultiSpeed_Speed') and beopt_key.end_with?('Rated Air Flow Rate {m3/s}')
            if model.getCoilHeatingDXMultiSpeeds.size > 0
                speed = beopt_key.split(" ")[1].to_i
                model.getCoilHeatingDXMultiSpeeds.each do |coil|
                    os_val += coil.stages[speed-1].ratedAirFlowRate.get
                end
            elsif model.getCoilHeatingElectrics.size > 0
                # Electric furnace with multi-speed AC modeled as HP in BEopt
                next # no airflow property
            elsif model.getCoilHeatingGass.size > 0
                # Gas furnace with multi-speed AC modeled as HP in BEopt
                next # no airflow property
            end

        elsif beopt_key == 'CondenserLoop_Maximum Loop Flow Rate {m3/s}'
            model.getPlantLoops.each do |pl|
                next if !pl.name.to_s.downcase.include?('condenser')
                os_val += pl.maximumLoopFlowRate.get
            end

        elsif beopt_key == 'Coil:Heating:WaterToAirHeatPump:EquationFit_Rated Air Flow Rate {m3/s}'
            model.getCoilHeatingWaterToAirHeatPumpEquationFits.each do |coil|
                os_val += coil.ratedAirFlowRate.get
            end

        elsif beopt_key == 'Coil:Heating:WaterToAirHeatPump:EquationFit_Rated Water Flow Rate {m3/s}'
            model.getCoilHeatingWaterToAirHeatPumpEquationFits.each do |coil|
                os_val += coil.ratedWaterFlowRate.get
            end

        elsif beopt_key == 'Coil:Cooling:WaterToAirHeatPump:EquationFit_Rated Water Flow Rate {m3/s}'
            model.getCoilCoolingWaterToAirHeatPumpEquationFits.each do |coil|
                os_val += coil.ratedWaterFlowRate.get
            end

        elsif beopt_key == 'Coil:Cooling:DX:SingleSpeed_Rated Total Cooling Capacity {W}'
            model.getCoilCoolingDXSingleSpeeds.each do |coil|
                os_val += coil.ratedTotalCoolingCapacity.get
            end

        elsif beopt_key.start_with?('Coil:Cooling:DX:MultiSpeed_Speed') and beopt_key.end_with?('Rated Total Cooling Capacity {W}')
            speed = beopt_key.split(" ")[1].to_i
            model.getCoilCoolingDXMultiSpeeds.each do |coil|
                os_val += coil.stages[speed-1].grossRatedTotalCoolingCapacity.get
            end

        elsif beopt_key == 'Coil:Cooling:DX:SingleSpeed_Rated Air Flow Rate {m3/s}'
            model.getCoilCoolingDXSingleSpeeds.each do |coil|
                os_val += coil.ratedAirFlowRate.get
            end

        elsif beopt_key.start_with?('Coil:Cooling:DX:MultiSpeed_Speed') and beopt_key.end_with?('Rated Air Flow Rate {m3/s}')
            speed = beopt_key.split(" ")[1].to_i
            model.getCoilCoolingDXMultiSpeeds.each do |coil|
                os_val += coil.stages[speed-1].ratedAirFlowRate.get
            end

        elsif beopt_key == 'ZoneHVAC:Baseboard:Convective:Electric_Living_Heating Design Capacity {W}'
            model.getZoneHVACBaseboardConvectiveElectrics.each do |bb|
                next if bb.name.to_s.downcase.include?('basement')
                os_val += bb.nominalCapacity.get
            end

        elsif beopt_key == 'ZoneHVAC:Baseboard:Convective:Electric_Basement_Heating Design Capacity {W}'
            model.getZoneHVACBaseboardConvectiveElectrics.each do |bb|
                next if !bb.name.to_s.downcase.include?('basement')
                os_val += bb.nominalCapacity.get
            end

        elsif beopt_key == 'ZoneHVAC:WindowAirConditioner_Airflow'
            model.getZoneHVACPackagedTerminalAirConditioners.each do |ptac|
                os_val += ptac.supplyAirFlowRateDuringCoolingOperation.get
            end

        elsif beopt_key == 'AirTerminal:SingleDuct:Uncontrolled_Living_Maximum Flow Rate {m3/s}'
            model.getAirTerminalSingleDuctUncontrolleds.each do |term|
                next if term.name.to_s.downcase.include?('basement')
                model.getAirLoopHVACUnitarySystems.each do |system|
                    next unless system.airLoopHVAC.is_initialized
                    next if term.airLoopHVAC.get != system.airLoopHVAC.get
                    if system.heatingCoil.is_initialized
                        htg_val += term.maximumAirFlowRate.get
                    elsif system.coolingCoil.is_initialized
                        clg_val += term.maximumAirFlowRate.get
                    end
                end
            end
            os_val += [htg_val, clg_val].max

        elsif beopt_key == 'AirTerminal:SingleDuct:Uncontrolled_Basement_Maximum Flow Rate {m3/s}'
            model.getAirTerminalSingleDuctUncontrolleds.each do |term|
                next if !term.name.to_s.downcase.include?('basement')
                model.getAirLoopHVACUnitarySystems.each do |system|
                    next unless system.airLoopHVAC.is_initialized
                    next if term.airLoopHVAC.get != system.airLoopHVAC.get
                    if system.heatingCoil.is_initialized
                        htg_val += term.maximumAirFlowRate.get
                    elsif system.coolingCoil.is_initialized
                        clg_val += term.maximumAirFlowRate.get
                    end
                end
            end
            os_val += [htg_val, clg_val].max

        elsif beopt_key == 'Fan:OnOff_Maximum Flow Rate {m3/s}'
            model.getFanOnOffs.each do |fan|
                next if !fan.name.to_s.downcase.include?('room ac')
                os_val += fan.maximumFlowRate.get
            end

        elsif beopt_key == 'Fan:OnOff_Living_Maximum Flow Rate {m3/s}'
            model.getFanOnOffs.each do |fan|
                next if fan.name.to_s.downcase.include?('basement') or fan.name.to_s.downcase.include?('room ac')
                if fan.endUseSubcategory == Constants.EndUseHVACHeatingFan
                    htg_val += fan.maximumFlowRate.get
                elsif fan.endUseSubcategory == Constants.EndUseHVACCoolingFan
                    clg_val += fan.maximumFlowRate.get
                end
            end
            os_val += [htg_val, clg_val].max

        elsif beopt_key == 'Fan:OnOff_Basement_Maximum Flow Rate {m3/s}'
            model.getFanOnOffs.each do |fan|
                next if !fan.name.to_s.downcase.include?('basement')
                if fan.endUseSubcategory == Constants.EndUseHVACHeatingFan
                    os_val += fan.maximumFlowRate.get
                end
            end

        elsif beopt_key == 'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}'
            model.getAirConditionerVariableRefrigerantFlows.each do |vrf|
                next if vrf.name.to_s.downcase.include?('basement')
                os_val += vrf.ratedTotalCoolingCapacity.get
            end

        elsif beopt_key == 'AirConditioner:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}'
            model.getAirConditionerVariableRefrigerantFlows.each do |vrf|
                next if vrf.name.to_s.downcase.include?('basement')
                os_val += vrf.ratedTotalHeatingCapacity.get
            end

        elsif beopt_key == 'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}'
            model.getAirConditionerVariableRefrigerantFlows.each do |vrf|
                next if !vrf.name.to_s.downcase.include?('basement')
                os_val += vrf.ratedTotalCoolingCapacity.get
            end

        elsif beopt_key == 'AirConditioner:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}'
            model.getAirConditionerVariableRefrigerantFlows.each do |vrf|
                next if !vrf.name.to_s.downcase.include?('basement')
                os_val += vrf.ratedTotalHeatingCapacity.get
            end

        elsif beopt_key == 'Coil:Heating:DX:VariableRefrigerantFlow_Living_Gross Rated Total Heating Capacity {W}'
            model.getCoilHeatingDXVariableRefrigerantFlows.each do |vrf|
                next if vrf.name.to_s.downcase.include?('basement')
                os_val += vrf.ratedTotalHeatingCapacity.get
            end

        elsif beopt_key == 'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Gross Rated Total Cooling Capacity {W}'
            model.getCoilCoolingDXVariableRefrigerantFlows.each do |vrf|
                next if vrf.name.to_s.downcase.include?('basement')
                os_val += vrf.ratedTotalCoolingCapacity.get
            end

        elsif beopt_key == 'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Heating Capacity {W}'
            model.getCoilHeatingDXVariableRefrigerantFlows.each do |vrf|
                next if !vrf.name.to_s.downcase.include?('basement')
                os_val += vrf.ratedTotalHeatingCapacity.get
            end

        elsif beopt_key == 'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Gross Rated Total Cooling Capacity {W}'
            model.getCoilCoolingDXVariableRefrigerantFlows.each do |vrf|
                next if !vrf.name.to_s.downcase.include?('basement')
                os_val += vrf.ratedTotalCoolingCapacity.get
            end

        elsif beopt_key == 'Coil:Heating:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}'
            model.getCoilHeatingDXVariableRefrigerantFlows.each do |vrf|
                next if vrf.name.to_s.downcase.include?('basement')
                os_val += vrf.ratedAirFlowRate.get
            end

        elsif beopt_key == 'Coil:Cooling:DX:VariableRefrigerantFlow_Living_Rated Air Flow Rate {m3/s}'
            model.getCoilCoolingDXVariableRefrigerantFlows.each do |vrf|
                next if vrf.name.to_s.downcase.include?('basement')
                os_val += vrf.ratedAirFlowRate.get
            end

        elsif beopt_key == 'Coil:Heating:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}'
            model.getCoilHeatingDXVariableRefrigerantFlows.each do |vrf|
                next if !vrf.name.to_s.downcase.include?('basement')
                os_val += vrf.ratedAirFlowRate.get
            end

        elsif beopt_key == 'Coil:Cooling:DX:VariableRefrigerantFlow_Basement_Rated Air Flow Rate {m3/s}'
            model.getCoilCoolingDXVariableRefrigerantFlows.each do |vrf|
                next if !vrf.name.to_s.downcase.include?('basement')
                os_val += vrf.ratedAirFlowRate.get
            end

        elsif beopt_key == 'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Cooling Supply Air Flow Rate {m3/s}'
            model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |term|
                next if term.name.to_s.downcase.include?('basement')
                os_val += term.supplyAirFlowRateDuringCoolingOperation.get
            end

        elsif beopt_key == 'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Living_Heating Supply Air Flow Rate {m3/s}'
            model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |term|
                next if term.name.to_s.downcase.include?('basement')
                os_val += term.supplyAirFlowRateDuringHeatingOperation.get
            end

        elsif beopt_key == 'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Cooling Supply Air Flow Rate {m3/s}'
            model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |term|
                next if !term.name.to_s.downcase.include?('basement')
                os_val += term.supplyAirFlowRateDuringCoolingOperation.get
            end

        elsif beopt_key == 'ZoneHVAC:TerminalUnit:VariableRefrigerantFlow_Basement_Heating Supply Air Flow Rate {m3/s}'
            model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |term|
                next if !term.name.to_s.downcase.include?('basement')
                os_val += term.supplyAirFlowRateDuringHeatingOperation.get
            end

        elsif beopt_key == 'ZoneHVAC:WindowAirConditioner_Maximum Supply Air Flow Rate {m3/s}'
            model.getZoneHVACPackagedTerminalAirConditioners.each do |ptac|
                os_val += ptac.supplyAirFlowRateDuringCoolingOperation.get
            end

        elsif beopt_key == 'ZoneHVAC:Dehumidifier:DX_Rated Water Removal {L/day}'
            model.getZoneHVACDehumidifierDXs.each do |dehum|
                os_val += dehum.ratedWaterRemoval
            end

        elsif beopt_key == 'ZoneHVAC:Dehumidifier:DX_Rated Energy Factor {L/kWh}'
            model.getZoneHVACDehumidifierDXs.each do |dehum|
                os_val += dehum.ratedEnergyFactor
            end

        elsif beopt_key == 'ZoneHVAC:Dehumidifier:DX_Rated Air Flow Rate {m3/s}'
            model.getZoneHVACDehumidifierDXs.each do |dehum|
                os_val += dehum.ratedAirFlowRate
            end

        elsif beopt_key == 'Pump:VariableSpeed_Design Flow Rate {m3/s}'
            model.getPumpVariableSpeeds.each do |pump|
                next if !pump.name.to_s.downcase.include?('boiler') and !pump.name.to_s.downcase.include?('gshp')
                os_val += pump.ratedFlowRate.get
            end

        elsif beopt_key == 'Boiler:HotWater_Nomimal Capacity {W}'
            model.getBoilerHotWaters.each do |boiler|
                os_val += boiler.nominalCapacity.get
            end

        elsif beopt_key == 'ZoneHVAC:Baseboard:Convective:Water_Living_U-Factor Times Area Value {W/K}'
            model.getZoneHVACBaseboardConvectiveWaters.each do |bb|
                next if bb.name.to_s.downcase.include?('basement')
                os_val += bb.heatingCoil.to_CoilHeatingWaterBaseboard.get.uFactorTimesAreaValue.get
            end

        elsif beopt_key == 'ZoneHVAC:Baseboard:Convective:Water_Living_Maximum Water Flow rate {m3/s}'
            model.getZoneHVACBaseboardConvectiveWaters.each do |bb|
                next if bb.name.to_s.downcase.include?('basement')
                os_val += bb.heatingCoil.to_CoilHeatingWaterBaseboard.get.maximumWaterFlowRate.get
            end

        elsif beopt_key == 'ZoneHVAC:Baseboard:Convective:Water_Basement_U-Factor Times Area Value {W/K}'
            model.getZoneHVACBaseboardConvectiveWaters.each do |bb|
                next if !bb.name.to_s.downcase.include?('basement')
                os_val += bb.heatingCoil.to_CoilHeatingWaterBaseboard.get.uFactorTimesAreaValue.get
            end

        elsif beopt_key == 'ZoneHVAC:Baseboard:Convective:Water_Basement_Maximum Water Flow rate {m3/s}'
            model.getZoneHVACBaseboardConvectiveWaters.each do |bb|
                next if !bb.name.to_s.downcase.include?('basement')
                os_val += bb.heatingCoil.to_CoilHeatingWaterBaseboard.get.maximumWaterFlowRate.get
            end

        elsif beopt_key.start_with?('GroundHeatExchanger:Vertical_Pair') and beopt_key.end_with?('GFNC')
            pair_num = beopt_key.gsub('GroundHeatExchanger:Vertical_Pair','').gsub('GFNC','').to_i
            model.getGroundHeatExchangerVerticals.each do |ghex|
                gfunction = ghex.gFunctions
                os_val += gfunction[pair_num-1].gValue
            end

        else
            puts "WARNING: Unhandled key: #{beopt_key}."
            next

        end

        str = ""
        if is_flowrate
            str = "#{beopt_key.gsub(flowrate_units,'').strip}: #{beopt_val.round(3)} (Expected) vs. #{os_val.round(3)} (Actual)"
            os_val = UnitConversions.convert(os_val,"m^3/s","cfm")
            beopt_val = UnitConversions.convert(beopt_val,"m^3/s","cfm")
            tolerance = airflow_tolerance
        elsif is_capacity
            str = "#{beopt_key.gsub(capacity_units,'').strip}: #{beopt_val.round(0)} (Expected) vs. #{os_val.round(0)} (Actual)"
            os_val = UnitConversions.convert(os_val,"W","Btu/hr")
            beopt_val = UnitConversions.convert(beopt_val,"W","Btu/hr")
            tolerance = load_total_tolerance
        elsif is_water_removal
            str = "#{beopt_key.gsub(water_removal_units,'').strip}: #{beopt_val.round(1)} (Expected) vs. #{os_val.round(1)} (Actual)"
            tolerance = water_removal_tolerance
        elsif is_energy_factor
            str = "#{beopt_key.gsub(energy_factor_units,'').strip}: #{beopt_val.round(1)} (Expected) vs. #{os_val.round(1)} (Actual)"
            tolerance = energy_factor_tolerance
        elsif is_ua
            str = "#{beopt_key.gsub(ua_units,'').strip}: #{beopt_val.round(0)} (Expected) vs. #{os_val.round(0)} (Actual)"
            tolerance = ua_tolerance
        elsif is_length
            str = "#{beopt_key.gsub(length_units,'').strip}: #{beopt_val.round(0)} (Expected) vs. #{os_val.round(0)} (Actual)"
            os_val = UnitConversions.convert(os_val,"m","ft")
            beopt_val = UnitConversions.convert(beopt_val,"m","ft")
            tolerance = length_tolerance
        elsif is_unitless
            str = "#{beopt_key.strip}: #{beopt_val.round(0)} (Expected) vs. #{os_val.round(0)} (Actual)"
            tolerance = 0
        end
        if print_debug_info
            puts str
        end
        assert_in_delta(beopt_val, os_val, tolerance)
    end

    return model
  end

end
