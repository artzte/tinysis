module AssignmentHelper

  def assignment_header_image(assignment, print = false)
    fn = "ah_#{assignment.id}"
    fn << "p" if print
    image_tag "/assets/gradesheet/#{fn}.gif"
  end

end
