#!/usr/bin/env bash
set -euo pipefail

echo "🏗️  Building backend (GraalVM native image)..."
cd ../hello-backend

# Clean and build native Lambda
./gradlew clean buildNativeLambda -Pmicronaut.runtime=lambda_provided

# Verify artifact exists
if [ -f "build/libs/hello-backend-0.1-lambda.zip" ]; then
  echo "✅ Backend build successful: $(du -h build/libs/hello-backend-0.1-lambda.zip | cut -f1)"
else
  echo "❌ Backend build failed: artifact not found"
  exit 1
fi
