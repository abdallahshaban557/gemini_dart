#!/bin/bash

# Script to run tests with options for unit, integration, or all tests

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [API_KEY]"
    echo ""
    echo "Options:"
    echo "  -u, --unit         Run unit tests only (no API key required)"
    echo "  -i, --integration  Run integration tests only (requires API key)"
    echo "  -a, --all          Run all tests (unit + integration, requires API key)"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -u                    # Run unit tests only"
    echo "  $0 -i                    # Run integration tests (uses .env or env var)"
    echo "  $0 -i YOUR_API_KEY       # Run integration tests with provided API key"
    echo "  $0 -a YOUR_API_KEY       # Run all tests with provided API key"
    echo ""
    echo "If no option is provided, defaults to integration tests only."
}

# Parse command line arguments
TEST_TYPE="integration"  # Default to integration tests
API_KEY_ARG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--unit)
            TEST_TYPE="unit"
            shift
            ;;
        -i|--integration)
            TEST_TYPE="integration"
            shift
            ;;
        -a|--all)
            TEST_TYPE="all"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            # Assume it's an API key if it starts with AIza or is long enough
            if [[ $1 =~ ^AIza.* ]] || [[ ${#1} -gt 20 ]]; then
                API_KEY_ARG="$1"
            else
                echo "❌ Unknown option: $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Handle API key setup for integration and all tests
if [[ "$TEST_TYPE" == "integration" || "$TEST_TYPE" == "all" ]]; then
    # Check if .env file exists
    if [ -f .env ]; then
        echo "Loading environment variables from .env file..."
        export $(cat .env | grep -v '^#' | xargs)
    fi
    
    # Use API key from argument if provided
    if [ ! -z "$API_KEY_ARG" ]; then
        echo "Using API key from command line argument..."
        export GEMINI_API_KEY="$API_KEY_ARG"
    fi
    
    # Check if API key is set
    if [ -z "$GEMINI_API_KEY" ]; then
        echo "❌ GEMINI_API_KEY is not set!"
        echo ""
        echo "For integration tests, you need a Gemini API key:"
        echo "1. Go to https://makersuite.google.com/app/apikey"
        echo "2. Create a new API key"
        echo "3. Use one of these methods:"
        echo "   - Create .env file: cp .env.example .env (then edit it)"
        echo "   - Set environment variable: export GEMINI_API_KEY='your-key'"
        echo "   - Pass as argument: $0 -i YOUR_API_KEY"
        exit 1
    fi
fi

# Run the appropriate tests
case $TEST_TYPE in
    "unit")
        echo "🧪 Running unit tests..."
        echo ""
        dart test test/unit/ --reporter=expanded
        ;;
    "integration")
        echo "🚀 Running integration tests with API key: ${GEMINI_API_KEY:0:8}..."
        echo ""
        dart test test/integration/ --reporter=expanded
        ;;
    "all")
        echo "🧪🚀 Running all tests (unit + integration) with API key: ${GEMINI_API_KEY:0:8}..."
        echo ""
        echo "=== Running Unit Tests First ==="
        dart test test/unit/ --reporter=compact
        echo ""
        echo "=== Running Integration Tests ==="
        dart test test/integration/ --reporter=expanded
        ;;
esac