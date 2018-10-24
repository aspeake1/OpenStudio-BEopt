require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class UAReportTest < MiniTest::Test

  def test_ua
    uas = {
            "floor_fin_ins_unfin_attic"=>1480, # unfinished attic floor
            # "floor_fin_ins_unfin"=>0, # interzonal or cantilevered floor
            "floor_fin_unins_fin"=>4018, # floor between 1st/2nd story living spaces
            # "floor_unfin_unins_unfin"=>0, # floor between garage and attic
            # "floor_fnd_grnd_fin_b"=>0, # finished basement floor
            # "floor_fnd_grnd_unfin_b"=>0, # unfinished basement floor
            "floor_fnd_grnd_fin_slab"=>17814, # finished slab
            # "floor_fnd_grnd_unfin_slab"=>0, # garage slab
            # "floor_unfin_b_ins_fin"=>0, # unfinished basement ceiling
            # "floor_cs_ins_fin"=>0, # crawlspace ceiling
            # "floor_pb_ins_fin"=>0, # pier beam ceiling
            # "floor_fnd_grnd_cs"=>0, # crawlspace floor
            # "roof_unfin_unins_ext"=>0, # garage roof
            "roof_unfin_ins_ext"=>3712, # unfinished attic roof
            # "roof_fin_ins_ext"=>0, # finished attic roof
            "wall_ext_ins_fin"=>7023, # living exterior wall
            # "wall_ext_ins_unfin"=>0, # attic gable wall under insulated roof
            "wall_ext_unins_unfin"=>216, # garage exterior wall or attic gable wall under uninsulated roof
            # "wall_fnd_grnd_fin_b"=>0, # finished basement wall
            # "wall_fnd_grnd_unfin_b"=>0, # unfinished basement wall
            # "wall_fnd_grnd_cs"=>0, # crawlspace wall
            # "wall_int_fin_ins_unfin"=>0, # interzonal wall
            "wall_int_fin_unins_fin"=>3245, # wall between two finished spaces
            # "wall_int_unfin_unins_unfin"=>0, # wall between two unfinished spaces
            # "living_space_footing_construction"=>0, # living space footing construction
            # "garage_space_footing_construction"=>0, # garage space footing construction
            "door"=>51, # exterior door
            "residential_furniture_construction_living_space"=>4407, # furniture in living
            "residential_furniture_construction_living_space_story_2"=>4407, # furniture in living, second floor
            # "residential_furniture_construction_unfinished_basement_space"=>0, # furniture in unfinished basement
            # "residential_furniture_construction_finished_basement_space"=>0, # furniture in finished basement
            # "residential_furniture_construction_garage_space"=>0 # furniture in garage
          }
    _test_uas("example_single_family_detached.osm", uas)
  end
    
  private

  def _test_uas(osm_file, uas)
    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.join(File.dirname(__FILE__), osm_file))
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # create an instance of the measure
    measure = UAReport.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    
    # Check for correct thermal capacitance values
    uas.each do |constr_name, ua|
      constr = nil
      model.getConstructions.each do |construction|
        next if OpenStudio::toUnderscoreCase(construction.name.to_s) != constr_name
        constr = construction
      end
      assert(!constr.nil?)
      surface_area, name = measure.get_surface_area(model, constr)
      foundation_area, name = measure.get_foundation_area(model, constr)
      sub_surface_area, name = measure.get_sub_surface_area(model, constr)
      internal_mass_area, name = measure.get_internal_mass_area(model, constr)
      area = surface_area + foundation_area + sub_surface_area + internal_mass_area
      value = measure.get_ua(constr, area)
      assert(!value.nil?)
      assert_in_epsilon(ua, value, 0.05)
    end
  end

end
