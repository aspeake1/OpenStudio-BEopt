require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class UtilityBillCalculationsTest < MiniTest::Test

  # BEopt building:
  # - 600 sq ft (30 x 20), Denver EPW
  # - Propane cooking range
  # - Oil Standard water heater
  # - USA_CO_Denver.Intl.AP EPW location
  # - All other options left at default values
  # Then retrieve 1.csv from output folder, change headers to OpenStudio headers, and subtract Produced column from Facility column

  $hourly_output = true

  def test_simple_calculations_0kW_pv_net_metering
    args_hash = {}
    args_hash["electric_bill_type"] = "Simple"
    args_hash["elec_fixed"] = "8.0"
    args_hash["elec_rate"] = Constants.Auto
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_None.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>96+568.5, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

  def test_simple_calculations_1kW_pv_net_metering
    args_hash = {}
    args_hash["electric_bill_type"] = "Simple"
    args_hash["elec_fixed"] = "8.0"
    args_hash["elec_rate"] = Constants.Auto
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>96+568.5-160.24, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end
  
  def test_simple_calculations_10kW_pv_net_metering
    args_hash = {}
    args_hash["electric_bill_type"] = "Simple"
    args_hash["elec_fixed"] = "8.0"
    args_hash["elec_rate"] = Constants.Auto
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>96+568.5-857.139526, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

  def test_simple_calculations_10kW_pv_net_metering_retail_sellback
    args_hash = {}
    args_hash["electric_bill_type"] = "Simple"
    args_hash["elec_fixed"] = "8.0"
    args_hash["elec_rate"] = Constants.Auto
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_annual_excess_sellback_rate_type"] = Constants.RetailElectricityCost
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>96+568.5-1607.76, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

  def test_simple_calculations_1kW_pv_feed_in_tariff
    args_hash = {}
    args_hash["electric_bill_type"] = "Simple"
    args_hash["elec_fixed"] = "8.0"
    args_hash["elec_rate"] = Constants.Auto
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    args_hash["pv_tariff_rate"] = "0.12"
    timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>96+568.5-178.01, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

  def test_simple_calculations_10kW_pv_feed_in_tariff
    args_hash = {}
    args_hash["electric_bill_type"] = "Simple"
    args_hash["elec_fixed"] = "8.0"
    args_hash["elec_rate"] = Constants.Auto
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    args_hash["pv_tariff_rate"] = "0.12"
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {Constants.FuelTypeElectric=>96+568.5-1786.08, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end
  
  def test_detailed_error_invalid_location
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586bda1b5457a3ef521c9605.json", __FILE__)
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    weather_file_state = "AB"
    timeseries = get_timeseries(File.expand_path("../PV_None.csv", __FILE__))
    result = _test_error(timeseries, args_hash, weather_file_state)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Rates do not exist for state/province/region '#{weather_file_state}'.")
  end
  
  def test_detailed_error_invalid_tariff
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../539f75f7ec4f024411ed19fd.json", __FILE__)
    timeseries = get_timeseries(File.expand_path("../PV_None.csv", __FILE__))
    result = _test_error(timeseries, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Does not contain charges: City of Linneus, Missouri (Utility Company) - Electric Rate.")
  end
  
  def test_detailed_error_no_tariffs_found
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../Imaginary Tariff.json", __FILE__)
    timeseries = get_timeseries(File.expand_path("../PV_None.csv", __FILE__))
    result = _test_error(timeseries, args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Could not locate tariff(s).")
  end

  def test_detailed_calculations_0kW_pv_net_metering_custom_tariff_tiered
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586bda1b5457a3ef521c9605.json", __FILE__) # Southern California Edison Co - Domestic Service: D - Baseline Region 5
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_None.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>11.16+696.43, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

  def test_detailed_calculations_1kW_pv_net_metering_custom_tariff_tiered
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586bda1b5457a3ef521c9605.json", __FILE__) # Southern California Edison Co - Domestic Service: D - Baseline Region 5
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>11.16+696.43-196, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end
  
  def test_detailed_calculations_10kW_pv_net_metering_custom_tariff_tiered # TODO: fails, calculating: -277.4794921875
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586bda1b5457a3ef521c9605.json", __FILE__) # Southern California Edison Co - Domestic Service: D - Baseline Region 5
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>11.16+696.43-696.43, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end
  
  def test_detailed_calculations_10kW_pv_net_metering_custom_tariff_retail_sellback_tiered # TODO: fails, calculating 11.160000801086426 (pretty sure beopt is incorrectly round the production credit)
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586bda1b5457a3ef521c9605.json", __FILE__) # Southern California Edison Co - Domestic Service: D - Baseline Region 5
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_annnual_excess_sellback_rate_type"] = Constants.RetailElectricityCost
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>11.16+696.43-696, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

  def test_detailed_calculations_1kW_pv_feed_in_tariff_custom_tariff_tiered
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586bda1b5457a3ef521c9605.json", __FILE__) # Southern California Edison Co - Domestic Service: D - Baseline Region 5
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    args_hash["pv_tariff_rate"] = "0.12"
    timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>11.16+696.43-178.02, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end
  
  def test_detailed_calculations_10kW_pv_feed_in_tariff_custom_tariff_tiered
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586bda1b5457a3ef521c9605.json", __FILE__) # Southern California Edison Co - Domestic Service: D - Baseline Region 5
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    args_hash["pv_tariff_rate"] = "0.12"
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>11.16+696.43-1786.09, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

  def test_detailed_calculations_0kW_pv_net_metering_custom_tariff_tou
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../539f6d9eec4f024411ecb875.json", __FILE__) # Georgia Power Co - Schedule TOU-REO-7 - Time of Use - Residential
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_None.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>108+482.85, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

  def test_detailed_calculations_1kW_pv_net_metering_custom_tariff_tou # TODO: fails, calculating: 451.69952392578125
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../539f6d9eec4f024411ecb875.json", __FILE__) # Georgia Power Co - Schedule TOU-REO-7 - Time of Use - Residential
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>108+482.85-131, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end
  
  def test_detailed_calculations_10kW_pv_net_metering_custom_tariff_tou # TODO: fails, calculating: -180.63949584960938
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../539f6d9eec4f024411ecb875.json", __FILE__) # Georgia Power Co - Schedule TOU-REO-7 - Time of Use - Residential
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>108+482.85-482.85, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end
  
  def test_detailed_calculations_10kW_pv_net_metering_custom_tariff_retail_sellback_tou # TODO: fails, calculating: 108.0
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../539f6d9eec4f024411ecb875.json", __FILE__) # Georgia Power Co - Schedule TOU-REO-7 - Time of Use - Residential
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_annnual_excess_sellback_rate_type"] = Constants.RetailElectricityCost
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>108+482.85-1317, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

  def test_detailed_calculations_1kW_pv_feed_in_tariff_custom_tariff_tou
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../539f6d9eec4f024411ecb875.json", __FILE__) # Georgia Power Co - Schedule TOU-REO-7 - Time of Use - Residential
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    args_hash["pv_tariff_rate"] = "0.12"
    timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>108+482.85-178.02, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end
  
  def test_detailed_calculations_10kW_pv_feed_in_tariff_custom_tariff_tou
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../539f6d9eec4f024411ecb875.json", __FILE__) # Georgia Power Co - Schedule TOU-REO-7 - Time of Use - Residential
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    args_hash["pv_tariff_rate"] = "0.12"
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>108+482.85-1786.09, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

  def test_detailed_calculations_0kW_pv_net_metering_custom_tariff_tiered_tou # TODO: fails, calculating: 757.5201416015625
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586be0bd5457a30d661c9605.json", __FILE__) # Southern California Edison Co - Time-of-use Tiered Domestic: TOU-D-T-Region 5
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_None.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>11.16+751.78, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

  def test_detailed_calculations_1kW_pv_net_metering_custom_tariff_tiered_tou # TODO: fails, calculating: 501.4223327636719
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586be0bd5457a30d661c9605.json", __FILE__) # Southern California Edison Co - Time-of-use Tiered Domestic: TOU-D-T-Region 5
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>11.16+751.78-237, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end
  
  def test_detailed_calculations_10kW_pv_net_metering_custom_tariff_tiered_tou # TODO: fails, calculating: -277.4794921875
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586be0bd5457a30d661c9605.json", __FILE__) # Southern California Edison Co - Time-of-use Tiered Domestic: TOU-D-T-Region 5
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>11.16+751.78-751.78, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end
  
  def test_detailed_calculations_10kW_pv_net_metering_custom_tariff_retail_sellback_tiered_tou # TODO: fails, calculating: 11.160000801086426 (pretty sure beopt is incorrectly round the production credit)
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586be0bd5457a30d661c9605.json", __FILE__) # Southern California Edison Co - Time-of-use Tiered Domestic: TOU-D-T-Region 5
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>11.16+751.78-752, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

  def test_detailed_calculations_1kW_pv_feed_in_tariff_custom_tariff_tiered_tou # TODO: fails, calculating: 579.501708984375
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586be0bd5457a30d661c9605.json", __FILE__) # Southern California Edison Co - Time-of-use Tiered Domestic: TOU-D-T-Region 5
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    args_hash["pv_tariff_rate"] = "0.12"
    timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>11.16+751.78-178.02, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end
  
  def test_detailed_calculations_10kW_pv_feed_in_tariff_custom_tariff_tiered_tou
    args_hash = {}
    args_hash["electric_bill_type"] = "Detailed"
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../586be0bd5457a30d661c9605.json", __FILE__) # Southern California Edison Co - Time-of-use Tiered Domestic: TOU-D-T-Region 5
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    args_hash["pv_tariff_rate"] = "0.12"
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_values = {Constants.FuelTypeElectric=>11.16+751.78-1786.09, Constants.FuelTypeGas=>96+195.67, Constants.FuelTypePropane=>61.99, Constants.FuelTypeOil=>343.98}
    $hourly_output ? test_name = __method__ : test_name = nil
    _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
  end

=begin
  def test_all_tariff_files_validate
    require 'zip'
    require 'parallel'
    args_hash = {}
    args_hash["tariff_label"] = "Custom Tariff"    
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    args_hash["pv_tariff_rate"] = "0.12"
    Zip::File.open("#{File.dirname(__FILE__)}/../resources/tariffs.zip") do |zip_file|
      Parallel.each_with_index(zip_file, in_threads: 1) do |entry, i|
        next unless entry.file?
        timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
        puts "#{i} #{entry.name}"
        args_hash["custom_tariff"] = entry.name
        expected_values = {}
        $hourly_output ? test_name = __method__ : test_name = nil
        _test_measure_calculations(timeseries, args_hash, expected_values, test_name)
      end
    end
  end
=end

=begin
  def test_all_resstock_epw_files
    args_hash = {}
    args_hash["tariff_label"] = "Autoselect Tariff(s)"
    args_hash["custom_tariff"] = File.expand_path("../Southern California Edison Co - D - Region 5 - Monthly Tier.json", __FILE__)
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    weather_file_state = "CO"
    cols = CSV.read("#{File.dirname(__FILE__)}/../tests/resstock_epws.csv", {:encoding=>'ISO-8859-1'})
    cols.each_with_index do |col, i|
      next if i == 0
      id, filename, station_name, state, country, wx_type, usafn, latitude, longitude, time_diff, elevation = col
      puts "#{i} #{filename}"
      timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
      expected_values = {}
      $hourly_output ? test_name = __method__ : test_name = nil
      _test_measure_calculations(timeseries, args_hash, expected_values, test_name, weather_file_state, latitude, longitude)
    end
  end
=end
  
  private
  
  def _test_measure_calculations(timeseries, args_hash, expected_values, test_name, weather_file_state="CO", epw_latitude=nil, epw_longitude=nil)
    # create an instance of the measure
    measure = UtilityBillCalculations.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    
    # get arguments
    arguments = measure.arguments()
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    tariffs = {}
    marginal_rates = {Constants.FuelTypeGas=>args_hash["gas_rate"], Constants.FuelTypeOil=>args_hash["oil_rate"], Constants.FuelTypePropane=>args_hash["prop_rate"]}
    fixed_rates = {Constants.FuelTypeGas=>args_hash["gas_fixed"].to_f}
    if args_hash["electric_bill_type"] == "Simple"
      marginal_rates[Constants.FuelTypeElectric] = args_hash["elec_rate"]
      fixed_rates[Constants.FuelTypeElectric] = args_hash["elec_fixed"].to_f
    elsif args_hash["electric_bill_type"] == "Detailed"
      begin
        tariffs = {File.basename(args_hash["custom_tariff"]).chomp(".json") => JSON.parse(File.read(args_hash["custom_tariff"]), :symbolize_names=>true)[:items][0]}
      rescue
        begin
          Zip::File.open("#{File.dirname(__FILE__)}/../resources/tariffs.zip") do |zip_file|
            tariffs = {File.basename(args_hash["custom_tariff"]).chomp(".json") => JSON.parse(zip_file.read(args_hash["custom_tariff"]), :symbolize_names=>true)[:items][0]}
          end
        rescue
        end
      end
      if args_hash["tariff_label"] == "Autoselect Tariff(s)"
        tariffs = measure.autoselect_tariffs(runner, epw_latitude, epw_longitude)
      end
    end
    
    measure.calculate_utility_bills(runner, timeseries, weather_file_state, marginal_rates, fixed_rates, args_hash["pv_compensation_type"], args_hash["pv_annual_excess_sellback_rate_type"], args_hash["pv_sellback_rate"], args_hash["pv_tariff_rate"], args_hash["electric_bill_type"], tariffs, test_name)

    result = runner.result
    # show_output(result)
    
    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size > 0)

    expected_values.keys.each do |fuel|
      result.stepValues.each do |arg|
        next unless fuel == arg.name
        actual_value = arg.valueAsVariant.to_s
        if actual_value.include? "="
          actual_value = actual_value.split("=")
          actual_value = actual_value[1]
        end
        assert_in_epsilon(expected_values[arg.name], actual_value.to_f, 0.01)
      end
    end

  end
  
  def _test_error(timeseries, args_hash, weather_file_state="CO")
    # create an instance of the measure
    measure = UtilityBillCalculations.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    
    # get arguments
    arguments = measure.arguments()
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    marginal_rates = {Constants.FuelTypeGas=>args_hash["gas_rate"], Constants.FuelTypeOil=>args_hash["oil_rate"], Constants.FuelTypePropane=>args_hash["prop_rate"]}
    fixed_rates = {Constants.FuelTypeGas=>args_hash["gas_fixed"].to_f}
    tariffs = {}
    begin
      tariffs = {File.basename(args_hash["custom_tariff"]).chomp(".json") => JSON.parse(File.read(args_hash["custom_tariff"]), :symbolize_names=>true)[:items][0]}
    rescue
      begin
        Zip::File.open("#{File.dirname(__FILE__)}/../resources/tariffs.zip") do |zip_file|
          tariffs = {File.basename(args_hash["custom_tariff"]).chomp(".json") => JSON.parse(zip_file.read(args_hash["custom_tariff"]), :symbolize_names=>true)[:items][0]}
        end
      rescue
      end
    end
    measure.calculate_utility_bills(runner, timeseries, weather_file_state, marginal_rates, fixed_rates, args_hash["pv_compensation_type"], args_hash["pv_annual_excess_sellback_rate_type"], args_hash["pv_sellback_rate"], args_hash["pv_tariff_rate"], args_hash["electric_bill_type"], tariffs)

    result = runner.result
    # show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end
  
  def get_timeseries(enduse_timeseries)
    timeseries = {}
    cols = CSV.read(File.expand_path(enduse_timeseries)).transpose
    cols.each do |col|
      next unless col[0].include? "Facility"
      var_name = col[0].split("  ")[0]
      old_units = col[0].split("  ")[1].gsub("[", "").gsub("]", "")
      fuel_type = col[0].split(":")[0]
      new_units, unit_conv = UnitConversions.get_scalar_unit_conversion(var_name, old_units, HelperMethods.reverse_openstudio_fuel_map(fuel_type))
      vals = []
      col[1..8760].each do |val|
        vals << unit_conv * val.to_f
      end
      timeseries[var_name] = vals
    end
    return timeseries
  end
  
end