#!/bin/bash

# Script to run all tests with coverage using the correct Ruby and database settings

# Set database connection for local PostgreSQL (Docker Compose on port 5433)
export PGPORT=5433
export PGHOST=localhost
export PGUSER=dev_user
export PGPASSWORD=dev_pass

# Enable coverage
export COVERAGE=1

# Run all tests
echo "🧪 Running all tests with coverage..."
echo "=================================================="
bin/rails test "$@"

echo ""
echo "✅ Tests complete! Coverage report generated in coverage/index.html"
echo "💡 To view coverage:"
echo "   python3 -m http.server 8000 --directory coverage"
echo "   Then open: http://localhost:8000"
