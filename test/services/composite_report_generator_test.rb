require "test_helper"

class CompositeReportGeneratorTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    CompositeReportCache.reset!
  end

  test "render raises MissingDependency when WickedPdf is not defined" do
    # remove WickedPdf if present
    had = Object.const_defined?(:WickedPdf)
    old = WickedPdf if had
    Object.send(:remove_const, :WickedPdf) if had

    sr = SurveyResponse.build(student: students(:student), survey: surveys(:fall_2025))
    gen = CompositeReportGenerator.new(survey_response: sr)

    assert_raises(CompositeReportGenerator::MissingDependency) do
      gen.render
    end
  ensure
    Object.const_set(:WickedPdf, old) if had
  end

  test "render generates pdf via WickedPdf and caches result" do
    # define a fake WickedPdf that increments a global counter
    had = Object.const_defined?(:WickedPdf)
    old = WickedPdf if had
    $wicked_calls = 0

    fake_instance = Object.new
    def fake_instance.pdf_from_string(_html, _options = {})
      $wicked_calls += 1
      # Return a string that looks like PDF data
      "%PDF-1.4\nPDFDATA-#{$wicked_calls}"
    end

    fake_class = Class.new do
      define_method(:initialize) { |*args| }
      define_singleton_method(:new) { fake_instance }
    end

    Object.send(:remove_const, :WickedPdf) if had
    Object.const_set(:WickedPdf, fake_class)

    sr = SurveyResponse.build(student: students(:student), survey: surveys(:fall_2025))
    gen = CompositeReportGenerator.new(survey_response: sr)

    # Stub the render_html method instead of ApplicationController.render
    gen.stub :render_html, "<html>ok</html>" do
      first = gen.render
      assert_match /PDFDATA-1/, first

      # second render should come from cache and not increment WickedPdf calls
      second = gen.render
      assert_equal first, second
      assert_equal 1, $wicked_calls
    end
  ensure
    Object.send(:remove_const, :WickedPdf) if Object.const_defined?(:WickedPdf)
    Object.const_set(:WickedPdf, old) if had
  end

  test "render wraps generation errors in GenerationError and logs" do
    had = Object.const_defined?(:WickedPdf)
    old = WickedPdf if had

    fake_instance = Object.new
    def fake_instance.pdf_from_string(_, _options = {})
      raise StandardError, "boom"
    end

    fake_class = Class.new do
      define_method(:initialize) { |*args| }
      define_singleton_method(:new) { fake_instance }
    end

    Object.send(:remove_const, :WickedPdf) if had
    Object.const_set(:WickedPdf, fake_class)

    sr = SurveyResponse.build(student: students(:student), survey: surveys(:fall_2025))
    gen = CompositeReportGenerator.new(survey_response: sr)

    # Stub the render_html method
    gen.stub :render_html, "<html>bad</html>" do
      logged = nil
      Rails.logger.stub :error, ->(msg) { logged = msg } do
        err = assert_raises(CompositeReportGenerator::GenerationError) { gen.render }
        assert_match /boom/, err.message
        assert logged&.include?("generation failed")
      end
    end
  ensure
    Object.send(:remove_const, :WickedPdf) if Object.const_defined?(:WickedPdf)
    Object.const_set(:WickedPdf, old) if had
  end

  test "cache_fingerprint changes when feedback is updated" do
    # create feedback before building generator so it's included in the fingerprint
    fb = Feedback.create!(student: students(:student), advisor: advisors(:advisor), category: categories(:clinical_skills), survey: surveys(:fall_2025), average_score: 4.0, comments: "ok")
    sr = SurveyResponse.build(student: students(:student), survey: surveys(:fall_2025))
    gen = CompositeReportGenerator.new(survey_response: sr)

    fp1 = gen.cache_fingerprint
    travel 1.second do
      fb.touch
    end
    # clear memoized feedback records so fingerprint recomputes
    gen.instance_variable_set(:@feedback_records, nil)
    fp2 = gen.cache_fingerprint

    assert_not_equal fp1, fp2
    assert_match /^[0-9a-f]{64}$/, fp2
  end

  test "render re-raises MissingDependency without wrapping" do
    had = Object.const_defined?(:WickedPdf)
    old = WickedPdf if had
    Object.send(:remove_const, :WickedPdf) if had

    sr = SurveyResponse.build(student: students(:student), survey: surveys(:fall_2025))
    gen = CompositeReportGenerator.new(survey_response: sr)

    logged = nil
    Rails.logger.stub :error, ->(msg) { logged = msg } do
      err = assert_raises(CompositeReportGenerator::MissingDependency) { gen.render }
      assert_nil logged, "MissingDependency should not log an error"
    end
  ensure
    Object.const_set(:WickedPdf, old) if had
  end

  test "feedback_scope returns all feedback when advisor is nil" do
    sr = SurveyResponse.build(student: students(:student), survey: surveys(:fall_2025))
    gen = CompositeReportGenerator.new(survey_response: sr)

    # stub advisor method to return nil to exercise the else branch at line 142
    gen.stub :advisor, nil do
      scope = gen.send(:feedback_scope)
      assert_not_nil scope
         # when advisor is nil, feedback_scope should return base scope without advisor filter
    end
  end

  test "feedback_summary returns nil average_score when no scored entries" do
    # Delete any existing feedback for this student/survey to ensure clean state
    Feedback.where(student: students(:student), survey: surveys(:fall_2025)).destroy_all

    # create feedback without average_score
    Feedback.create!(student: students(:student), advisor: advisors(:advisor), category: categories(:clinical_skills), survey: surveys(:fall_2025), average_score: nil, comments: "no score")
    sr = SurveyResponse.build(student: students(:student), survey: surveys(:fall_2025))
    gen = CompositeReportGenerator.new(survey_response: sr)

    summary = gen.send(:feedback_summary)
    assert_equal 1, summary[:total_entries]
    assert_equal 0, summary[:scored_entries]
    assert_nil summary[:average_score]
  end

  test "feedbacks_by_category sorts entries by timestamp" do
    # Delete any existing feedback for this student/survey/category to ensure clean state
    Feedback.where(student: students(:student), survey: surveys(:fall_2025), category: categories(:clinical_skills)).destroy_all

    # create multiple feedbacks for the same category at different times
    travel_to Time.zone.parse("2025-01-01 12:00:00") do
      Feedback.create!(student: students(:student), advisor: advisors(:advisor), category: categories(:clinical_skills), survey: surveys(:fall_2025), average_score: 3.0, comments: "older")
    end

    travel_to Time.zone.parse("2025-01-02 12:00:00") do
      Feedback.create!(student: students(:student), advisor: advisors(:advisor), category: categories(:clinical_skills), survey: surveys(:fall_2025), average_score: 4.0, comments: "newer")
    end

    sr = SurveyResponse.build(student: students(:student), survey: surveys(:fall_2025))
    gen = CompositeReportGenerator.new(survey_response: sr)

    by_cat = gen.send(:feedbacks_by_category)
    assert by_cat.key?(categories(:clinical_skills).id)
    feedbacks = by_cat[categories(:clinical_skills).id]
    # should return sorted array with most recent first
    assert_equal 2, feedbacks.size
    assert_equal "newer", feedbacks.first.comments
    assert_equal "older", feedbacks.last.comments
  end
end
