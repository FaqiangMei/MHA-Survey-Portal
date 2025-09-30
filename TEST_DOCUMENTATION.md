# Test Suite Documentation

## Overview

This document provides comprehensive information about the test suite for the Health Professions Rails application. The test suite includes unit tests, integration tests, and system tests to ensure the application works correctly across all components.

## Test Structure

```
test/
├── models/                 # Unit tests for model classes
│   ├── admin_test.rb      # Admin model tests (OAuth, roles, permissions)
│   ├── advisor_test.rb    # Advisor model tests (validations, associations)
│   ├── student_test.rb    # Student model tests (enum, associations)
│   ├── survey_test.rb     # Survey model tests (associations, dependencies)
│   ├── competency_test.rb # Competency model tests (associations, validations)
│   ├── question_test.rb   # Question model tests (types, answer options)
│   ├── survey_response_test.rb     # Survey response tests (enum, scopes)
│   ├── question_response_test.rb   # Question response tests (associations)
│   ├── feedback_test.rb            # Feedback model tests
│   └── evidence_upload_test.rb     # Evidence upload tests
├── controllers/           # Controller action tests
│   ├── surveys_controller_test.rb  # CRUD operations, authorization
│   ├── competencies_controller_test.rb # CRUD operations, validation
│   ├── students_controller_test.rb     # Student management
│   └── ...other controller tests
├── integration/          # Integration tests for user workflows
│   ├── survey_workflow_test.rb        # Complete survey lifecycle
│   └── user_authentication_test.rb    # OAuth and permission flows
├── system/              # End-to-end browser tests
│   ├── surveys_test.rb               # UI interactions for surveys
│   ├── complete_survey_workflow_test.rb # Full workflow testing
│   └── ...other system tests
├── fixtures/            # Test data
│   ├── admins.yml      # Admin test data
│   ├── students.yml    # Student test data
│   ├── surveys.yml     # Survey test data
│   └── ...other fixtures
└── test_helper.rb      # Test configuration and utilities
```

## Test Types

### 1. Model Tests (Unit Tests)

Model tests ensure that your ActiveRecord models work correctly in isolation:

- **Validations**: Test required fields, format validations, uniqueness constraints
- **Associations**: Test relationships between models (belongs_to, has_many, etc.)
- **Enums**: Test enum values and prefix methods
- **Custom Methods**: Test any custom model methods
- **Scopes**: Test model scopes and class methods

Example model test structure:
```ruby
class StudentTest < ActiveSupport::TestCase
  def setup
    @student = students(:one)
  end

  test "should be valid with valid attributes" do
    assert @student.valid?
  end

  test "should validate track enum" do
    assert @student.track_residential?
    @student.track = "executive"
    assert @student.track_executive?
  end
end
```

### 2. Controller Tests (Functional Tests)

Controller tests verify that your controllers handle HTTP requests correctly:

- **HTTP Methods**: Test GET, POST, PATCH, DELETE requests
- **Response Codes**: Verify correct HTTP status codes (200, 302, 404, etc.)
- **Authorization**: Test access control and permissions
- **Parameter Handling**: Test valid and invalid parameter combinations
- **Redirects**: Verify correct redirections after actions

Example controller test structure:
```ruby
class SurveysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:one)
    sign_in @admin
  end

  test "should create survey with valid params" do
    assert_difference("Survey.count") do
      post surveys_url, params: { survey: valid_survey_params }
    end
    assert_redirected_to survey_url(Survey.last)
  end
end
```

### 3. Integration Tests

Integration tests verify that different parts of your application work together:

- **User Workflows**: Test complete user journeys
- **Multi-Model Interactions**: Test interactions across multiple models
- **Authentication Flows**: Test login/logout processes
- **Data Integrity**: Verify data consistency across operations

Example integration test:
```ruby
test "complete survey creation and response workflow" do
  # Create survey -> Add competency -> Add questions -> Create response
  # This tests the entire flow working together
end
```

### 4. System Tests (End-to-End Tests)

System tests use a real browser to test the complete user experience:

- **User Interface**: Test actual web page interactions
- **JavaScript**: Test client-side functionality
- **Form Submissions**: Test complete form workflows
- **Navigation**: Test user navigation patterns
- **Responsive Design**: Test different screen sizes

Example system test:
```ruby
test "admin can create survey through UI" do
  visit surveys_url
  click_on "New survey"
  fill_in "Title", with: "Test Survey"
  click_on "Create Survey"
  assert_text "Survey was successfully created"
end
```

## Test Coverage Areas

### Authentication & Authorization
- Google OAuth integration (Admin model)
- Role-based permissions (admin, advisor, user)
- Session management
- Access control for different user types

### Survey Management
- Survey creation, editing, deletion
- Date validation (assigned vs completion dates)
- Association with competencies and questions
- Status tracking

### Competency & Question Management
- Competency creation and association with surveys
- Question types (text, select, radio, checkbox)
- Answer options handling
- Ordering and organization

### Response Handling
- Survey response status workflow (not_started → in_progress → submitted → approved)
- Question response collection
- Data validation and storage
- Relationship integrity

