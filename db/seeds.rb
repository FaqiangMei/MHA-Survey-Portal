# db/seeds.rb
require "json"
require "securerandom"

puts "\n== Seeding Health sample data =="

models_to_clear = [
  Notification,
  StudentQuestion,
  SurveyQuestion,
  CategoryQuestion,
  Feedback,
  Question,
  Category,
  Survey,
  Student,
  Advisor,
  Admin,
  User
]

puts "🧹 Deleting existing records..."
models_to_clear.each do |model|
  model.delete_all
  puts "   • cleared #{model.name}"
end

seed_user = lambda do |email:, name:, role:, uid: nil, avatar_url: nil|
  role_value = User.normalize_role(role) || role.to_s
  user = User.find_or_initialize_by(email: email)
  user.name = name
  user.uid = uid.presence || user.uid.presence || email
  user.avatar_url = avatar_url if avatar_url.present?
  user.role = role_value
  user.save!
  user.send(:ensure_role_profile!)
  user
end

puts "• Creating administrative accounts"
admin_accounts = [
  { email: "rainsuds@tamu.edu", name: "System Administrator" },
  { email: "anthuan374@tamu.edu", name: "System Administrator" },
  { email: "faqiang_mei@tamu.edu", name: "System Administrator" },
  { email: "jonah.belew@tamu.edu", name: "System Administrator" },
  { email: "cstebbins@tamu.edu", name: "System Administrator" },
  { email: "kum@tamu.edu", name: "System Administrator" },
  { email: "ruoqiwei@tamu.edu", name: "System Administrator" }
]

admin_users = admin_accounts.map do |attrs|
  seed_user.call(email: attrs[:email], name: attrs[:name], role: :admin)
end

puts "• Creating advisor accounts"
advisor_users = [
  seed_user.call(email: "advisor.one@tamu.edu", name: "Advisor One", role: :advisor),
  seed_user.call(email: "advisor.two@tamu.edu", name: "Advisor Two", role: :advisor)
]

advisors = advisor_users.map(&:advisor_profile)

puts "• Creating sample students"
students_seed = [
  { email: "faqiangmei@tamu.edu", name: "Faqiang Mei", track: "Residential", advisor: advisors.first },
  { email: "j.belew714@tamu.edu", name: "J Belew", track: "Residential", advisor: advisors.first },
  { email: "rainsuds123@tamu.edu", name: "Tee Li", track: "Executive", advisor: advisors.last },
  { email: "anthuan374@tamu.edu", name: "Anthuan", track: "Residential", advisor: advisors.last },
  { email: "meif7749@tamu.edu", name: "Executive Test", track: "Executive", advisor: advisors.last }
]

students = students_seed.map do |attrs|
  user = seed_user.call(email: attrs[:email], name: attrs[:name], role: :student)
  profile = user.student_profile || Student.new(student_id: user.id)
  profile.assign_attributes(track: attrs[:track], advisor: attrs[:advisor])
  profile.save!
  profile
end

puts "• Creating surveys, categories, and questions"

def create_question!(question_attrs)
  options = question_attrs[:options]
  Question.create!(
    question: question_attrs[:question],
    question_order: question_attrs[:order],
    question_type: question_attrs[:type],
    required: question_attrs.fetch(:required, true),
    answer_options: options.present? ? options.to_json : nil
  )
end

