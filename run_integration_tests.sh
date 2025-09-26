#!/bin/bash

# Script to run integration tests with API key from .env file

# Check if .env file exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "No .env file found. You can:"
    echo "1. Copy .env.example to .env and add your API key"
    echo "2. Set GEMINI_API_KEY environment variable manually"
    echo "3. Pass API key as argument: ./run_integration_tests.sh YOUR_API_KEY"
    
    if [ ! -z "$1" ]; then
        echo "Using API key from command line argument..."
        export GEMINI_API_KEY="$1"
    fi
fi

# Check if API key is set
if [ -z "$GEMINI_API_KEY" ]; then
    echo "❌ GEMINI_API_KEY is not set!"
    echo ""
    echo "To get a Gemini API key:"
    echo "1. Go to https://makersuite.google.com/app/apikey"
    echo "2. Create a new API key"
    echo "3. Set it as an environment variable or create a .env file"
    exit 1
fi

echo "🚀 Running integration tests with API key: ${GEMINI_API_KEY:0:8}..."
echo ""

# Run the integration tests
dart test test/integration/ --reporter=expanded