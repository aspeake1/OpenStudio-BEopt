require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'

class EnergyRatingIndexTest < MiniTest::Test

  def test_sample_hpxml_file
  
    os_clis = Dir["C:/openstudio-*/bin/openstudio.exe"] + Dir["/usr/bin/openstudio"] + Dir["/usr/local/bin/openstudio"]
    assert(os_clis.size > 0)
    os_cli = os_clis[-1]
    
    parent_dir = File.join(File.dirname(__FILE__), "..")
    command = "cd #{parent_dir} && \"#{os_cli}\" execute_ruby_script energy_rating_index.rb -x sample_files/valid.xml -e sample_files/denver.epw"
    system(command)
    
    # Output files exist?
    ref_hpxml = File.join(parent_dir, "results", "HERSReferenceHome.xml")
    rated_hpxml = File.join(parent_dir, "results", "HERSRatedHome.xml")
    results_csv = File.join(parent_dir, "results", "results.csv")
    worksheet_csv = File.join(parent_dir, "results", "worksheet.csv")
    
    assert(File.exists?(ref_hpxml))
    assert(File.exists?(rated_hpxml))
    assert(File.exists?(results_csv))
    assert(File.exists?(worksheet_csv))
  end

end
