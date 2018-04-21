require 'bundler'
Bundler.setup

require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'

require 'pp'
require 'colored'
require 'json'


desc 'perform tasks related to BCL'
namespace :measures do
  # change the file: users/username/.bcl/config.yml
  # to the ID of the BCL group you want your measures to go into
  # get the group id number from the URL of the group on BCL
  # https://bcl.nrel.gov/node/37347 - the group ID here is 37347
  # you must be an administrator or editor member of a group to
  # upload content to that group

  desc 'Generate measures to prepare for upload to BCL '
  task :generate do
    require 'bcl'
    # verify staged directory exists
    FileUtils.mkdir_p('./staged')
    dirs = Dir.glob('./measures/*')
    dirs.each do |dir|
      next if dir.include?('Rakefile')
      current_d = Dir.pwd
      measure_name = File.basename(dir)
      puts "Generating #{measure_name}"

      Dir.chdir(dir)
      # puts Dir.pwd

      destination = "../../staged/#{measure_name}.tar.gz"
      FileUtils.rm(destination) if File.exist?(destination)
      files = Pathname.glob('**/*')
      files.each do |f|
        puts "  #{f}"
      end
      paths = []
      files.each do |file|
        paths << file.to_s
      end

      BCL.tarball(destination, paths)
      Dir.chdir(current_d)
    end
  end

  desc 'Push generated measures to the BCL group defined in .bcl/config.yml'
  task :push do
    require 'bcl'
    # grab all the tar files and push to bcl
    measures = []
    paths = Pathname.glob('./staged/*.tar.gz')
    paths.each do |path|
      puts path
      measures << path.to_s
    end
    bcl = BCL::ComponentMethods.new
    bcl.login
    bcl.push_contents(measures, true, 'nrel_measure')
  end

  desc 'update generated measures on the BCL'
  task :update do
    require 'bcl'
    # grab all the tar files and push to bcl
    measures = []
    paths = Pathname.glob('./staged/*.tar.gz')
    paths.each do |path|
      puts path
      measures << path.to_s
    end
    bcl = BCL::ComponentMethods.new
    bcl.login
    bcl.update_contents(measures, true)
  end

  desc 'test the BCL login credentials defined in .bcl/config.yml'
  task :test_bcl_login do
    require 'bcl'
    bcl = BCL::ComponentMethods.new
    bcl.login
  end

  desc 'Create measure zip files for upload to BCL '
  task :zip do
    Dir.glob('./measures/*').each do |dir|
      current_d = Dir.pwd
      Dir.chdir(dir)
      if File.exists?("measure.zip")
        File.delete("measure.zip")
      end
      command = '"c:/Program Files/7-Zip\7z.exe" a measure.zip *'
      system(command)
      Dir.chdir(current_d)
    end
  end
  
end # end the :measures namespace


desc 'perform tasks related to unit tests'
namespace :test do

  desc 'Run unit tests for all measures'
  Rake::TestTask.new('all') do |t|
    t.libs << 'test'
    t.test_files = Dir['measures/*/tests/*.rb'] + Dir['workflows/tests/*.rb']
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
  
    # Generate hash that maps osw's to measures
    osw_map = {}
    measures = Dir.entries(File.expand_path("../measures/", __FILE__)).select {|entry| File.directory? File.join(File.expand_path("../measures/", __FILE__), entry) and !(entry == '.' || entry == '..') }
    measures.each do |m|
        testrbs = Dir[File.expand_path("../measures/#{m}/tests/*.rb", __FILE__)]
        if testrbs.size == 1
            # Get osm's specified in the test rb
            testrb = testrbs[0]
            osms = get_osms_listed_in_test(testrb)
            osms.each do |osm|
                osw = File.basename(osm).gsub('.osm','.osw')
                if not osw_map.keys.include?(osw)
                    osw_map[osw] = []
                end
                osw_map[osw] << m
            end
        elsif testrbs.size > 1
            fail "ERROR: Multiple .rb files found in #{m} tests dir."
      end
    end
    
    osw_files = Dir.entries(osw_path).select {|entry| entry.end_with?(".osw")}
    if File.exists?(File.expand_path("../log", __FILE__))
        FileUtils.rm(File.expand_path("../log", __FILE__))
    end

    # Print warnings about unused OSWs
    osw_files.each do |osw|
        next if not osw_map[osw].nil?
        puts "Warning: Unused OSW '#{osw}'."
    end

    # Print more warnings
    osw_map.each do |osw, _measures|
        next if osw_files.include? osw
        puts "Warning: OSW not found '#{osw}'."
    end
    
    # Remove any extra osm's in the measures test dirs
    measures.each do |m|
        osms = Dir[File.expand_path("../measures/#{m}/tests/*.osm", __FILE__)]
        osms.each do |osm|
            osw = File.basename(osm).gsub('.osm','.osw')
            if osw_map[osw].nil? or !osw_map[osw].include?(m)
                puts "Extra file #{osw} found in #{m}/tests. Do you want to delete it? (y/n)"
                input = STDIN.gets.strip.downcase
                next if input != "y"
                FileUtils.rm(osm)
                puts "File deleted."
            end
        end
    end
    
    cli_path = OpenStudio.getOpenStudioCLI

    num_osws = 0
    osw_files.each do |osw|
        next if osw_map[osw].nil?
        num_osws += 1
    end

    osw_files.each do |osw|
    
        next if osw_map[osw].nil?

        # Generate osm from osw
        osw_filename = osw
        num_tot += 1
        
        puts "[#{num_tot}/#{num_osws}] Regenerating osm from #{osw}..."
        osw = File.expand_path("../test/osw_files/#{osw}", __FILE__)
        osm = File.expand_path("../test/osw_files/run/in.osm", __FILE__)
        osw_gem = File.expand_path("gems/OpenStudio-workflow-gem/lib/") # Speed up osm generation
        command = "\"#{cli_path}\" -I #{osw_gem} run -w #{osw} -m >> log"
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
                    file_line = file_data[0] + "../tests/" + file_data[-1]
                end
                f.write(file_line)
            end
        end

        # Copy to appropriate measure test dirs
        osm_filename = osw_filename.gsub(".osw", ".osm")
        num_copied = 0
        osw_map[osw_filename].each do |measure|
            measure_test_dir = File.expand_path("../measures/#{measure}/tests/", __FILE__)
            FileUtils.cp(osm, File.expand_path("#{measure_test_dir}/#{osm_filename}", __FILE__))
            num_copied += 1
        end
        puts "  Copied to #{num_copied} measure(s)."
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

