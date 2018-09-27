require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialAirflowTest < MiniTest::Test

  def mech_vent_none_new_options
    return {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
  end

  def test_no_hvac_equip
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>11, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemGlobalVariable"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "Material"=>1, "Surface"=>6, "Space"=>1, "Construction"=>1, "ThermalZone"=>1, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.074880, "Cw"=>0.140569, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>0}, "TerrainType"=>"Suburbs", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 4)
  end

  def test_non_ducted_hvac_equipment
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>11, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemGlobalVariable"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "Material"=>1, "Surface"=>6, "Construction"=>1, "ThermalZone"=>1, "Space"=>1, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.074880, "Cw"=>0.140569, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>0}, "TerrainType"=>"Suburbs", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_ElectricBaseboard.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 2)
    assert_includes(result.warnings.map{ |x| x.logMessage }, "No ducted HVAC equipment was found but ducts were specified. Overriding duct specification.")
  end

  def test_has_clothes_dryer
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>5, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC_ElecWHTank_ClothesWasher_ClothesDryer.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1)
  end

  def test_neighbors
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000087}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC_Neighbors.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_mech_vent_none
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["mech_vent_type"] = "none"
    expected_num_del_objects = {}
    expected_num_new_objects = mech_vent_none_new_options
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>1, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_mech_vent_supply
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["mech_vent_type"] = Constants.VentTypeSupply
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
    # test objects are removed correctly
    args_hash["mech_vent_type"] = "none"
    expected_num_del_objects = expected_num_new_objects
    expected_num_new_objects = mech_vent_none_new_options
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, {}, __method__, 1, 1)
  end

  def test_mech_vent_cfis
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["mech_vent_type"] = Constants.VentTypeCFIS
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>4, "EnergyManagementSystemProgram"=>4, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>26, "EnergyManagementSystemInternalVariable"=>1, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
    # test objects are removed correctly
    args_hash["mech_vent_type"] = "none"
    expected_num_del_objects = expected_num_new_objects
    expected_num_new_objects = mech_vent_none_new_options
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, {}, __method__, 1, 1)
  end

  def test_mech_vent_cfis_no_ducts
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["mech_vent_type"] = Constants.VentTypeCFIS
    result = _test_error("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_ElectricBaseboard.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "A CFIS ventilation system has been selected but the building does not have central, forced air equipment.")
  end

  def test_mech_vent_exhaust_ashrae_622_2013
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["mech_vent_ashrae_std"] = "2013"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
    # test objects are removed correctly
    args_hash["mech_vent_type"] = "none"
    expected_num_del_objects = expected_num_new_objects
    expected_num_new_objects = mech_vent_none_new_options
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, {}, __method__, 1, 1)
  end

  def test_existing_building
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["is_existing_home"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_crawl
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["crawl_ach"] = 0.1
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.093461, "Cw"=>0.108877, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"crawl zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_CS_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_pier_beam
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.091302, "Cw"=>0.108877, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000307}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"pier and beam zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_PB_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_ufbasement
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.0}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished basement zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_UB_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_duct_location_ufbasement
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_location"] = Constants.SpaceTypeUnfinishedBasement
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.0}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished basement zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_UB_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_fbasement
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["finished_basement_ach"] = 0.1
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.046322, "Cs"=>0.084549, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>120}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.0}, "TerrainType"=>"Suburbs", "DuctLocation"=>"finished basement zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_FB_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_duct_location_fbasement
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_location"] = Constants.SpaceTypeFinishedBasement
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.046322, "Cs"=>0.084549, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>120}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.0}, "TerrainType"=>"Suburbs", "DuctLocation"=>"finished basement zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_FB_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_duct_location_ufattic
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_location"] = Constants.SpaceTypeUnfinishedAttic
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone"}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_duct_location_in_living
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_location"] = Constants.SpaceTypeLiving
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>11, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemGlobalVariable"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "Material"=>1, "Surface"=>6, "ThermalZone"=>1, "Construction"=>1, "AirLoopHVACReturnPlenum"=>1, "Space"=>1, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "TerrainType"=>"Suburbs", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_terrain_ocean
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["terrain"] = Constants.TerrainOcean
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.001317}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Ocean", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_terrain_plains
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["terrain"] = Constants.TerrainPlains
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000725}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Country", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_terrain_rural
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["terrain"] = Constants.TerrainRural
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000487}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Country", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_terrain_city
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["terrain"] = Constants.TerrainCity
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000120}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"City", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_mech_vent_hrv
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["mech_vent_type"] = Constants.VentTypeBalanced
    args_hash["mech_vent_sensible_efficiency"] = 0.6
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "FanOnOff"=>2, "HeatExchangerAirToAirSensibleAndLatent"=>1, "ZoneHVACEnergyRecoveryVentilatorController"=>1, "ZoneHVACEnergyRecoveryVentilator"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "res mv_1 erv"=>{"SupAirRate"=>0.023597, "ExhAirRate"=>0.023597, "Priority"=>1}, "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
    # test objects are removed correctly
    args_hash["mech_vent_type"] = "none"
    expected_num_del_objects = expected_num_new_objects
    expected_num_new_objects = mech_vent_none_new_options
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, {}, __method__, 1, 1)
  end

  def test_mech_vent_erv
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["mech_vent_type"] = Constants.VentTypeBalanced
    args_hash["mech_vent_total_efficiency"] = 0.48
    args_hash["mech_vent_sensible_efficiency"] = 0.72
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "FanOnOff"=>2, "HeatExchangerAirToAirSensibleAndLatent"=>1, "ZoneHVACEnergyRecoveryVentilatorController"=>1, "ZoneHVACEnergyRecoveryVentilator"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "res mv_1 erv"=>{"SupAirRate"=>0.023597, "ExhAirRate"=>0.023597, "Priority"=>1}, "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
    # test objects are removed correctly
    args_hash["mech_vent_type"] = "none"
    expected_num_del_objects = expected_num_new_objects
    expected_num_new_objects = mech_vent_none_new_options
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, {}, __method__, 1, 1)
  end

  def test_nat_vent_0_wkdy_0_wked
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["nat_vent_num_weekdays"] = 0
    args_hash["nat_vent_num_weekends"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_nat_vent_1_wkdy_1_wked
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["nat_vent_num_weekdays"] = 1
    args_hash["nat_vent_num_weekends"] = 1
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_nat_vent_2_wkdy_2_wked
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["nat_vent_num_weekdays"] = 2
    args_hash["nat_vent_num_weekends"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_nat_vent_4_wkdy
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["nat_vent_num_weekdays"] = 4
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_nat_vent_5_wkdy
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["nat_vent_num_weekdays"] = 5
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_ductless_mini_split_heat_pump_no_ducts # miniSplitHPIsDucted=false, duct_location=none
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_location"] = "none"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>11, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemGlobalVariable"=>2, "ThermalZone"=>1, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "TerrainType"=>"Suburbs", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_MSHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_ductless_mini_split_heat_pump_has_ducts # miniSplitHPIsDucted=false, duct_location=auto (OVERRIDE)
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>11, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemGlobalVariable"=>2, "ThermalZone"=>1, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "TerrainType"=>"Suburbs", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_MSHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 2)
  end

  def test_ducted_mini_split_heat_pump_no_ducts # miniSplitHPIsDucted=true, duct_location=none (ERROR)
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_location"] = "none"
    result = _test_error("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_MSHPDucted.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Ducted mini-split heat pump selected but no ducts were selected.")
  end

  def test_ducted_mini_split_heat_pump_has_ducts # miniSplitHPIsDucted=true, duct_location=auto
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>19, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_MSHPDucted.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_duct_location_frac
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_location"] = Constants.SpaceTypeUnfinishedAttic
    args_hash["duct_location_frac"] = "0.5"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.109990, "f_ret"=>0.100099, "f_OA"=>0.009890}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_return_loss_greater_than_supply_loss
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_supply_frac"] = 0.067
    args_hash["duct_return_frac"] = 0.6
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.033132, "f_ret"=>0.259840, "f_OA"=>0.226707}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_duct_num_returns
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_num_returns"] = "1"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>30}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_no_living_garage_attic_infiltration
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["living_ach50"] = 0
    args_hash["garage_ach50"] = 0
    args_hash["unfinished_attic_sla"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.0}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_GRG_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_garage_with_attic
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>2, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_GRG_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_garage_without_attic
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.05, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000229, "Cw"=>0.000319}, "res ds_1 ret air zone"=>{"RADuctVol"=>120}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"garage zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_GRG_FR_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_error_duct_total_leakage_invalid
    args_hash = {}
    args_hash["duct_total_leakage"] = -0.00001
    result = _test_error("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Ducts: Total Leakage must be greater than or equal to 0.")
  end

  def test_error_duct_supply_leakage_frac_invalid
    args_hash = {}
    args_hash["duct_supply_frac"] = -0.00001
    result = _test_error("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Ducts: Supply Leakage Fraction of Total must be greater than or equal to 0 and less than or equal to 1.")
  end

  def test_error_duct_return_leakage_frac_invalid
    args_hash = {}
    args_hash["duct_return_frac"] = -0.00001
    result = _test_error("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Ducts: Return Leakage Fraction of Total must be greater than or equal to 0 and less than or equal to 1.")
  end

  def test_error_duct_supply_ah_leakage_frac_invalid
    args_hash = {}
    args_hash["duct_ah_supply_frac"] = -0.00001
    result = _test_error("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Ducts: Supply Air Handler Leakage Fraction of Total must be greater than or equal to 0 and less than or equal to 1.")
  end

  def test_error_duct_return_ah_leakage_frac_invalid
    args_hash = {}
    args_hash["duct_ah_return_frac"] = -0.00001
    result = _test_error("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Ducts: Return Air Handler Leakage Fraction of Total must be greater than or equal to 0 and less than or equal to 1.")
  end

  def test_error_duct_r_value_invalid
    args_hash = {}
    args_hash["duct_r"] = -0.00001
    result = _test_error("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Ducts: Insulation Nominal R-Value must be greater than or equal to 0.")
  end

  def test_error_duct_supply_surface_area_mult_invalid
    args_hash = {}
    args_hash["duct_supply_area_mult"] = -0.00001
    result = _test_error("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Ducts: Supply Surface Area Multiplier must be greater than or equal to 0.")
  end

  def test_error_duct_return_surface_area_mult_invalid
    args_hash = {}
    args_hash["duct_return_area_mult"] = -0.00001
    result = _test_error("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Ducts: Return Surface Area Multiplier must be greater than or equal to 0.")
  end

  def test_retrofit_infiltration
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["mech_vent_type"] = Constants.VentTypeBalanced
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "FanOnOff"=>2, "ZoneHVACEnergyRecoveryVentilatorController"=>1, "HeatExchangerAirToAirSensibleAndLatent"=>1, "ZoneHVACEnergyRecoveryVentilator"=>1, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.069658, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
    args_hash["living_ach50"] = 3
    args_hash["mech_vent_type"] = Constants.VentTypeBalanced
    expected_num_del_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "FanOnOff"=>2, "ZoneHVACEnergyRecoveryVentilatorController"=>1, "HeatExchangerAirToAirSensibleAndLatent"=>1, "ZoneHVACEnergyRecoveryVentilator"=>1, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_num_new_objects = {"ScheduleRuleset"=>4, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>20, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "FanOnOff"=>2, "ZoneHVACEnergyRecoveryVentilatorController"=>1, "HeatExchangerAirToAirSensibleAndLatent"=>1, "ZoneHVACEnergyRecoveryVentilator"=>1, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.029853, "Cs"=>0.086238, "Cw"=>0.128435, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000179, "Cw"=>0.000282}, "res ds_1 ret air zone"=>{"RADuctVol"=>90}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.136963, "f_ret"=>0.100099, "f_OA"=>0.036863}, "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, 1)
  end

  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>num_units*4, "EnergyManagementSystemSubroutine"=>num_units*1, "EnergyManagementSystemProgramCallingManager"=>num_units*2, "EnergyManagementSystemProgram"=>num_units*3, "EnergyManagementSystemSensor"=>71, "EnergyManagementSystemActuator"=>num_units*17, "EnergyManagementSystemGlobalVariable"=>num_units*23, "SpaceInfiltrationDesignFlowRate"=>num_units*2, "ZoneMixing"=>num_units*2, "OtherEquipment"=>num_units*10, "OtherEquipmentDefinition"=>num_units*10, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Surface"=>num_units*6, "Space"=>num_units*1, "ThermalZone"=>num_units*1, "AirLoopHVACReturnPlenum"=>num_units*1, "Material"=>1, "ElectricEquipmentDefinition"=>num_units*3, "ElectricEquipment"=>num_units*3, "SurfacePropertyConvectionCoefficients"=>num_units*6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.042099, "Cs"=>0.066417, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000089, "Cw"=>0.000199}, "res ds_1 ret air zone"=>{"RADuctVol"=>34}, "res_ds_1_lk_subrout"=>{"f_sup"=>0.199900, "f_ret"=>0.100099, "f_OA"=>0.099800}, \
                       "res_infil_2_program"=>{"c"=>0.020801, "Cs"=>0.066417, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_2_program"=>{"Cs"=>0.000089, "Cw"=>0.000199}, "res ds_2 ret air zone"=>{"RADuctVol"=>34}, "res_ds_2_lk_subrout"=>{"f_sup"=>0.199900, "f_ret"=>0.100099, "f_OA"=>0.099800}, \
                       "res_infil_3_program"=>{"c"=>0.020801, "Cs"=>0.066417, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_3_program"=>{"Cs"=>0.000089, "Cw"=>0.000199}, "res ds_3 ret air zone"=>{"RADuctVol"=>34}, "res_ds_3_lk_subrout"=>{"f_sup"=>0.199900, "f_ret"=>0.100099, "f_OA"=>0.099800}, \
                       "res_infil_4_program"=>{"c"=>0.042099, "Cs"=>0.066417, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_4_program"=>{"Cs"=>0.000089, "Cw"=>0.000199}, "res ds_4 ret air zone"=>{"RADuctVol"=>34}, "res_ds_4_lk_subrout"=>{"f_sup"=>0.199900, "f_ret"=>0.100099, "f_OA"=>0.099800}, \
                       "TerrainType"=>"Suburbs", "DuctLocation"=>"unfinished attic zone", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("SFA_4units_1story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, num_units)
  end

  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>num_units*4, "EnergyManagementSystemProgramCallingManager"=>num_units*2, "EnergyManagementSystemProgram"=>num_units*3, "EnergyManagementSystemSensor"=>67, "EnergyManagementSystemActuator"=>num_units*5, "EnergyManagementSystemGlobalVariable"=>num_units*2, "SpaceInfiltrationDesignFlowRate"=>num_units*2, "ElectricEquipmentDefinition"=>num_units*3, "ElectricEquipment"=>num_units*3, "Surface"=>num_units*6, "Material"=>1, "Space"=>num_units*1, "AirLoopHVACReturnPlenum"=>num_units*1, "ThermalZone"=>num_units*1, "Construction"=>1, "SurfacePropertyConvectionCoefficients"=>num_units*6, "MaterialPropertyMoisturePenetrationDepthSettings"=>1}
    expected_values = {"res_infil_1_program"=>{"c"=>0.047360, "Cs"=>0.049758, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_1_program"=>{"Cs"=>0.000089, "Cw"=>0.000199}, \
                       "res_infil_2_program"=>{"c"=>0.047360, "Cs"=>0.049758, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_2_program"=>{"Cs"=>0.000089, "Cw"=>0.000199}, \
                       "res_infil_3_program"=>{"c"=>0.015540, "Cs"=>0.049758, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_3_program"=>{"Cs"=>0.000089, "Cw"=>0.000199}, \
                       "res_infil_4_program"=>{"c"=>0.015540, "Cs"=>0.049758, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_4_program"=>{"Cs"=>0.000089, "Cw"=>0.000199}, \
                       "res_infil_5_program"=>{"c"=>0.015540, "Cs"=>0.049758, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_5_program"=>{"Cs"=>0.000089, "Cw"=>0.000199}, \
                       "res_infil_6_program"=>{"c"=>0.015540, "Cs"=>0.049758, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_6_program"=>{"Cs"=>0.000089, "Cw"=>0.000199}, \
                       "res_infil_7_program"=>{"c"=>0.047360, "Cs"=>0.049758, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_7_program"=>{"Cs"=>0.000089, "Cw"=>0.000199}, \
                       "res_infil_8_program"=>{"c"=>0.047360, "Cs"=>0.049758, "Cw"=>0.128435, "faneff_wh"=>0.943894, "faneff_sp"=>0.471947}, "res_nv_8_program"=>{"Cs"=>0.000089, "Cw"=>0.000199}, \
                       "TerrainType"=>"Suburbs", "Adiabatic"=>{"WaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.waterVaporDiffusionResistanceFactor, "MoistureEquationCoefficientA"=>BaseMaterial.Adiabatic.moistureEquationCoefficientA, "MoistureEquationCoefficientB"=>BaseMaterial.Adiabatic.moistureEquationCoefficientB, "MoistureEquationCoefficientC"=>BaseMaterial.Adiabatic.moistureEquationCoefficientC, "MoistureEquationCoefficientD"=>BaseMaterial.Adiabatic.moistureEquationCoefficientD, "CoatingLayerThickness"=>BaseMaterial.Adiabatic.coatingLayerThickness, "CoatingLayerWaterVaporDiffusionResistanceFactor"=>BaseMaterial.Adiabatic.coatingLayerWaterVaporDiffusionResistanceFactor}}
    model, result = _test_measure("MF_8units_1story_SL_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, 1, num_units)
  end

  private

  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ResidentialAirflow.new

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

    # show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)

    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, test_name, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialAirflow.new

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
    
    # show the output
    # show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert_equal(num_infos, result.info.size)
    assert_equal(num_warnings, result.warnings.size)

    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = ["ScheduleDay", "ZoneHVACEquipmentList", "PortList", "Node", "SizingZone", "ScheduleConstant", "ScheduleTypeLimits", "CurveCubic", "CurveExponent", "ScheduleRule"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)

    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    check_ems(model)

    actual_values = {}

    all_new_objects.each do |obj_type, new_objects|
      new_objects.each do |new_object|
        next if not new_object.respond_to?("to_#{obj_type}")
        new_object = new_object.public_send("to_#{obj_type}").get
        unless actual_values.keys.include? new_object.name.to_s
          actual_values[new_object.name.to_s] = {}
        end
        if ["EnergyManagementSystemProgram", "EnergyManagementSystemSubroutine"].include? obj_type
          new_object.lines.each do |line|
            next unless line.downcase.start_with? "set"
            lhs, rhs = line.split("=")
            lhs = lhs.gsub("Set", "").gsub("set", "").strip
            rhs = rhs.gsub(",", "").gsub(";", "").strip
            actual_values[new_object.name.to_s][lhs] = rhs
          end
        elsif obj_type == "EnergyManagementSystemSensor"
          next if new_object.outputVariableOrMeterName != "Zone Air Temperature"
          actual_values["DuctLocation"] = new_object.keyName
        elsif obj_type == "ThermalZone"
          actual_values[new_object.name.to_s]["RADuctVol"] = UnitConversions.convert(new_object.volume.get, "m^3", "ft^3")
        elsif obj_type == "ZoneHVACEnergyRecoveryVentilator"
          actual_values[new_object.name.to_s]["SupAirRate"] = new_object.supplyAirFlowRate
          actual_values[new_object.name.to_s]["ExhAirRate"] = new_object.exhaustAirFlowRate
          model.getThermalZones.each do |thermal_zone|
            heating_seq = thermal_zone.equipmentInHeatingOrder.index(new_object)
            next if heating_seq.nil?
            actual_values[new_object.name.to_s]["Priority"] = heating_seq+1
          end
        elsif obj_type == "MaterialPropertyMoisturePenetrationDepthSettings"
          actual_values["Adiabatic"]["WaterVaporDiffusionResistanceFactor"] = new_object.waterVaporDiffusionResistanceFactor
          actual_values["Adiabatic"]["MoistureEquationCoefficientA"] = new_object.moistureEquationCoefficientA
          actual_values["Adiabatic"]["MoistureEquationCoefficientB"] = new_object.moistureEquationCoefficientB
          actual_values["Adiabatic"]["MoistureEquationCoefficientC"] = new_object.moistureEquationCoefficientC
          actual_values["Adiabatic"]["MoistureEquationCoefficientD"] = new_object.moistureEquationCoefficientD
          actual_values["Adiabatic"]["CoatingLayerThickness"] = new_object.coatingLayerThickness
          actual_values["Adiabatic"]["CoatingLayerWaterVaporDiffusionResistanceFactor"] = new_object.coatingLayerWaterVaporDiffusionResistanceFactor
        end
      end
    end
    actual_values["TerrainType"] = model.getSite.terrain.to_s
    if not expected_values["WaterVaporDiffusionResistanceFactor"].nil?
      assert_in_epsilon(expected_values["WaterVaporDiffusionResistanceFactor"], actual_values["WaterVaporDiffusionResistanceFactor"], 0.01)
    end
    if not expected_values["MoistureEquationCoefficientA"].nil?
      assert_in_epsilon(expected_values["MoistureEquationCoefficientA"], actual_values["MoistureEquationCoefficientA"], 0.01)
    end
    if not expected_values["MoistureEquationCoefficientB"].nil?
      assert_in_epsilon(expected_values["MoistureEquationCoefficientB"], actual_values["MoistureEquationCoefficientB"], 0.01)
    end
    if not expected_values["MoistureEquationCoefficientC"].nil?
      assert_in_epsilon(expected_values["MoistureEquationCoefficientC"], actual_values["MoistureEquationCoefficientC"], 0.01)
    end
    if not expected_values["MoistureEquationCoefficientD"].nil?
      assert_in_epsilon(expected_values["MoistureEquationCoefficientD"], actual_values["MoistureEquationCoefficientD"], 0.01)
    end
    if not expected_values["CoatingLayerThickness"].nil?
      assert_in_epsilon(expected_values["CoatingLayerThickness"], actual_values["CoatingLayerThickness"], 0.01)
    end
    if not expected_values["CoatingLayerWaterVaporDiffusionResistanceFactor"].nil?
      assert_in_epsilon(expected_values["CoatingLayerWaterVaporDiffusionResistanceFactor"], actual_values["CoatingLayerWaterVaporDiffusionResistanceFactor"], 0.01)
    end

    expected_values.each do |obj_name, values|
      if values.respond_to? :to_str
        assert_equal(values, actual_values[obj_name])
      else
        values.each do |lhs, rhs|
          assert_in_epsilon(rhs, actual_values[obj_name][lhs].to_f, 0.0125)
        end
      end
    end

    return model, result
  end

end
