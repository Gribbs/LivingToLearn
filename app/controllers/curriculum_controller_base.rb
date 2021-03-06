class CurriculumControllerBase < ApplicationController

  before_filter :lookup_district

  before_filter :lookup_school,
    :only => [:school,:standard,:strand]

  before_filter :lookup_curriculum_content_areas,
    :only => [:school,:standard,:strand]

  before_filter :lookup_standards,
    :only => [:school,:standard,:strand]

  before_filter :lookup_standard,
    :only => [:standard,:strand]

  before_filter :lookup_strands,
    :only => [:strand]

  before_filter :lookup_strand,
    :only => [:strand]

  def lookup_strand
    @strand = @strands.select{ |strand|
      strand.code == params["strand_code"]
    }[0]
  end

  def lookup_district
    @district = Government::SchoolDistrictKvn.find_by_nickname(params[:district_nickname])
  end

  def lookup_school
    @school =  @district.schools.select{ |school|
      school.government_district_id == @district.id
    }.first
  end

####################
#
####################

  def lookup_standards
    @standards = @curriculum_content_areas.map{ |content_area|
      content_area.get_sorted_curriculum_standards
    }.flatten
  end

  def lookup_standard
    @standard = @standards.select{ |standard|
      standard.code == params["standard_code"]
    }[0]
  end

  def lookup_strands
    @strands = @standard.curriculum_strands
  end

###################
# Override These!
###################
  def lookup_curriculum_content_areas
  end

  def district
  end

  def school
  end

  def standard
  end

  def strand
  end

end
