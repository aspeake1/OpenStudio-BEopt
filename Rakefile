require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'

require 'pp'
require 'colored'
require 'json'

desc 'perform tasks related to unit tests'
namespace :test do

  desc 'Run unit tests for all measures'
  Rake::TestTask.new('all') do |t|
    t.libs << 'test'
    t.test_files = Dir['measures/*/tests/*.rb'] + Dir['workflows/tests/*.rb'] - Dir['measures/HPXMLtoOpenStudio/tests/*.rb'] # HPXMLtoOpenStudio is tested upstream
    t.warning = false
    t.verbose = true
  end
  
  desc 'regenerate test osm files from osw files'
  Rake::TestTask.new('regenerate_osms') do |t|
    t.libs << 'test'
    t.test_files = Dir['test/osw_files/tests/*.rb']
    t.warning = false
    t.verbose = true
  end

end

def regenerate_osms

    require 'openstudio'
  
    start_time = Time.now
    num_tot = 0
    num_success = 0
    
    osw_path = File.expand_path("../test/osw_files/", __FILE__)
    osm_path = File.expand_path("../test/osm_files/", __FILE__)
    
    osw_files = Dir.entries(osw_path).select {|entry| entry.end_with?(".osw") and entry != "out.osw"}
    
    if File.exists?(File.expand_path("../log", __FILE__))
        FileUtils.rm(File.expand_path("../log", __FILE__))
    end

    cli_path = OpenStudio.getOpenStudioCLI

    num_osws = osw_files.size

    osw_files.each do |osw|
    
        # Generate osm from osw
        num_tot += 1
        
        puts "[#{num_tot}/#{num_osws}] Regenerating osm from #{osw}..."
        osw = File.expand_path("../test/osw_files/#{osw}", __FILE__)
        update_and_format_osw(osw)
        osm = File.expand_path("../test/osw_files/run/in.osm", __FILE__)
        command = "\"#{cli_path}\" --no-ssl run -w #{osw} -m >> log"
        for _retry in 1..3
            system(command)
            break if File.exists?(osm)
        end
        if not File.exists?(osm)
            fail "  ERROR: Could not generate osm."
        end

        # Add auto-generated message to top of file
        # Update EPW file paths to be relative for the CirceCI machine
        file_text = File.readlines(osm)
        File.open(osm, "w") do |f|
            f.write("!- NOTE: Auto-generated from #{osw.gsub(File.dirname(__FILE__), "")}\n")
            file_text.each do |file_line|
                if file_line.strip.start_with?("file:///")
                    file_data = file_line.split('/')
                    epw_name = file_data[-1].split(',')[0]
                    if File.exists? File.join(File.dirname(__FILE__), "measures/HPXMLtoOpenStudio/weather/#{epw_name}")
                      file_line = file_data[0] + "../weather/" + file_data[-1]
                    else
                      # File not found in weather dir, assume it's in measure's tests dir instead
                      file_line = file_data[0] + "../tests/" + file_data[-1]
                    end
                end
                f.write(file_line)
            end
        end
        
        # Copy to osm dir
        osm_new = File.join(osm_path, File.basename(osw).gsub(".osw",".osm"))
        FileUtils.cp(osm, osm_new)
        num_success += 1

        # Clean up
        run_dir = File.expand_path("../test/osw_files/run", __FILE__)
        if Dir.exists?(run_dir)
            FileUtils.rmtree(run_dir)
        end
        if File.exists?(File.expand_path("../test/osw_files/out.osw", __FILE__))
            FileUtils.rm(File.expand_path("../test/osw_files/out.osw", __FILE__))
        end
    end
    
    puts "Completed. #{num_success} of #{num_tot} osm files were regenerated successfully (#{Time.now - start_time} seconds)."

end

def update_and_format_osw(osw)
  # Insert new step(s) into test osw files, if they don't already exist: {step1=>index1, step2=>index2, ...}
  # e.g., new_steps = {{"measure_dir_name"=>"ResidentialSimulationControls"}=>0}
  new_steps = {}
  json = JSON.parse(File.read(osw), :symbolize_names=>true)
  steps = json[:steps]
  new_steps.each do |new_step, ix|
    insert_new_step = true
    steps.each do |step|
      step.each do |k, v|
        next if k != :measure_dir_name
        next if v != new_step.values[0] # already have this step
        insert_new_step = false
      end
    end
    next unless insert_new_step
    json[:steps].insert(ix, new_step)
  end
  File.open(osw, "w") do |f|
    f.write(JSON.pretty_generate(json)) # format nicely even if not updating the osw with new steps
  end
end