### Data Relationships
- Survey → Competencies → Questions hierarchy
- Student → Survey Responses relationship
- Advisor oversight and approval workflows
- Cascade delete behavior

## Running Tests

### Basic Test Execution
```bash
# Run all tests
rails test

# Run specific test types
rails test test/models
rails test test/controllers
rails test test/integration
rails test test/system

# Run specific test file
rails test test/models/student_test.rb

# Run specific test method
rails test test/models/student_test.rb:test_should_validate_track_enum
```

### Using the Custom Test Runner
```bash
# Run all tests with the custom runner
ruby run_tests.rb

# Run specific test type
ruby run_tests.rb -t models
ruby run_tests.rb -t controllers
ruby run_tests.rb -t integration
ruby run_tests.rb -t system

# Run with coverage report
ruby run_tests.rb -c

# Run with verbose output
ruby run_tests.rb -v

# Get help
ruby run_tests.rb -h
```

## Test Data (Fixtures)

Fixtures provide consistent test data across all tests:

### Key Fixtures:
- **admins.yml**: Admin users with different roles (admin, advisor, user)
- **students.yml**: Student records with different tracks (residential, executive)
- **surveys.yml**: Survey records for different semesters
- **competencies.yml**: Competencies associated with surveys
- **questions.yml**: Questions of different types with answer options
- **survey_responses.yml**: Survey responses in various states

### Fixture Relationships:
```
surveys(:one) 
  └── competencies(:one, :two)
      └── questions(:one, :two, :three, :four)
          
students(:one, :two, :three)
  └── survey_responses(:one, :two, :three, :four)

admins(:one) [admin role]
admins(:two) [advisor role]
admins(:three) [user role]
```

## Custom Test Helpers

The test suite includes custom helper methods to simplify test writing:

### Model Creation Helpers
```ruby
create_test_admin(email: "test@example.com", role: "admin")
create_test_student(student_id: 12345)
create_complete_test_survey(survey_id: 999)
```

### Custom Assertions
```ruby
assert_enum_values(model, :status, ["active", "inactive"])
assert_association(model, :surveys, :has_many)
assert_required_field(model, :name)
assert_email_validation(model, :email)
```

### Cleanup Utilities
```ruby
cleanup_test_data  # Removes test records to prevent interference
```

## Best Practices

### 1. Test Naming
- Use descriptive test names that explain what is being tested
- Follow the pattern: "should [expected behavior] when [conditions]"
- Group related tests using consistent naming

### 2. Test Structure
- Use `setup` method for common test data preparation
- Keep tests focused on a single behavior
- Use descriptive variable names

### 3. Assertions
- Use the most specific assertion available
- Include meaningful failure messages
- Test both positive and negative cases

### 4. Data Management
- Use fixtures for standard test data
- Create specific test data when fixtures aren't sufficient
- Clean up any test data that might affect other tests

### 5. Coverage
- Aim for high test coverage but focus on critical paths
- Test edge cases and error conditions
- Include both happy path and failure scenarios

## Common Test Patterns

### Testing Enums
```ruby
test "should have valid track values" do
  %w[residential executive].each do |track|
    @student.track = track
    assert @student.valid?
  end
end
```

### Testing Associations
```ruby
test "should destroy dependent records" do
  assert_difference('Competency.count', -1) do
    @survey.destroy
  end
end
```

### Testing Validations
```ruby
test "should require email" do
  @admin.email = nil
  assert_not @admin.valid?
  assert_includes @admin.errors[:email], "can't be blank"
end
```

### Testing Scopes
```ruby
test "should return pending responses" do
  pending = SurveyResponse.pending
  pending.each do |response|
    assert_not_equal "submitted", response.status
  end
end
```

## Continuous Integration

The test suite is designed to work with CI/CD pipelines:

- Tests run in parallel for faster execution
- Coverage reports can be generated automatically
- Test results are clearly reported with exit codes
- Fixtures provide consistent data across environments

## Troubleshooting

### Common Issues:

1. **Fixture Loading Errors**
   - Check that all referenced associations exist in fixtures
   - Verify fixture file syntax (YAML format)

2. **Authentication Errors in Tests**
   - Ensure `include Devise::Test::IntegrationHelpers` is present
   - Use `sign_in` helper correctly in controller/integration tests

3. **Database State Issues**
   - Use `cleanup_test_data` helper to reset test data
   - Check for test pollution between test methods

4. **System Test Failures**
   - Ensure proper Capybara configuration
   - Check for timing issues with `wait_for` methods
   - Verify that the test server is running correctly

## Contributing to Tests

When adding new features:

1. **Add Model Tests** for any new models or model changes
2. **Add Controller Tests** for new endpoints or controller logic
3. **Add Integration Tests** for new user workflows
4. **Add System Tests** for new UI components or user interactions
5. **Update Fixtures** as needed for new test scenarios
6. **Update Documentation** to reflect any new test patterns or helpers

The goal is to maintain comprehensive test coverage that gives confidence in code changes and helps prevent regressions.