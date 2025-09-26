# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create admin user
Admin.find_or_create_by(email: 'rainsuds@tamu.edu') do |admin|
  admin.full_name = 'System Administrator'
  admin.role = 'admin'
  puts "Created admin user: #{admin.email}"
end

Admin.find_or_create_by(email: 'jcwtexasanm@tamu.edu') do |admin|
  admin.full_name = 'System Administrator'
  admin.role = 'admin'
  puts "Created admin user: #{admin.email}"
end

Admin.find_or_create_by(email: 'anthuan374@tamu.edu') do |admin|
  admin.full_name = 'System Administrator'
  admin.role = 'admin'
  puts "Created admin user: #{admin.email}"
end

Admin.find_or_create_by(email: 'faqiang_mei@tamu.edu') do |admin|
  admin.full_name = 'System Administrator'
  admin.role = 'admin'
  puts "Created admin user: #{admin.email}"
end

Admin.find_or_create_by(email: 'jonah.belew@tamu.edu') do |admin|
  admin.full_name = 'System Administrator'
  admin.role = 'admin'
  puts "Created admin user: #{admin.email}"
end

Admin.find_or_create_by(email: 'cstebbins@tamu.edu') do |admin|
  admin.full_name = 'System Administrator'
  admin.role = 'admin'
  puts "Created admin user: #{admin.email}"
end

Admin.find_or_create_by(email: 'kum@tamu.edu') do |admin|
  admin.full_name = 'System Administrator'
  admin.role = 'admin'
  puts "Created admin user: #{admin.email}"
end

Admin.find_or_create_by(email: 'ruoqiwei@tamu.edu') do |admin|
  admin.full_name = 'System Administrator'
  admin.role = 'admin'
  puts "Created admin user: #{admin.email}"
end


# Create some sample surveys
Survey.find_or_create_by!(id: 1) do |s|
  s.survey_id = "Survey 1"
  s.assigned_date = Date.today
  s.completion_date = nil
  s.approval_date = nil
end

Survey.find_or_create_by!(id: 2) do |s|
  s.survey_id = "Survey 2"
  s.assigned_date = Date.today
  s.completion_date = nil
  s.approval_date = nil
end

Survey.find_or_create_by!(id: 3) do |s|
  s.survey_id = "Survey 3"
  s.assigned_date = Date.today
  s.completion_date = nil
  s.approval_date = nil
end

puts "Created default surveys"

# Ensure faqiangmei@gmail.com exists as a login admin with student role and corresponding Student
student_admin = Admin.find_or_create_by(email: 'faqiangmei@gmail.com') do |a|
  a.full_name = 'Faqiang Mei'
  a.role = 'student'
  puts "Created student admin: #{a.email}"
end

Student.find_or_create_by(email: 'faqiangmei@gmail.com') do |s|
  s.name = 'Faqiang Mei'
  s.NetID = 'faqiangmei'
  s.track = 0
  s.advisor_id = nil
  puts "Created Student record for #{s.email}"
end

# Assign surveys 1..3 to this student (create SurveyResponse if missing)
student = Student.find_by(email: 'faqiangmei@gmail.com')
if student
  (1..3).each do |i|
    survey = Survey.find_by(survey_id: i) || Survey.find_by(id: i) || Survey.find_or_create_by(survey_id: i)
    sr = SurveyResponse.find_or_initialize_by(student_id: student.id, survey_id: survey.id)
    if sr.new_record?
      sr.status = SurveyResponse.statuses[:not_started]
      sr.advisor_id = student.advisor_id
      sr.save!
      puts "Assigned survey #{survey.id} to student #{student.email}"
    end
  end
end