desc 'update all measures (resources, xmls, workflows, README)'
task :update_measures do

  require 'openstudio'
  measures_dir = File.expand_path("../measures/", __FILE__)
  # Update measure xmls
  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" --no-ssl measure --update_all #{measures_dir} >> log"
  puts "Updating measure.xml files..."
  system(command)
  
  # Generate example OSWs
  
  # Check that there is no missing/extra measures in the measure-info.json
  # and get all_measures name (folders) in the correct order
  data_hash = get_and_proof_measure_order_json()
  
  exclude_measures = ["ResidentialHotWaterSolar", 
                      "ResidentialHVACCeilingFan", 
                      "ResidentialHVACDehumidifier",
                      "ResidentialMiscLargeUncommonLoads"]
  
  # SFD
  include_measures = ["ResidentialGeometryCreateSingleFamilyDetached"]
  generate_example_osws(data_hash, 
                        include_measures, 
                        exclude_measures,
                        "example_single_family_detached.osw")
  
  # SFA
  include_measures = ["ResidentialGeometryCreateSingleFamilyAttached"]
  generate_example_osws(data_hash, 
                        include_measures, 
                        exclude_measures,
                        "example_single_family_attached.osw")
  
  # MF
  include_measures = ["ResidentialGeometryCreateMultifamily", "ResidentialConstructionsFinishedRoof"]
  generate_example_osws(data_hash, 
                        include_measures, 
                        exclude_measures,
                        "example_multifamily.osw")
  
  # FloorspaceJS
  #include_measures = ["ResidentialGeometryCreateFromFloorspaceJS"]
  #generate_example_osws(data_hash,
  #                      include_measures, 
  #                      exclude_measures,
  #                      "example_from_floorspacejs.osw")
  
  # Update README.md
  update_readme(data_hash)
  
end

def generate_example_osws(data_hash, include_measures, exclude_measures, 
                          osw_filename, simplify=true)
  # This function will generate OpenStudio OSWs
  # with all the measures in it, in the order specified in /resources/measure-info.json

  require 'openstudio'
  require_relative 'measures/HPXMLtoOpenStudio/resources/meta_measure'

  puts "Updating #{osw_filename}..."
  
  model = OpenStudio::Model::Model.new
  osw_path = "workflows/#{osw_filename}"
  
  if File.exist?(osw_path)
    File.delete(osw_path)
  end
  
  workflowJSON = OpenStudio::WorkflowJSON.new
  workflowJSON.setOswPath(osw_path)
  workflowJSON.addMeasurePath("../measures")
  
  steps = OpenStudio::WorkflowStepVector.new
  
  # Check for invalid measure names
  all_measures = []
  data_hash.each do |group|
    group["group_steps"].each do |group_step|
        group_step["measures"].each do |measure|
            all_measures << measure
        end
    end
  end
  (include_measures + exclude_measures).each do |m|
      next if all_measures.include? m
      puts "Error: No measure found with name '#{m}'."
      exit
  end
  
  data_hash.each do |group|
    group["group_steps"].each do |group_step|
      
        # Default o first measure in step
        measure = group_step["measures"][0]
        
        # Override with include measure?
        include_measures.each do |include_measure|
            if group_step["measures"].include? include_measure
                measure = include_measure
            end
        end
        
        # Skip exclude measures
        if exclude_measures.include? measure
            next 
        end
        
        measure_path = File.expand_path(File.join("../measures", measure), workflowJSON.oswDir.to_s) 

        measure_instance = get_measure_instance("#{measure_path}/measure.rb")
        measure_args = measure_instance.arguments(model).sort_by {|arg| arg.name}
        
        step = OpenStudio::MeasureStep.new(measure)
        if not simplify
            step.setName(measure_instance.name)
            step.setDescription(measure_instance.description)
            step.setModelerDescription(measure_instance.modeler_description)
        end

        # Loop on each argument
        measure_args.each do |arg|
            if arg.hasDefaultValue
                step.setArgument(arg.name, arg.defaultValueAsString)
            elsif arg.required
                puts "Error: No default value provided for #{measure} argument '#{arg.name}'."
                exit
            end
        end
      
        # Push step in Steps
        steps.push(step)
    end 
  end

  workflowJSON.setWorkflowSteps(steps)
  workflowJSON.save
  
  # Strip created_at/updated_at
  require 'json'
  file = File.read(osw_path)
  data_hash = JSON.parse(file)
  data_hash.delete("created_at")
  data_hash.delete("updated_at")
  File.write(osw_path, JSON.pretty_generate(data_hash))
  
end

