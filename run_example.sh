#!/bin/bash

# Script to run the text generation example
# Usage: ./run_example.sh [your-api-key]

if [ $# -eq 1 ]; then
    # API key provided as argument
    export GEMINI_API_KEY="$1"
    echo "Using API key from command line argument"
elif [ -z "$GEMINI_API_KEY" ]; then
    # No API key set and none provided
    echo "Error: No API key provided."
    echo ""
    echo "Usage:"
    echo "  1. Set environment variable: export GEMINI_API_KEY=\"your-api-key-here\""
    echo "  2. Or run with argument: ./run_example.sh \"your-api-key-here\""
    echo ""
    echo "Get your API key from: https://makersuite.google.com/app/apikey"
    exit 1
else
    echo "Using API key from environment variable"
fi

echo "Running text generation example..."
dart run example/text_generation_example.dart