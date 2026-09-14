#!/bin/bash

export PROJECT_ID="jupyter-last-sheet"
export REGION="asia-south1"

export ARTIFACT_REPO="llmops-docker"
export SERVICE="rahul-chatbot"

export GITHUB_OWNER="rahul8879"
export GITHUB_REPO="llmops-docker-cicd-demo"
export GITHUB_REPOSITORY="$GITHUB_OWNER/$GITHUB_REPO"

export DEPLOY_SA_NAME="github-cd"
# added the repo
export DEPLOY_SA="$DEPLOY_SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

echo "GCP configuration loaded"
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Service: $SERVICE"
echo "GitHub: $GITHUB_REPOSITORY"