surveys_data = [
  {
    title: "Executive Survey",
    semester: "Fall 2025",
    categories: [
      {
        name: "Semester",
        description: "Semester Activity Information",
        questions: [
          { order: 1, question: "Which student organizations are you currently a member of?", type: "multiple_choice", options: ["AFHL", "AAHL", "HFA", "IHI", "MGMA", "AC3"], required: true },
          { order: 2, question: "Other Organization - please specify the name", type: "short_answer", required: false },
          { order: 3, question: "Did you participate in any professional meetings?", type: "multiple_choice", options: ["Yes", "No"], required: true },
          { order: 4, question: "If yes, please provide the meeting name, date, and location", type: "short_answer", required: false },
          { order: 5, question: "If no, why not?", type: "short_answer", required: false },
          { order: 6, question: "Did you compete in a Case Competition?", type: "multiple_choice", options: ["Yes", "No"], required: true },
          { order: 7, question: "If yes, name and date", type: "short_answer", required: false },
          { order: 8, question: "If no, why not?", type: "short_answer", required: false },
          { order: 9, question: "Did you engage in a community service activity?", type: "multiple_choice", options: ["Yes", "No"], required: true },
          { order: 10, question: "If yes, provide the activity name, date, and location", type: "short_answer", required: false },
          { order: 11, question: "If no, why not?", type: "short_answer", required: false }
        ]
      },
      {
        name: "Mentor Relationships (RMHA Only)",
        description: "Mentorship Information",
        questions: [
          { order: 12, question: "Did you meet with your alumni mentor?", type: "multiple_choice", options: ["Yes", "No"], required: true },
          { order: 13, question: "Summarize your discussions", type: "short_answer", required: false },
          { order: 14, question: "If not, why not?", type: "short_answer", required: false },
          { order: 15, question: "Did you meet with your student mentor/mentee?", type: "multiple_choice", options: ["Yes", "No"], required: true },
          { order: 16, question: "Summarize your meetings", type: "short_answer", required: false },
          { order: 17, question: "If not, why not?", type: "short_answer", required: false }
        ]
      },
      {
        name: "Volunteering/Service",
        description: "Volunteer Work Information",
        questions: [
          { order: 18, question: "Any volunteer service?", type: "multiple_choice", options: ["Yes", "No"], required: true },
          { order: 19, question: "If yes, please describe.", type: "short_answer", required: false },
          { order: 20, question: "If no, why not?", type: "short_answer", required: false }
        ]
      },
      {
        name: "Health Care Environment and Community",
        description: "Relation between health care operations and community organizations and policies",
        questions: [
          { order: 21, question: "Public and Population Health Assessment", type: "short_answer" },
          { order: 22, question: "Delivery, Organization, and Financing of Health Services", type: "short_answer" },
          { order: 23, question: "Policy Analysis", type: "short_answer" },
          { order: 24, question: "Legal and Ethical Bases for Health Services", type: "short_answer" }
        ]
      },
      {
        name: "Leadership Skills",
        description: "Motivation and empowerment of organizational resources",
        questions: [
          { order: 25, question: "Ethics, Accountability, and Self-Assessment", type: "short_answer" },
          { order: 26, question: "Organizational Dynamics", type: "short_answer" },
          { order: 27, question: "Problem Solving, Decision Making, and Critical Thinking", type: "short_answer" },
          { order: 28, question: "Team Building and Collaboration", type: "short_answer" }
        ]
      },
      {
        name: "Management Skills",
        description: "Control and organization of health services delivery",
        questions: [
          { order: 29, question: "Strategic Planning", type: "short_answer" },
          { order: 30, question: "Business Planning", type: "short_answer" },
          { order: 31, question: "Communication", type: "short_answer" },
          { order: 32, question: "Financial Management", type: "short_answer" },
          { order: 33, question: "Performance Improvement", type: "short_answer" },
          { order: 34, question: "Project Management", type: "short_answer" }
        ]
      },
      {
        name: "Analytic and Technical Skills",
        description: "Successful accomplishment of tasks in health services delivery",
        questions: [
          { order: 35, question: "Systems Thinking", type: "short_answer" },
          { order: 36, question: "Data Analysis and Information Management", type: "short_answer" },
          { order: 37, question: "Quantitative Methods for Health Services Delivery", type: "short_answer" }
        ]
      }
    ]
  },
  {
    title: "Residential Survey",
    semester: "Fall 2025",
    categories: [
      {
        name: "Health Care Environment and Community",
        description: "Relationship between health care operations and communities",
        questions: [
          { order: 1, question: "Public and Population Health Assessment", type: "short_answer" },
          { order: 2, question: "Delivery, Organization, and Financing of Health Services", type: "short_answer" },
          { order: 3, question: "Policy Analysis", type: "short_answer" },
          { order: 4, question: "Legal and Ethical Bases for Health Services", type: "short_answer" }
        ]
      },
      {
        name: "Leadership Skills",
        description: "Motivation and empowerment of organizational resources",
        questions: [
          { order: 5, question: "Ethics, Accountability, and Self-Assessment", type: "short_answer" },
          { order: 6, question: "Organizational Dynamics", type: "short_answer" },
          { order: 7, question: "Problem Solving, Decision Making, and Critical Thinking", type: "short_answer" },
          { order: 8, question: "Team Building and Collaboration", type: "short_answer" }
        ]
      },
      {
        name: "Management Skills",
        description: "Control and organization of health services delivery",
        questions: [
          { order: 9, question: "Strategic Planning", type: "short_answer" },
          { order: 10, question: "Business Planning", type: "short_answer" },
          { order: 11, question: "Communication", type: "short_answer" },
          { order: 12, question: "Financial Management", type: "short_answer" },
          { order: 13, question: "Performance Improvement", type: "short_answer" },
          { order: 14, question: "Project Management", type: "short_answer" }
        ]
      },
      {
        name: "Analytic and Technical Skills",
        description: "Successful accomplishment of tasks in health services delivery",
        questions: [
          { order: 15, question: "Systems Thinking", type: "short_answer" },
          { order: 16, question: "Data Analysis and Information Management", type: "short_answer" },
          { order: 17, question: "Quantitative Methods for Health Services Delivery", type: "short_answer" }
        ]
      }
    ]
  }
]

surveys = surveys_data.map do |survey_data|
  survey = Survey.create!(title: survey_data[:title], semester: survey_data[:semester])
  puts "   • Survey: #{survey.title}"

  survey_data[:categories].each do |category_data|
    category = Category.create!(name: category_data[:name], description: category_data[:description])
    puts "      ▸ Category: #{category.name}"

    category_data[:questions].each do |question_data|
      question = create_question!(question_data)
      SurveyQuestion.create!(survey: survey, question: question)
      CategoryQuestion.create!(category: category, question: question, display_label: question_data[:question])
      puts "        ↳ Question ##{question.question_order}: #{question.question}"
    end
  end

  survey
end

puts "• Assigning every survey to every student"
Student.includes(:user, :advisor).find_each do |student|
  surveys.each do |survey|
    survey.questions.each do |question|
      StudentQuestion.find_or_create_by!(student_id: student.student_id, question_id: question.id) do |record|
        record.advisor_id = student.advisor&.advisor_id
      end
    end

    notification_title = "Survey ready: #{survey.title}"
    Notification.find_or_create_by!(
      notifiable: student,
      title: notification_title
    ) do |notification|
      notification.message = "#{survey.title} has been assigned to you for #{survey.semester}."
    end
  end

  puts "   • Linked #{surveys.sum { |survey| survey.questions.count }} questions for #{student.user.name}"
end

puts "🎉 Seed data finished!"
