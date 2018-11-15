require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class UtilityBillCalculationsDetailedTest < MiniTest::Test
  def test_functionality_net_metering_custom_tariff
    args_hash = {}
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = "../../../Southern California Edison Co - D - Region 5 - Monthly Tier.json"
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure_functionality("SFD_Successful_EnergyPlus_Run_TMY_PV.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, "USA_CO_Denver_Intl_AP_725650_TMY3.epw", 1, 1)
  end

  def test_functionality_net_metering_autoselect_tariffs
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure_functionality("SFD_Successful_EnergyPlus_Run_TMY_PV.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, "USA_CO_Denver_Intl_AP_725650_TMY3.epw", 35, 1)
  end

  def test_functionality_feed_in_tariff_select_tariff
    args_hash = {}
    args_hash["tariff_label"] = "4-County Electric Power Assn - Residential"
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure_functionality("SFD_Successful_EnergyPlus_Run_AMY_PV.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, "DuPage_17043_725300_880860.epw", 1, 1)
  end

  def test_error_invalid_location
    args_hash = {}
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../Southern California Edison Co - D - Region 5 - Monthly Tier.json", __FILE__)
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    args_hash["pv_tariff_rate"] = "0.12"
    weather_file_state = "AB"
    timeseries = get_timeseries(File.expand_path("../PV_None.csv", __FILE__))
    result = _test_error(timeseries, args_hash, weather_file_state)
    assert_includes(result.errors.map { |x| x.logMessage }, "Rates do not exist for state/province/region '#{weather_file_state}'.")
  end

  def test_error_invalid_tariff
    args_hash = {}
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../539f75f7ec4f024411ed19fd.json", __FILE__)
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    args_hash["pv_tariff_rate"] = "0.12"
    weather_file_state = "CO"
    timeseries = get_timeseries(File.expand_path("../PV_None.csv", __FILE__))
    result = _test_error(timeseries, args_hash, weather_file_state)
    assert_includes(result.errors.map { |x| x.logMessage }, "Does not contain charges: City of Linneus, Missouri (Utility Company) - Electric Rate.")
  end

  def test_error_no_tariffs_found
    args_hash = {}
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../Imaginary Tariff.json", __FILE__)
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    args_hash["pv_tariff_rate"] = "0.12"
    weather_file_state = "CO"
    timeseries = get_timeseries(File.expand_path("../PV_None.csv", __FILE__))
    result = _test_error(timeseries, args_hash, weather_file_state)
    assert_includes(result.errors.map { |x| x.logMessage }, "Could not locate tariff(s).")
  end

  def test_calculations_0kW_pv_net_metering_custom_tariff
    args_hash = {}
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../Southern California Edison Co - D - Region 5 - Monthly Tier.json", __FILE__)
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    args_hash["pv_tariff_rate"] = "0.12"
    weather_file_state = "CO"
    timeseries = get_timeseries(File.expand_path("../PV_None.csv", __FILE__))
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = { Constants.FuelTypeElectric => 781, Constants.FuelTypeGas => 414, Constants.FuelTypePropane => 62, Constants.FuelTypeOil => 344 }
    _test_measure_calculations(timeseries, args_hash, weather_file_state, expected_values)
  end

  def test_calculations_1kW_pv_net_metering_custom_tariff
    args_hash = {}
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../Southern California Edison Co - D - Region 5 - Monthly Tier.json", __FILE__)
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    args_hash["pv_tariff_rate"] = "0.12"
    weather_file_state = "CO"
    timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = { Constants.FuelTypeElectric => 781 - 196, Constants.FuelTypeGas => 414, Constants.FuelTypePropane => 62, Constants.FuelTypeOil => 344 }
    _test_measure_calculations(timeseries, args_hash, weather_file_state, expected_values)
  end

  def test_calculations_10kW_pv_net_metering_custom_tariff
    args_hash = {}
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../Southern California Edison Co - D - Region 5 - Monthly Tier.json", __FILE__)
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVNetMetering
    args_hash["pv_sellback_rate"] = "0.03"
    args_hash["pv_tariff_rate"] = "0.12"
    weather_file_state = "CO"
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = { Constants.FuelTypeElectric => 781 - 1042, Constants.FuelTypeGas => 414, Constants.FuelTypePropane => 62, Constants.FuelTypeOil => 344 }
    _test_measure_calculations(timeseries, args_hash, weather_file_state, expected_values)
  end

  def test_calculations_0kW_pv_feed_in_tariff_custom_tariff
    args_hash = {}
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../Southern California Edison Co - D - Region 5 - Monthly Tier.json", __FILE__)
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    args_hash["pv_sellback_rate"] = "0.03"
    args_hash["pv_tariff_rate"] = "0.12"
    weather_file_state = "CO"
    timeseries = get_timeseries(File.expand_path("../PV_None.csv", __FILE__))
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = { Constants.FuelTypeElectric => 781, Constants.FuelTypeGas => 414, Constants.FuelTypePropane => 62, Constants.FuelTypeOil => 344 }
    _test_measure_calculations(timeseries, args_hash, weather_file_state, expected_values)
  end

  def test_calculations_1kW_pv_feed_in_tariff_custom_tariff
    args_hash = {}
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../Southern California Edison Co - D - Region 5 - Monthly Tier.json", __FILE__)
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    args_hash["pv_sellback_rate"] = "0.03"
    args_hash["pv_tariff_rate"] = "0.12"
    weather_file_state = "CO"
    timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = { Constants.FuelTypeElectric => 781 - 178, Constants.FuelTypeGas => 414, Constants.FuelTypePropane => 62, Constants.FuelTypeOil => 344 }
    _test_measure_calculations(timeseries, args_hash, weather_file_state, expected_values)
  end

  def test_calculations_10kW_pv_feed_in_tariff_custom_tariff
    args_hash = {}
    args_hash["tariff_label"] = "Custom Tariff"
    args_hash["custom_tariff"] = File.expand_path("../Southern California Edison Co - D - Region 5 - Monthly Tier.json", __FILE__)
    args_hash["gas_fixed"] = "8.0"
    args_hash["gas_rate"] = Constants.Auto
    args_hash["oil_rate"] = Constants.Auto
    args_hash["prop_rate"] = Constants.Auto
    args_hash["pv_compensation_type"] = Constants.PVFeedInTariff
    args_hash["pv_sellback_rate"] = "0.03"
    args_hash["pv_tariff_rate"] = "0.12"
    weather_file_state = "CO"
    timeseries = get_timeseries(File.expand_path("../PV_10kW.csv", __FILE__))
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = { Constants.FuelTypeElectric => 781 - 1786, Constants.FuelTypeGas => 414, Constants.FuelTypePropane => 62, Constants.FuelTypeOil => 344 }
    _test_measure_calculations(timeseries, args_hash, weather_file_state, expected_values)
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
    args_hash["pv_sellback_rate"] = "0.03"
    args_hash["pv_tariff_rate"] = "0.12"
    weather_file_state = "CO"
    Zip::File.open("#{File.dirname(__FILE__)}/../resources/tariffs.zip") do |zip_file|
      Parallel.each_with_index(zip_file, in_threads: 1) do |entry, i|
        next unless entry.file?
        timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
        puts "#{i} #{entry.name}"
        args_hash["custom_tariff"] = entry.name
        expected_values = {}
        _test_measure_calculations(timeseries, args_hash, weather_file_state, expected_values)
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
    args_hash["pv_tariff_rate"] = "0.12"
    weather_file_state = "CO"
    cols = CSV.read("#{File.dirname(__FILE__)}/../tests/resstock_epws.csv", {:encoding=>'ISO-8859-1'})
    cols.each_with_index do |col, i|
      next if i == 0
      id, filename, station_name, state, country, wx_type, usafn, latitude, longitude, time_diff, elevation = col
      puts "#{i} #{filename}"
      timeseries = get_timeseries(File.expand_path("../PV_1kW.csv", __FILE__))
      expected_values = {}
      _test_measure_calculations(timeseries, args_hash, weather_file_state, expected_values, latitude, longitude)
    end
  end
=end

  private

  def model_in_path_default(osm_file_or_model)
    return File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", "..", "test", "osm_files", osm_file_or_model))
  end

  def epw_path_default(epw_name)
    # make sure we have a weather data location
    epw = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{epw_name}")
    assert(File.exist?(epw.to_s))
    return epw.to_s
  end

  def run_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    return "#{File.dirname(__FILE__)}/output/#{test_name}/run"
  end

  def tests_dir(test_name)
    return "#{File.dirname(__FILE__)}/output/#{test_name}/tests"
  end

  def model_out_path(osm_file_or_model, test_name)
    return "#{run_dir(test_name)}/#{osm_file_or_model}"
  end

  def sql_path(test_name)
    return "#{run_dir(test_name)}/run/eplusout.sql"
  end

  # create test files if they do not exist when the test first runs
  def setup_test(osm_file_or_model, test_name, idf_output_requests, epw_path, model_in_path)
    if !File.exist?(run_dir(test_name))
      FileUtils.mkdir_p(run_dir(test_name))
    end
    assert(File.exist?(run_dir(test_name)))

    if !File.exist?(tests_dir(test_name))
      FileUtils.mkdir_p(tests_dir(test_name))
    end
    assert(File.exist?(tests_dir(test_name)))

    assert(File.exist?(model_in_path))

    if File.exist?(model_out_path(osm_file_or_model, test_name))
      FileUtils.rm(model_out_path(osm_file_or_model, test_name))
    end

    # convert output requests to OSM for testing, OS App and PAT will add these to the E+ Idf
    workspace = OpenStudio::Workspace.new("Draft".to_StrictnessLevel, "EnergyPlus".to_IddFileType)
    workspace.addObjects(idf_output_requests)
    rt = OpenStudio::EnergyPlus::ReverseTranslator.new
    request_model = rt.translateWorkspace(workspace)

    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(model_in_path)
    assert((not model.empty?))
    model = model.get
    model.addObjects(request_model.objects)
    model.save(model_out_path(osm_file_or_model, test_name), true)

    osw_path = File.join(run_dir(test_name), "in.osw")
    osw_path = File.absolute_path(osw_path)

    workflow = OpenStudio::WorkflowJSON.new
    workflow.setSeedFile(File.absolute_path(model_out_path(osm_file_or_model, test_name)))
    workflow.setWeatherFile(epw_path)
    workflow.saveAs(osw_path)

    if !File.exist?("#{run_dir(test_name)}")
      FileUtils.mkdir_p("#{run_dir(test_name)}")
    end

    cli_path = OpenStudio.getOpenStudioCLI
    cmd = "\"#{cli_path}\" --no-ssl run -w \"#{osw_path}\""
    puts cmd
    system(cmd)

    FileUtils.cp(epw_path, "#{tests_dir(test_name)}")

    return model
  end

  def _test_measure_functionality(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, test_name, epw_name, num_infos = 0, num_warnings = 0)
    # create an instance of the measure
    measure = UtilityBillCalculationsDetailed.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get arguments
    arguments = measure.arguments()
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert(idf_output_requests.size == measure.fuel_types.length * measure.end_uses.length)

    # mimic the process of running this measure in OS App or PAT. Optionally set custom model_in_path and custom epw_path.
    model = setup_test(osm_file_or_model, test_name, idf_output_requests, File.expand_path(epw_path_default(epw_name)), model_in_path_default(osm_file_or_model))

    assert(File.exist?(model_out_path(osm_file_or_model, test_name)))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(osm_file_or_model, test_name)))
    runner.setLastEpwFilePath(File.expand_path(epw_path_default(epw_name)))
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      # show_output(result)
    ensure
      Dir.chdir(start_dir)
    end

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)

    return model
  end

  def _test_measure_calculations(timeseries, args_hash, weather_file_state, expected_values, epw_latitude = nil, epw_longitude = nil)
    # create an instance of the measure
    measure = UtilityBillCalculationsDetailed.new

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
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    marginal_rates = { Constants.FuelTypeGas => args_hash["gas_rate"], Constants.FuelTypeOil => args_hash["oil_rate"], Constants.FuelTypePropane => args_hash["prop_rate"] }
    fixed_rates = { Constants.FuelTypeGas => args_hash["gas_fixed"].to_f }
    tariffs = {}
    begin
      tariffs = { File.basename(args_hash["custom_tariff"]).chomp(".json") => JSON.parse(File.read(args_hash["custom_tariff"]), :symbolize_names => true)[:items][0] }
    rescue
      begin
        Zip::File.open("#{File.dirname(__FILE__)}/../resources/tariffs.zip") do |zip_file|
          tariffs = { File.basename(args_hash["custom_tariff"]).chomp(".json") => JSON.parse(zip_file.read(args_hash["custom_tariff"]), :symbolize_names => true)[:items][0] }
        end
      rescue
      end
    end
    if args_hash["tariff_label"] == "Autoselect Tariff(s)"
      tariffs = measure.autoselect_tariffs(runner, epw_latitude, epw_longitude)
    end
    measure.calculate_utility_bills(runner, timeseries, weather_file_state, marginal_rates, fixed_rates, args_hash["pv_compensation_type"], args_hash["pv_sellback_rate"], args_hash["pv_tariff_rate"], tariffs)

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
        assert_in_epsilon(expected_values[arg.name], actual_value.to_f, 0.005)
      end
    end
  end

  def _test_error(timeseries, args_hash, weather_file_state)
    # create an instance of the measure
    measure = UtilityBillCalculationsDetailed.new

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
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    marginal_rates = { Constants.FuelTypeGas => args_hash["gas_rate"], Constants.FuelTypeOil => args_hash["oil_rate"], Constants.FuelTypePropane => args_hash["prop_rate"] }
    fixed_rates = { Constants.FuelTypeGas => args_hash["gas_fixed"].to_f }
    tariffs = {}
    begin
      tariffs = { File.basename(args_hash["custom_tariff"]).chomp(".json") => JSON.parse(File.read(args_hash["custom_tariff"]), :symbolize_names => true)[:items][0] }
    rescue
      begin
        Zip::File.open("#{File.dirname(__FILE__)}/../resources/tariffs.zip") do |zip_file|
          tariffs = { File.basename(args_hash["custom_tariff"]).chomp(".json") => JSON.parse(zip_file.read(args_hash["custom_tariff"]), :symbolize_names => true)[:items][0] }
        end
      rescue
      end
    end
    measure.calculate_utility_bills(runner, timeseries, weather_file_state, marginal_rates, fixed_rates, args_hash["pv_compensation_type"], args_hash["pv_sellback_rate"], args_hash["pv_tariff_rate"], tariffs)

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
