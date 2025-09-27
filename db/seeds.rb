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

# ---------------------------------------------------------------------------
# Default sample survey + competencies + questions (idempotent)
# ---------------------------------------------------------------------------
survey = Survey.find_or_create_by!(title: "Default Sample Survey", semester: "Fall 2025")

comp_prof = Competency.find_or_create_by!(survey_id: survey.id, name: "Professional Skills")
comp_tech = Competency.find_or_create_by!(survey_id: survey.id, name: "Technical Skills")

# Questions for Professional Skills
Question.find_or_create_by!(competency_id: comp_prof.id, question_order: 1, question: "I communicate effectively with my peers.") do |q|
  q.question_type = 'radio'
  q.answer_options = [ 'Strongly disagree', 'Disagree', 'Neutral', 'Agree', 'Strongly agree' ].to_json
end

Question.find_or_create_by!(competency_id: comp_prof.id, question_order: 2, question: "Describe a recent teamwork experience.") do |q|
  q.question_type = 'text'
  q.answer_options = nil
end

# Questions for Technical Skills
Question.find_or_create_by!(competency_id: comp_tech.id, question_order: 1, question: "Rate your proficiency in Ruby on Rails.") do |q|
  q.question_type = 'select'
  q.answer_options = [ 'Beginner', 'Intermediate', 'Advanced' ].to_json
end

Question.find_or_create_by!(competency_id: comp_tech.id, question_order: 2, question: "Which frameworks have you used recently?") do |q|
  q.question_type = 'text'
  q.answer_options = nil
end

puts "Ensured default survey and questions exist (survey id=#{survey.id})"

# Ensure a student account for local login/testing
Student.find_or_create_by!(email: 'faqiangmei@gmail.com') do |s|
  s.name = 'Faqiang Mei'
  s.net_id = 'fmei'
  # valid tracks per Student enum are 'residential' and 'executive'
  s.track = 'residential'
  puts "Created student: #{s.email}"
end
