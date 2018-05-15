require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialQualityFaultProgramTest < MiniTest::Test
  
  def test_argument_error
    args_hash = {}
    args_hash["rated_cfm_per_ton"] = "100"
    result = _test_error("SFD_HVACSizing_Equip_GF_AC1_Fixed.osm", args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Input(s) are outside the valid range.")
  end
  
  def test_argument_warning
    args_hash = {}
    args_hash["actual_cfm_per_ton"] = "650"
    expected_num_del_objects = {}
    expected_num_new_objects = {"EnergyManagementSystemSensor"=>2, "EnergyManagementSystemActuator"=>2, "EnergyManagementSystemProgram"=>1, "EnergyManagementSystemProgramCallingManager"=>1}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_GF_AC1_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end
  
  def test_apply_fault_to_single_speed_central_ac
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"EnergyManagementSystemSensor"=>2, "EnergyManagementSystemActuator"=>2, "EnergyManagementSystemProgram"=>1, "EnergyManagementSystemProgramCallingManager"=>1}
    expected_values = {"res_installation_quality_fault_1_prog"=>{"F"=>0}, "SensorLocation"=>"living zone"}
    _test_measure("SFD_HVACSizing_Equip_GF_AC1_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_apply_fault_to_two_speed_central_ac
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_EF_AC2_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end
  
  def test_apply_fault_to_single_speed_ashp
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"EnergyManagementSystemSensor"=>2, "EnergyManagementSystemActuator"=>4, "EnergyManagementSystemProgram"=>1, "EnergyManagementSystemProgramCallingManager"=>1}
    expected_values = {"res_installation_quality_fault_1_prog"=>{"F"=>0}, "SensorLocation"=>"living zone"}
    _test_measure("SFD_HVACSizing_Equip_ASHP1_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_apply_fault_to_two_speed_ashp
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_ASHP2_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end
  
  def test_apply_fault_to_mshp
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_HVACSizing_Equip_MSHP_BB_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end
  
  def test_apply_fault_to_faulted_single_speed_central_ac
    args_hash = {}
    args_hash["actual_cfm_per_ton"] = "280"
    expected_num_del_objects = {"EnergyManagementSystemSensor"=>2, "EnergyManagementSystemActuator"=>2, "EnergyManagementSystemProgram"=>1, "EnergyManagementSystemProgramCallingManager"=>1}
    expected_num_new_objects = {"EnergyManagementSystemSensor"=>2, "EnergyManagementSystemActuator"=>2, "EnergyManagementSystemProgram"=>1, "EnergyManagementSystemProgramCallingManager"=>1}
    expected_values = {"res_installation_quality_fault_1_prog"=>{"F"=>-0.3}, "SensorLocation"=>"living zone"}
    _test_measure("SFD_HVACSizing_Equip_GF_Faulted_AC1_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_apply_fault_to_faulted_single_speed_ashp
    args_hash = {}
    args_hash["actual_cfm_per_ton"] = "280"
    expected_num_del_objects = {"EnergyManagementSystemSensor"=>2, "EnergyManagementSystemActuator"=>4, "EnergyManagementSystemProgram"=>1, "EnergyManagementSystemProgramCallingManager"=>1}
    expected_num_new_objects = {"EnergyManagementSystemSensor"=>2, "EnergyManagementSystemActuator"=>4, "EnergyManagementSystemProgram"=>1, "EnergyManagementSystemProgramCallingManager"=>1}
    expected_values = {"res_installation_quality_fault_1_prog"=>{"F"=>-0.3}, "SensorLocation"=>"living zone"}
    _test_measure("SFD_HVACSizing_Equip_Faulted_ASHP1_Fixed.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_single_family_attached_apply_fault_to_single_speed_central_ac
    num_units = 4
    args_hash = {}
    args_hash["actual_cfm_per_ton"] = "280"
    expected_num_del_objects = {}
    expected_num_new_objects = {"EnergyManagementSystemSensor"=>2*num_units, "EnergyManagementSystemActuator"=>2*num_units, "EnergyManagementSystemProgram"=>1*num_units, "EnergyManagementSystemProgramCallingManager"=>1*num_units}
    expected_values = {"res_installation_quality_fault_1_prog"=>{"F"=>-0.3}, \
                       "res_installation_quality_fault_2_prog"=>{"F"=>-0.3}, \
                       "res_installation_quality_fault_3_prog"=>{"F"=>-0.3}, \
                       "res_installation_quality_fault_4_prog"=>{"F"=>-0.3}}
    _test_measure("SFA_4units_1story_SL_UA_3Beds_2Baths_Denver_CentralAC_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_multifamily_apply_fault_to_single_speed_central_ac
    num_units = 8
    args_hash = {}
    args_hash["actual_cfm_per_ton"] = "280"
    expected_num_del_objects = {}
    expected_num_new_objects = {"EnergyManagementSystemSensor"=>2*num_units, "EnergyManagementSystemActuator"=>2*num_units, "EnergyManagementSystemProgram"=>1*num_units, "EnergyManagementSystemProgramCallingManager"=>1*num_units}
    expected_values = {"res_installation_quality_fault_1_prog"=>{"F"=>-0.3}, \
                       "res_installation_quality_fault_2_prog"=>{"F"=>-0.3}, \
                       "res_installation_quality_fault_3_prog"=>{"F"=>-0.3}, \
                       "res_installation_quality_fault_4_prog"=>{"F"=>-0.3}, \
                       "res_installation_quality_fault_5_prog"=>{"F"=>-0.3}, \
                       "res_installation_quality_fault_6_prog"=>{"F"=>-0.3}, \
                       "res_installation_quality_fault_7_prog"=>{"F"=>-0.3}, \
                       "res_installation_quality_fault_8_prog"=>{"F"=>-0.3}}
    _test_measure("MF_8units_1story_SL_3Beds_2Baths_Denver_CentralAC_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ResidentialQualityFaultProgram.new

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

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end  
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ResidentialQualityFaultProgram.new

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
    
    # save the model to test output directory
    # output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/test.osm")
    # model.save(output_file_path, true)
    
    # show_output(result)
    
    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert_equal(num_infos, result.info.size)
    assert_equal(num_warnings, result.warnings.size)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["OutputVariable"]
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
        if ["EnergyManagementSystemProgram"].include? obj_type
          new_object.lines.each do |line|
            next unless line.downcase.start_with? "set"
            lhs, rhs = line.split("=")
            lhs = lhs.gsub("Set", "").gsub("set", "").strip
            rhs = rhs.gsub(",", "").gsub(";", "").strip
            actual_values[new_object.name.to_s][lhs] = rhs
          end
        elsif obj_type == "EnergyManagementSystemSensor"
          next unless new_object.outputVariable.is_initialized
          next if new_object.outputVariable.get.name.to_s != "Zone Mean Air Temperature"
          actual_values["SensorLocation"] = new_object.keyName
        end
      end
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
    
    return model
  end
  
end
