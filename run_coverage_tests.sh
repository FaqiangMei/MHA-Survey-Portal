#!/bin/bash

# Script to run all tests with coverage
# This ensures all services, jobs, helpers, mailers, and controllers are tested together

echo "🧪 Running comprehensive test suite with coverage..."
echo "=================================================="

# Set coverage flag
export COVERAGE=1

# Run all tests together to get cumulative coverage
bin/rails test \
  test/services/composite_report_cache_test.rb \
  test/services/composite_report_generator_test.rb \
  test/services/survey_assignment_notifier_test.rb \
  test/jobs/application_job_test.rb \
  test/jobs/survey_notification_job_test.rb \
  test/helpers/application_helper_test.rb \
  test/mailers/application_mailer_test.rb \
  test/controllers/surveys_controller_test.rb

echo ""
echo "✅ Tests complete! Coverage report generated in coverage/index.html"
echo "💡 Run: python3 -m http.server 8000 --directory coverage"
echo "   Then open: http://localhost:8000"
