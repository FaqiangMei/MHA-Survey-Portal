require "test_helper"

class SurveyAssignmentNotifierTest < ActiveJob::TestCase
  setup do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    @assignment_due_soon = survey_assignments(:residential_assignment)
    @assignment_overdue = survey_assignments(:overdue_assignment)
  end

  test "run_due_date_checks! enqueues due_soon and past_due jobs" do
    reference_time = Time.current

    # Modify an existing fixture assignment to be due soon to exercise due_soon path
    @assignment_due_soon.update!(assigned_at: reference_time - 1.day, due_date: reference_time + 1.day)

    SurveyAssignmentNotifier.run_due_date_checks!(reference_time: reference_time)

    jobs = enqueued_jobs

    due_soon_found = jobs.any? do |j|
      (j[:job] == SurveyNotificationJob || j[:job_class] == "SurveyNotificationJob") &&
        j[:args]&.any? { |a| (a["survey_assignment_id"] || a[:survey_assignment_id]) == @assignment_due_soon.id }
    end

    past_due_found = jobs.any? do |j|
      (j[:job] == SurveyNotificationJob || j[:job_class] == "SurveyNotificationJob") &&
        j[:args]&.any? { |a| (a["survey_assignment_id"] || a[:survey_assignment_id]) == @assignment_overdue.id }
    end

    assert due_soon_found, "expected a due_soon job for assignment #{@assignment_due_soon.id} to be enqueued"
    assert past_due_found, "expected a past_due job for assignment #{@assignment_overdue.id} to be enqueued"
  end

  test "notify_now! delivers notification immediately" do
    assert_difference -> { Notification.count }, 1 do
      SurveyAssignmentNotifier.notify_now!(assignment: @assignment_due_soon, title: "Hello", message: "Please do this")
    end

    notification = Notification.last
    assert_equal @assignment_due_soon.recipient_user, notification.user
    assert_equal "Hello", notification.title
  end
end