def get_osms_listed_in_test(testrb)
    osms = []
    if not File.exists?(testrb)
      return osms
    end
    str = File.readlines(testrb).join("\n")
    osms = str.scan(/\w+\.osm/)
    return osms.uniq
end


desc 'update all measures (resources, xmls, workflows, README)'
task :update_measures do

  require 'openstudio'

  puts "Updating measure resources..."
  measures_dir = File.expand_path("../measures/", __FILE__)
  
  measures = Dir.entries(measures_dir).select {|entry| File.directory? File.join(File.expand_path("../measures/", __FILE__), entry) and !(entry == '.' || entry == '..') }
  measures.each do |m|
    measurerb = File.expand_path("../measures/#{m}/measure.rb", __FILE__)
    
    # Get recursive list of resources required based on looking for 'require FOO' in rb files
    resources = get_requires_from_file(measurerb)

    # Add any additional resources specified in resource_to_measure_mapping.csv
    subdir_resources = {} # Handle resources in subdirs
    File.open(File.expand_path("../resources/resource_to_measure_mapping.csv", __FILE__)) do |file|
      file.each do |line|
        line = line.chomp.split(',').reject { |l| l.empty? }
        measure = line.delete_at(0)
        next if measure != m
        line.each do |resource|
          fullresource = File.expand_path("../resources/#{resource}", __FILE__)
          next if resources.include?(fullresource)
          resources << fullresource
          if resource != File.basename(resource)
            subdir_resources[File.basename(resource)] = resource
          end
        end
      end
    end
    
    # Add/update resource files as needed
    resources.each do |resource|
      if not File.exist?(resource)
        puts "Cannot find resource: #{resource}."
        next
      end
      r = File.basename(resource)
      dest_resource = File.expand_path("../measures/#{m}/resources/#{r}", __FILE__)
      measure_resource_dir = File.dirname(dest_resource)
      if not File.directory?(measure_resource_dir)
        FileUtils.mkdir_p(measure_resource_dir)
      end
      if not File.file?(dest_resource)
        FileUtils.cp(resource, measure_resource_dir)
        puts "Added #{r} to #{m}/resources."
      elsif not FileUtils.compare_file(resource, dest_resource)
        FileUtils.cp(resource, measure_resource_dir)
        puts "Updated #{r} in #{m}/resources."
      end
    end
    
    # Any extra resource files?
    if File.directory?(File.expand_path("../measures/#{m}/resources", __FILE__))
      Dir.foreach(File.expand_path("../measures/#{m}/resources", __FILE__)) do |item|
        next if item == '.' or item == '..'
        if subdir_resources.include?(item)
          item = subdir_resources[item]
        end
        resource = File.expand_path("../resources/#{item}", __FILE__)
        next if resources.include?(resource)
        item_path = File.expand_path("../measures/#{m}/resources/#{item}", __FILE__)
        if File.directory?(item_path)
            puts "Extra dir #{item} found in #{m}/resources. Do you want to delete it? (y/n)"
            input = STDIN.gets.strip.downcase
            next if input != "y"
            puts "deleting #{item_path}"
            FileUtils.rm_rf(item_path)
            puts "Dir deleted."
        else
            next if item == 'measure-info.json'
            puts "Extra file #{item} found in #{m}/resources. Do you want to delete it? (y/n)"
            input = STDIN.gets.strip.downcase
            next if input != "y"
            FileUtils.rm(item_path)
            puts "File deleted."
        end
      end
    end
    
  end
  
  # Update measure xmls
  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" measure --update_all #{measures_dir} >> log"
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
  require_relative 'resources/meta_measure'

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
  all_measures = Dir.entries(beopt_measure_folder).select{|entry| entry.start_with?('Residential')}
  
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

def get_requires_from_file(filerb)
  requires = []
  if not File.exists?(filerb)
    return requires
  end
  File.open(filerb) do |file|
    file.each do |line|
      line.strip!
      next if line.nil?
      next if not (line.start_with?("require \"\#{File.dirname(__FILE__)}/") or line.start_with?("require\"\#{File.dirname(__FILE__)}/"))
      line.chomp!("\"")
      d = line.split("/")
      requirerb = File.expand_path("../resources/#{d[-1].to_s}.rb", __FILE__)
      requires << requirerb
    end   
  end
  # Recursively look for additional requirements
  requires.each do |requirerb|
    get_requires_from_file(requirerb).each do |rb|
      next if requires.include?(rb)
      requires << rb
    end
  end
  return requires
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
