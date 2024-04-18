#!/bin/bash

# Script: generateFromOpenApi.sh
# Purpose: This script fetches the OpenAPI schema file from a remote git repository, saves it locally, and then generates TypeScript code from the API schema.
#
# Usage: Set the project config properties and run this script in a bash shell. No arguments are required.
#
# Prerequisites:
# - SSH keys must be set up for the git repository.
# - The 'openapi-typescript-codegen' or '@openapitools/openapi-generator-cli' npm packages should be installed globally or available in the project.
#
# Output: The generated TypeScript code will be saved in the './generated-api' directory.
#
set -e

### Project configuration
TARGET_PROJECT_NAME=cia_backend
TARGET_REPO_URL=git@git.cronn.de:a-team/umweltbundesamt/cia-2/cia-backend.git
TARGET_SCHEMA_PATH=data/test/validation/OpenApiTest_testOpenApiDoc.json

# Setup dirs and paths
GENERATED_API_DIR=./generated-api
SCHEMA_DIR=$GENERATED_API_DIR/schema
LOCAL_SCHEMA_PATH=$SCHEMA_DIR/$TARGET_PROJECT_NAME"_openApi.json"
mkdir -p $SCHEMA_DIR

# Use git archive and tar to fetch the latest version of the OpenAPI schema file via SSH
echo "Fetching schema from project: $TARGET_PROJECT_NAME"
if git archive --remote=$TARGET_REPO_URL HEAD $TARGET_SCHEMA_PATH | tar -x -C $SCHEMA_DIR; then
    echo "Schema fetched successfully"
else
  echo "Failed to fetch schema from project: $TARGET_PROJECT_NAME"
  rmdir --ignore-fail-on-non-empty $SCHEMA_DIR $GENERATED_API_DIR # Tidy empty dirs
  exit 1
fi

# Tidy filename and fetched dirs
mv $SCHEMA_DIR/data/test/validation/OpenApiTest_testOpenApiDoc.json $LOCAL_SCHEMA_PATH
rm -rf $SCHEMA_DIR/data
echo "Schema file saved to: $LOCAL_SCHEMA_PATH"

### Generate TS code from API schema - uncomment the command based on the desired output format
# OPTION 1: API components separated in multiple files:
GENERATE_COMMAND=("npx" "openapi-typescript-codegen" "--input" "$LOCAL_SCHEMA_PATH" "--output" "$GENERATED_API_DIR")
# OPTION 2: API components consolidated in one api.ts file:
#GENERATE_COMMAND=("npx" "@openapitools/openapi-generator-cli" "generate" "-i" "$LOCAL_SCHEMA_PATH" "-g" "typescript-axios" "-o" "$GENERATED_API_DIR")

if "${GENERATE_COMMAND[@]}"; then
  echo "API code generated successfully"
else
  echo "Failed to generate API code"
  exit 1
fi