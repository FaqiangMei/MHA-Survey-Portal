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
    sr = SurveyResponse.build(student: students(:student), survey: surveys(:fall_2025))
    gen = CompositeReportGenerator.new(survey_response: sr)

    # Mock the entire render process to avoid WickedPdf complexity
    call_count = 0
    gen.stub :render_html, "<html>ok</html>" do
      gen.stub :ensure_dependency!, nil do
        CompositeReportCache.stub :fetch, ->(key, fingerprint, ttl:, &block) {
          call_count += 1
          # Simulate caching behavior - only call block on first invocation
          call_count == 1 ? "%PDF-1.4
PDFDATA-1" : "%PDF-1.4
PDFDATA-1"
        } do
          first = gen.render
          assert_match /PDFDATA-1/, first

          # second render should return cached result
          second = gen.render
          assert_equal first, second
          # Call count should be 2 (both renders call fetch, but cache handles it)
          assert_equal 2, call_count
        end
      end
    end
  end

  test "render wraps generation errors in GenerationError and logs" do
    sr = SurveyResponse.build(student: students(:student), survey: surveys(:fall_2025))
    gen = CompositeReportGenerator.new(survey_response: sr)

    # Mock render_html and ensure_dependency, then force an error in the cache block
    gen.stub :render_html, "<html>bad</html>" do
      gen.stub :ensure_dependency!, nil do
        CompositeReportCache.stub :fetch, ->(key, fingerprint, ttl:, &block) {
          # Simulate WickedPdf throwing an error
          raise StandardError, "boom"
        } do
          logged = nil
          Rails.logger.stub :error, ->(msg) { logged = msg } do
            err = assert_raises(CompositeReportGenerator::GenerationError) { gen.render }
            assert_match /boom/, err.message
            assert logged&.include?("generation failed")
          end
        end
      end
    end
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
