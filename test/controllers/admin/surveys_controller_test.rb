require "test_helper"

class Admin::SurveysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:admin)
    @advisor_user = users(:advisor)
    @survey = surveys(:fall_2025)
    @advisor = advisors(:advisor)
    @category = categories(:clinical_skills)
    @question = questions(:fall_q1)
    sign_in @admin_user
  end

  test "requires admin role" do
    sign_out @admin_user
    sign_in @advisor_user

    get admin_surveys_path
    assert_redirected_to dashboard_path
  end

  test "creates survey with assignments, tags, and audit log" do
    params = {
      survey: {
        title: "Capstone Survey",
        semester: "Fall 2026",
        track: "Residential",
        question_ids: [ @question.id ],
        assigned_advisor_ids: [ @advisor.advisor_id ],
        tagged_category_ids: [ @category.id ]
      }
    }

    assert_difference ["Survey.count", "SurveyAuditLog.count"] do
      post admin_surveys_path, params: params
    end

    assert_redirected_to admin_surveys_path

    survey = Survey.order(:created_at).last
    assert_equal "Capstone Survey", survey.title
    assert_equal "Residential", survey.track
    assert_includes survey.question_ids, @question.id
    assert_includes survey.assigned_advisor_ids, @advisor.advisor_id
    assert_includes survey.tagged_category_ids, @category.id

    log = SurveyAuditLog.order(:created_at).last
    assert_equal "create", log.action
    assert_equal survey.id, log.survey_id
    assert_equal "Capstone Survey", log.metadata.dig("attributes", "title", "after")
  end

  test "updates survey and records audit trail" do
    survey = surveys(:spring_2025)

    patch admin_survey_path(survey), params: {
      survey: {
        title: "Updated Survey Title",
        semester: survey.semester,
        track: "Hybrid",
        question_ids: [ @question.id ],
        assigned_advisor_ids: [ @advisor.advisor_id ],
        tagged_category_ids: [ @category.id ]
      }
    }

    assert_redirected_to admin_surveys_path

    survey.reload
    assert_equal "Updated Survey Title", survey.title
    assert_equal "Hybrid", survey.track
    assert_equal [ @question.id ], survey.question_ids.sort

    log = SurveyAuditLog.order(:created_at).last
    assert_equal "update", log.action
    assert_equal survey.id, log.survey_id
    assert_equal "Hybrid", log.metadata.dig("attributes", "track", "after")
    assert_equal [ @advisor.display_name ], log.metadata.dig("associations", "advisors", "after")
  end

  test "bulk update applies grouping preferences" do
    survey_ids = [ surveys(:fall_2025).id, surveys(:spring_2025).id ]

    patch bulk_update_admin_surveys_path, params: {
      survey_ids: survey_ids,
      track: "Executive",
      assigned_advisor_ids: [ @advisor.advisor_id ],
      tagged_category_ids: [ @category.id ]
    }

    assert_redirected_to admin_surveys_path

    Survey.where(id: survey_ids).each do |survey|
      assert_equal "Executive", survey.track
      assert_includes survey.assigned_advisor_ids, @advisor.advisor_id
      assert_includes survey.tagged_category_ids, @category.id
    end

    log = SurveyAuditLog.order(:created_at).last
    assert_equal "group_update", log.action
    assert_includes survey_ids, log.survey_id
  end
end
