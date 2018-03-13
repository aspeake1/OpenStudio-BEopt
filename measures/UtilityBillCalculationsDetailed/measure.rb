# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'csv'
require 'matrix'
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/util"

#start the measure
class UtilityBillCalculationsDetailed < OpenStudio::Measure::ReportingMeasure

  # human readable name
  def name
    return "Calculate Detailed Utility Bills"
  end

  # human readable description
  def description
    return "Calculate utility bills for detailed electricity tariffs."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculate electric utility bills based on tariffs from the OpenEI Utility Rate Database (URDB). Calculate other utility bills based on fixed charges for gas, and marginal rates for gas, oil, and propane. User can specify PV compensation types of '#{Constants.PVNetMetering}' or '#{Constants.PVFeedInTariff}', along with corresponding rates."
  end 
  
  def fuel_types
    fuel_types = [  
      "Electricity",
      "Gas",
      "FuelOil#1",
      "Propane",
      "ElectricityProduced"
    ]
    
    return fuel_types
  end
  
  def end_uses
    end_uses = [
      "Facility"
    ]
    
    return end_uses
  end
  
  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Measure::OSArgumentVector.new

    tariffs = OpenStudio::StringVector.new
    tariffs << "Autoselect Tariff(s)"
    tariffs << "Custom Tariff"
    cols = CSV.read("#{File.dirname(__FILE__)}/resources/utilities.csv", {:encoding=>'ISO-8859-1'}).transpose
    zip_file = OpenStudio::UnzipFile.new("#{File.dirname(__FILE__)}/resources/tariffs.zip")
    zip_file.listFiles.each do |label|
      label = label.to_s.chomp(".json")
      utility_name = get_utility_and_name_from_label(cols, label)
      tariffs << utility_name
    end
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("tariff_label", tariffs, true)
    arg.setDisplayName("Electricity: Tariff")
    arg.setDescription("Choose either 'Autoselect Tariff(s)', 'Custom Tariff', or a prepackaged tariff. If 'Autoselect Tariff(s)' is selected, tariff(s) from nearby utilities will be selected.")
    arg.setDefaultValue("Autoselect Tariff(s)")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("custom_tariff", false)
    arg.setDisplayName("Electricity: Custom Tariff File Location")
    arg.setDescription("Absolute path to custom tariff file. See resources/tariffs.zip for example tariff files. Only applies if Tariff is 'Custom Tariff'.")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("gas_fixed", true)
    arg.setDisplayName("Natural Gas: Fixed Charge")
    arg.setUnits("$/month")
    arg.setDescription("Monthly fixed charge for natural gas.")
    arg.setDefaultValue("8.0")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("gas_rate", true)
    arg.setDisplayName("Natural Gas: Marginal Rate")
    arg.setUnits("$/therm")
    arg.setDescription("Price per therm for natural gas. Use '#{Constants.Auto} for state-average value from EIA.")
    arg.setDefaultValue(Constants.Auto)
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("oil_rate", true)
    arg.setDisplayName("Oil: Marginal Rate")
    arg.setUnits("$/gal")
    arg.setDescription("Price per gallon for fuel oil. Use '#{Constants.Auto} for state-average value from EIA.")
    arg.setDefaultValue(Constants.Auto)
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("prop_rate", true)
    arg.setDisplayName("Propane: Marginal Rate")
    arg.setUnits("$/gal")
    arg.setDescription("Price per gallon for propane. Use '#{Constants.Auto} for state-average value from EIA.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    pv_compensation_types = OpenStudio::StringVector.new
    pv_compensation_types << Constants.PVNetMetering
    pv_compensation_types << Constants.PVFeedInTariff
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("pv_compensation_type", pv_compensation_types, true)
    arg.setDisplayName("PV: Compensation Type")
    arg.setDescription("The type of compensation for PV.")
    arg.setDefaultValue(Constants.PVNetMetering)
    args << arg

    pv_annual_excess_sellback_rate_types = OpenStudio::StringVector.new
    pv_annual_excess_sellback_rate_types << Constants.RetailElectricityCost
    pv_annual_excess_sellback_rate_types << Constants.UserSpecified
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("pv_annual_excess_sellback_rate_type", pv_annual_excess_sellback_rate_types, true)
    arg.setDisplayName("PV: Annual Excess Sellback Rate Type")
    arg.setDescription("The type of annual excess sellback rate for PV. Only applies if the PV compensation type is '#{Constants.PVNetMetering}'.")
    arg.setDefaultValue(Constants.UserSpecified)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("pv_sellback_rate", true)
    arg.setDisplayName("PV: Net Metering Annual Excess Sellback Rate")
    arg.setUnits("$/kWh")
    arg.setDescription("The annual excess/net sellback rate for PV. Only applies if the PV compensation type is '#{Constants.PVNetMetering}'.")
    arg.setDefaultValue("0.03")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("pv_tariff_rate", true)
    arg.setDisplayName("PV: Feed-In Tariff Rate")
    arg.setUnits("$/kWh")
    arg.setDescription("The annual full/gross tariff rate for PV. Only applies if the PV compensation type is '#{Constants.PVFeedInTariff}'.")
    arg.setDefaultValue("0.12")
    args << arg
    
    return args
  end
  
  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)
    
    result = OpenStudio::IdfObjectVector.new

    # Request the output for each end use/fuel type combination
    end_uses.each do |end_use|
      fuel_types.each do |fuel_type|
        variable_name = if end_use == "Facility"
                  "#{fuel_type}:#{end_use}"
                else
                  "#{end_use}:#{fuel_type}"
                end
        result << OpenStudio::IdfObject.load("Output:Meter,#{variable_name},Hourly;").get
      end
    end

    return result
  end
  
  def outputs
    result = OpenStudio::Measure::OSOutputVector.new
    buildstock_outputs = [
                          Constants.FuelTypeElectric,
                          Constants.FuelTypeGas,
                          Constants.FuelTypePropane,
                          Constants.FuelTypeOil
                         ]
    buildstock_outputs.each do |output|
        result << OpenStudio::Measure::OSOutput.makeDoubleOutput(output)
    end
    return result
  end  
  
  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(), user_arguments)
      return false
    end
    
    # Assign the user inputs to variables
    tariff_label = runner.getStringArgumentValue("tariff_label", user_arguments)
    custom_tariff = runner.getOptionalStringArgumentValue("custom_tariff", user_arguments)
    gas_fixed = runner.getStringArgumentValue("gas_fixed", user_arguments)
    pv_compensation_type = runner.getStringArgumentValue("pv_compensation_type", user_arguments)
    pv_annual_excess_sellback_rate_type = runner.getStringArgumentValue("pv_annual_excess_sellback_rate_type", user_arguments)
    pv_sellback_rate = runner.getStringArgumentValue("pv_sellback_rate", user_arguments)
    pv_tariff_rate = runner.getStringArgumentValue("pv_tariff_rate", user_arguments)
    
    fixed_rates = {
                   Constants.FuelTypeGas=>gas_fixed.to_f
                  }
    
    marginal_rates = {
                      Constants.FuelTypeGas=>runner.getStringArgumentValue("gas_rate", user_arguments),
                      Constants.FuelTypeOil=>runner.getStringArgumentValue("oil_rate", user_arguments),
                      Constants.FuelTypePropane=>runner.getStringArgumentValue("prop_rate", user_arguments)
                     }
    
    # Get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get
    
    # Get weather file and state
    weather_file = model.getSite.weatherFile.get
    weather_file_state = weather_file.stateProvinceRegion
    if HelperMethods.state_code_map.keys.include? weather_file_state
      weather_file_state = HelperMethods.state_code_map[weather_file_state]
    end
      
    # Get the last sql file      
    sql = runner.lastEnergyPlusSqlFile
    if sql.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sql = sql.get
    model.setSqlFile(sql)
    
    # Get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sql.availableEnvPeriods.each do |env_pd|
      env_type = sql.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          ann_env_pd = env_pd
        end
      end
    end
    if ann_env_pd == false
      runner.registerError("Can't find a weather runperiod, make sure you ran an annual simulation, not just the design days.")
      return false
    end
    
    tariffs = {}
    if tariff_label == "Custom Tariff" and custom_tariff.is_initialized

      custom_tariff = custom_tariff.get
      if File.exists?(File.expand_path(custom_tariff))
        label = File.basename(File.expand_path(custom_tariff)).chomp(".json")
        tariffs[label] = JSON.parse(File.read(custom_tariff), :symbolize_names=>true)[:items][0]
      end

    elsif tariff_label != "Autoselect Tariff(s)" # tariff is selected from the list
    
      utility_name = tariff_label
      label = get_label_from_utility_and_name(utility_name)
      zip_file = OpenStudio::UnzipFile.new("#{File.dirname(__FILE__)}/resources/tariffs.zip")
      zip_file.listFiles.each do |zip_entry|
        next unless zip_entry.to_s == "#{label}.json"
        zip_entry = zip_file.extractFile(zip_entry, ".")
        tariffs[label] = JSON.parse(File.read(zip_entry.to_s), :symbolize_names=>true)[:items][0]
      end

    else # autoselect tariff based on distance to simulation epw location

      tariffs = autoselect_tariffs(runner, weather_file.latitude, weather_file.longitude)
    
    end

    timeseries = {}
    end_uses.each do |end_use|
      fuel_types.each do |fuel_type|
      
        var_name = "#{fuel_type}:#{end_use}"
        timeseries[var_name] = []
        
        # Get the y axis values
        y_timeseries = sql.timeSeries(ann_env_pd, "Hourly", var_name, "")
        if y_timeseries.empty?
          runner.registerWarning("No data found for Hourly #{var_name}.")
          next
        else
          y_timeseries = y_timeseries.get
          values = y_timeseries.values
        end

        old_units = y_timeseries.units
        new_units, unit_conv = UnitConversions.get_scalar_unit_conversion(var_name, old_units, HelperMethods.reverse_openstudio_fuel_map(fuel_type))
        y_timeseries.dateTimes.each_with_index do |date_time, i|
          y_val = values[i].to_f
          unless unit_conv.nil?
            y_val *= unit_conv
          end
          timeseries[var_name] << y_val.round(5)
        end
        
      end
    end

    result = calculate_utility_bills(runner, timeseries, weather_file_state, marginal_rates, fixed_rates, pv_compensation_type, pv_annual_excess_sellback_rate_type, pv_sellback_rate, pv_tariff_rate, tariffs)
    
    return result
    
  end
  
  def calculate_utility_bills(runner, timeseries, weather_file_state, marginal_rates, fixed_rates, pv_compensation_type, pv_annual_excess_sellback_rate_type, pv_sellback_rate, pv_tariff_rate, tariffs)

    if tariffs.empty?
      runner.registerError("Could not locate tariff(s).")
      return false
    end
    
    if marginal_rates.values.include? Constants.Auto
      unless HelperMethods.state_code_map.values.include? weather_file_state
        runner.registerError("Rates do not exist for state/province/region '#{weather_file_state}'.")
        return false
      end
    end
  
    if timeseries["ElectricityProduced:Facility"].empty?
      timeseries["ElectricityProduced:Facility"] = Array.new(timeseries["Electricity:Facility"].length, 0)
    end

    timeseries["ElectricityProduced:Facility"].each_with_index do |val, i|
      timeseries["Electricity:Facility"][i] += timeseries["ElectricityProduced:Facility"][i] # http://bigladdersoftware.com/epx/docs/8-7/input-output-reference/input-for-output.html
    end
  
    total_bill = 0
    fuels = {Constants.FuelTypeGas=>"Natural gas", Constants.FuelTypeOil=>"Oil", Constants.FuelTypePropane=>"Propane"}
    fuels.each do |fuel, file|
 
      cols = CSV.read("#{File.dirname(__FILE__)}/resources/#{file}.csv", {:encoding=>'ISO-8859-1'})[3..-1].transpose      
      cols[0].each_with_index do |rate_state, i|

        next unless rate_state == weather_file_state

        marginal_rate = marginal_rates[fuel]
        if marginal_rate == Constants.Auto
          average_rate = cols[1][i].to_f            
          marginal_rate = average_rate
          if [Constants.FuelTypeGas].include? fuel
            household_consumption = cols[2][i].to_f
            marginal_rate = average_rate - 12.0 * fixed_rates[fuel] / household_consumption
          end
        else
          marginal_rate = marginal_rate.to_f
        end

        if fuel == Constants.FuelTypeGas and not timeseries["Gas:Facility"].empty?
          gas_bill = UtilityBill.calculate_simple(timeseries["Gas:Facility"], fixed_rates[fuel], marginal_rate)
          runner.registerValue(fuel, gas_bill)
          total_bill += gas_bill
        elsif fuel == Constants.FuelTypeOil and not timeseries["FuelOil#1:Facility"].empty?
          oil_bill = UtilityBill.calculate_simple(timeseries["FuelOil#1:Facility"], 0, marginal_rate)
          runner.registerValue(fuel, oil_bill)
          total_bill += oil_bill
        elsif fuel == Constants.FuelTypePropane and not timeseries["Propane:Facility"].empty?
          prop_bill = UtilityBill.calculate_simple(timeseries["Propane:Facility"], 0, marginal_rate)
          runner.registerValue(fuel, prop_bill)
          total_bill += prop_bill
        end

      end

    end
  
    elec_bills = {}
    no_charges = []
    fuels = {Constants.FuelTypeElectric=>"Electricity"}
    fuels.each do |fuel, file|

      if !File.directory? "#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1"
        unzip_file = OpenStudio::UnzipFile.new("#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1.zip")
        unzip_file.extractAllFiles(OpenStudio::toPath("#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1"))
      end
      require "#{File.dirname(__FILE__)}/resources/ssc_api"
      timeseries["Electricity:Facility"] = UtilityBill.remove_leap_day(timeseries["Electricity:Facility"])
      timeseries["ElectricityProduced:Facility"] = UtilityBill.remove_leap_day(timeseries["ElectricityProduced:Facility"])
      
      cols = CSV.read("#{File.dirname(__FILE__)}/resources/utilities.csv", {:encoding=>'ISO-8859-1'}).transpose
      tariffs.each do |label, tariff|

        utility_name = get_utility_and_name_from_label(cols, label)
        if UtilityBill.validate_tariff(tariff)
          if pv_annual_excess_sellback_rate_type == Constants.RetailElectricityCost
            pv_sellback_rate = 0
          end
          elec_bill = UtilityBill.calculate_detailed_electric(timeseries["Electricity:Facility"], timeseries["ElectricityProduced:Facility"], pv_compensation_type, pv_sellback_rate, pv_tariff_rate, tariff)
          unless elec_bills.keys.include? tariff[:eiaid]
            elec_bills[tariff[:eiaid]] = []
          end
          elec_bills[tariff[:eiaid]] << elec_bill
          runner.registerInfo("Calculated utility bill: #{utility_name} = $%.2f" % (total_bill + elec_bill))
        else
          no_charges << "#{utility_name}"
        end

      end
      
      if elec_bills.empty?
        runner.registerError("Does not contain charges: #{no_charges.join(", ")}.")
        return false        
      end
      
      avg_elec_bills = []
      elec_bills.each do |eiaid, bills|
        avg_elec_bills << "#{eiaid}=#{bills.inject{ |sum, bill| sum + bill } / bills.size}"
      end
      runner.registerValue(fuel, avg_elec_bills.join(";"))

    end
    
    return true
  
  end
  
  def autoselect_tariffs(runner, epw_latitude, epw_longitude)
  
    cols = CSV.read("#{File.dirname(__FILE__)}/resources/by_nsrdb.csv").transpose
    closest_usaf = closest_usaf_to_epw(epw_latitude, epw_longitude, cols.transpose) # minimize distance to simulation epw
    runner.registerInfo("Closest usaf to #{epw_latitude}, #{epw_longitude}: #{closest_usaf}")      
    usafs = cols[1].collect { |i| i.to_s }
    usaf_ixs = usafs.each_index.select{|i| usafs[i] == closest_usaf}
    utilityids = [] # [eiaid1, eiaid2, ...]
    usaf_ixs.each do |ix|
      next if cols[4][ix].nil?
      cols[4][ix].split("|").each do |utilityid|
        next if utilityid == "no data"
        next if utilityids.include? utilityid
        utilityids << utilityid
      end
    end

    utilityid_to_filename = {} # {eiaid: {label, ...}, ...}
    cols = CSV.read("#{File.dirname(__FILE__)}/resources/utilities.csv", {:encoding=>'ISO-8859-1'}).transpose
    cols.each do |col|
      next unless col[0].include? "eiaid"
      utilityids.each do |utilityid|
        eiaid_ixs = col.each_index.select{|i| col[i] == utilityid}
        eiaid_ixs.each do |ix|
          label = cols[3][ix]
          filename = "#{label}.json"
          unless utilityid_to_filename.keys.include? utilityid
            utilityid_to_filename[utilityid] = []
          end
          utilityid_to_filename[utilityid] << filename
        end
      end
    end

    tariffs = {} # {label: tariff, ...} 
    utilityid_to_filename.each do |utilityid, filenames|
      filenames.each do |filename|
        zip_file = OpenStudio::UnzipFile.new("#{File.dirname(__FILE__)}/resources/tariffs.zip")
        zip_file.listFiles.each do |zip_entry|
          next unless zip_entry.to_s == filename
          zip_entry = zip_file.extractFile(zip_entry, ".")
          if File.exists?("./#{zip_entry}")
            label = File.basename(File.expand_path(zip_entry.to_s)).chomp(".json")
            tariffs[label] = JSON.parse(File.read(zip_entry.to_s), :symbolize_names=>true)[:items][0]
          else
            return []
          end
        end
      end          
    end
    
    return tariffs
  
  end

  def get_utility_and_name_from_label(cols, label)
    label_ix = nil
    utility = nil
    name = nil
    cols.each do |col|
      next unless col[0] == "label"
      label_ixs = col.each_index.select{|i| col[i] == label}
      unless label_ixs.empty?
        label_ix = label_ixs[0]
      end
    end
    unless label_ix.nil?
      cols.each do |col|
        if col[0] == "utility"
          utility = col[label_ix]
        elsif col[0] == "name"
          name = col[label_ix]
        end
      end
      return "#{utility} - #{name}"
    end
    return label
  end
  
  def get_label_from_utility_and_name(utility_name)
    utility_name = utility_name.split(" - ")
    utility = utility_name[0]
    name = utility_name[1..-1].join(" - ")
    cols = CSV.read("#{File.dirname(__FILE__)}/resources/utilities.csv", {:encoding=>'ISO-8859-1'}).transpose
    utility_ixs = []
    name_ixs = []
    utility_name_ix = nil
    label = nil
    cols.each do |col|
      next unless col[0] == "utility"
      utility_ixs = col.each_index.select{|i| col[i] == utility}
    end
    cols.each do |col|
      next unless col[0] == "name"
      name_ixs = col.each_index.select{|i| col[i] == name}
    end
    utility_name_ixs = utility_ixs & name_ixs
    utility_name_ix = utility_name_ixs[0]
    cols.each do |col|
      next unless col[0] == "label"
      label = col[utility_name_ix]
    end
    return label
  end
  
  def closest_usaf_to_epw(bldg_lat, bldg_lon, usafs) # for the 216 resstock locations, epw=usaf
    bldg_lat = bldg_lat.to_f
    bldg_lon = bldg_lon.to_f
    distances = [1000000]
    usafs.each_with_index do |usaf, i|
      next if i == 0
      nsrdb_gid_new, usafn, usaf_lon, usaf_lat, utilityid = usaf
      usaf_lat = usaf_lat.to_f
      usaf_lon = usaf_lon.to_f
      if (bldg_lat - usaf_lat).abs > 1 and (bldg_lon - usaf_lon).abs > 1 # reduce the set to save some time
        distances << 1000000
        next
      end
      km = haversine(bldg_lat, bldg_lon, usaf_lat, usaf_lon)
      distances << km
    end
    return usafs[distances.index(distances.min)][1]    
  end

  def haversine(lat1, lon1, lat2, lon2)

    # convert decimal degrees to radians
    lat1 = UnitConversions.convert(lat1, "deg", "rad")
    lon1 = UnitConversions.convert(lon1, "deg", "rad")
    lat2 = UnitConversions.convert(lat2, "deg", "rad")
    lon2 = UnitConversions.convert(lon2, "deg", "rad")

    # haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = Math.sin(dlat/2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dlon/2)**2
    c = 2 * Math.asin(Math.sqrt(a)) 
    km = 6367 * c

    return km

  end

end

# register the measure to be used by the application
UtilityBillCalculationsDetailed.new.registerWithApplication