def update_readme(data_hash)
  # This method updates the "Measure Order" table in the README.md
  
  puts "Updating README measure order..."
  
  table_flag_start = "MEASURE_WORKFLOW_START"
  table_flag_end = "MEASURE_WORKFLOW_END"
  
  readme_path = "README.md"
  
  # Create table
  table_lines = []
  table_lines << "|Group|Measure|Dependencies*|\n"
  table_lines << "|:---|:---|:---|\n"
  data_hash.each do |group|
    new_group = true
    group["group_steps"].each do |group_step|
      grp = ""
      if new_group
        grp = group["group_name"]
      end
      name = group_step['name']
      deps = group_step['dependencies']
      table_lines << "|#{grp}|#{name}|#{deps}|\n"
      new_group = false
    end
  end
  
  # Embed table in README text
  in_lines = IO.readlines(readme_path)
  out_lines = []
  inside_table = false
  in_lines.each do |in_line|
    if in_line.include? table_flag_start
      inside_table = true
      out_lines << in_line
      out_lines << table_lines
    elsif in_line.include? table_flag_end
      inside_table = false
      out_lines << in_line
    elsif not inside_table
      out_lines << in_line
    end
  end
  
  File.write(readme_path, out_lines.join(""))
  
end

def get_and_proof_measure_order_json()
  # This function will check that all measure folders (in measures/) 
  # are listed in the /resources/measure-info.json and vice versa
  # and return the list of all measures used in the proper order
  #
  # @return {data_hash} of measure-info.json

  # List all measures in measures/ folder
  beopt_measure_folder = File.expand_path("../measures/", __FILE__)
  all_measures = Dir.entries(beopt_measure_folder).select{|entry| entry.start_with?('Residential', 'ZoneMultipliers')}
  
  # Load json, and get all measures in there
  json_file = "workflows/measure-info.json"
  json_path = File.expand_path("../#{json_file}", __FILE__)
  data_hash = JSON.parse(File.read(json_path))

  measures_json = []
  data_hash.each do |group|
    group["group_steps"].each do |group_step|
      measures_json += group_step["measures"]
    end 
  end
  
  # Check for missing in JSON file
  missing_in_json = all_measures - measures_json
  if missing_in_json.size > 0
    puts "Warning: There are #{missing_in_json.size} measures missing in '#{json_file}': #{missing_in_json.join(",")}"
  end

  # Check for measures in JSON that don't have a corresponding folder
  extra_in_json = measures_json - all_measures
  if extra_in_json.size > 0
    puts "Warning: There are #{extra_in_json.size} measures extra in '#{json_file}': #{extra_in_json.join(",")}"
  end
  
  return data_hash
end

desc 'update urdb tariffs'
task :update_tariffs do
  require 'csv'
  require 'net/https'
  require 'zip'

  tariffs_path = "./resources/tariffs"
  tariffs_zip = "#{tariffs_path}.zip"
  
  if not File.exists?(tariffs_path)
    FileUtils.mkdir_p("./resources/tariffs")  
  end
  
  if File.exists?(tariffs_zip)
    Zip::File.open(tariffs_zip) do |zip_file|
      zip_file.each do |entry|
        next unless entry.file?
        entry_path = File.join(tariffs_path, entry.name)
        zip_file.extract(entry, entry_path) unless File.exists?(entry_path)
      end
    end
    FileUtils.rm_rf(tariffs_zip)
  end
  
  result = get_tariff_json_files(tariffs_path)
  
  if result
    Zip::File.open(tariffs_zip, Zip::File::CREATE) do |zip_file|
        Dir[File.join(tariffs_path, "*")].each do |entry|
          zip_file.add(entry.sub(tariffs_path + "/", ""), entry)
        end
    end
    FileUtils.rm_rf(tariffs_path)
  end

end

def get_tariff_json_files(tariffs_path)
  require 'parallel'

  STDOUT.puts "Enter API Key:"
  api_key = STDIN.gets.strip
  return false if api_key.empty?

  url = URI.parse("https://api.openei.org/utility_rates?")
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE  

  rows = CSV.read("./resources/utilities.csv", {:encoding=>'ISO-8859-1'})
  rows = rows[1..-1] # ignore header
  interval = 1
  report_at = interval
  timestep = Time.now
  num_parallel = 1 # FIXME: segfault when num_parallel > 1
  Parallel.each_with_index(rows, in_threads: num_parallel) do |row, i|
  
    utility, eiaid, name, label = row

    params = { 'version' => 3, 'format' => 'json', 'detail' => 'full', 'getpage' => label, 'api_key' => api_key }
    url.query = URI.encode_www_form(params)
    request = Net::HTTP::Get.new(url.request_uri)    
    response = http.request(request)
    response = JSON.parse(response.body, :symbolize_names=>true)

    if response.keys.include? :error
      puts "#{response[:error][:message]}."
      if response[:error][:message].include? "exceeded your rate limit"
        false
      end
      next
    end
    
    entry_path = File.join(tariffs_path, "#{label}.json")

    if response[:items].empty?
      puts "Skipping #{entry_path}: empty tariff."
      next
    end

    File.open(entry_path, "w") do |f|
      f.write(response.to_json)
    end
    puts "Added #{entry_path}."

    # Report out progress
    if i.to_f * 100 / rows.length >= report_at
      puts "INFO: Completed #{report_at}%; #{(Time.now - timestep).round}s"
      report_at += interval
      timestep = Time.now
    end

  end
  
  return true

end
