# Deploying a Dockerized FastAPI Application to GCP Cloud Run

## Demo Goal

In this demo, we take a FastAPI application that already works locally in Docker and deploy it manually to Google Cloud Platform.

The purpose of doing the deployment manually first is to understand the cloud components before automating the same process through GitHub Actions.

By the end of this demo, the flow will be:

```text
GitHub Repository
      |
      v
Cloud Shell
      |
      v
Cloud Build
      |
      v
Artifact Registry
      |
      v
Cloud Run
      |
      v
Public FastAPI URL
```

---

# 1. What We Are Learning

This demo introduces four important GCP concepts.

| GCP Component | Purpose |
|---|---|
| GCP Project | Logical boundary for all cloud resources |
| Cloud Build | Builds the Docker image in Google Cloud |
| Artifact Registry | Stores Docker/container images |
| Cloud Run | Runs the Docker container as a managed web service |

A useful comparison is:

```text
Docker Hub            -> Artifact Registry
docker build          -> Cloud Build
docker run            -> Cloud Run
```

---

# 2. Prerequisites

Before starting, make sure you already have:

- A Google Cloud account
- Billing enabled for your GCP project
- A GitHub repository containing your application
- A working `Dockerfile`
- A working FastAPI application
- A `/health` endpoint
- Docker already tested locally

Example repository structure:

```text
llmops-docker-cicd-demo/
|
|-- app/
|   |-- __init__.py
|   `-- main.py
|
|-- test/
|   `-- test_api.py
|
|-- Dockerfile
|-- requirements.txt
|-- README.md
|
`-- .github/
    `-- workflows/
        `-- cicd.yml
```

Example FastAPI health endpoint:

```python
@app.get("/health")
def health():
    return {
        "status": "healthy"
    }
```

---

# 3. Create a GCP Project

Open Google Cloud Console.

Create a new project.

Example:

```text
Project Name:
LLMOps Docker Demo
```

Google will generate a Project ID.

Example:

```text
jupyter-last-sheet
```

Important:

The Project Name is mainly for display.

The **Project ID** is what we use in commands.

---

# 4. Open Google Cloud Shell

From Google Cloud Console, click the Cloud Shell icon:

```text
>_
```

Cloud Shell gives us a browser-based Linux terminal with Google Cloud CLI already installed.

This avoids installing and configuring `gcloud` locally during the first demo.

Check that `gcloud` works:

```bash
gcloud --version
```

---

# 5. Configure Environment Variables

Create variables so that we do not repeatedly type long names.

Replace the project ID with your actual GCP Project ID.

```bash
export PROJECT_ID="YOUR_PROJECT_ID"

export REGION="asia-south1"

export REPO="llmops-docker"

export SERVICE="rahul-chatbot"
```

Example:

```bash
export PROJECT_ID="jupyter-last-sheet"
```

Set the active GCP project:

```bash
gcloud config set project $PROJECT_ID
```

Verify it:

```bash
gcloud config get-value project
```

Expected output:

```text
jupyter-last-sheet
```

---

# 6. Why `asia-south1`?

In this demo we use:

```text
asia-south1
```

This is a Google Cloud region in India.

Keeping Artifact Registry and Cloud Run in the same region is a simple and sensible setup for this demo.

---

# 7. Enable Required Google Cloud APIs

Run:

```bash
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  compute.googleapis.com
```

What each API does:

```text
run.googleapis.com
    -> Cloud Run

artifactregistry.googleapis.com
    -> Artifact Registry

cloudbuild.googleapis.com
    -> Cloud Build

compute.googleapis.com
    -> Supporting Google Cloud infrastructure
```

You normally do this once per project.

---

# 8. Create an Artifact Registry Repository

Artifact Registry is where GCP stores Docker images.

Create a Docker repository:

```bash
gcloud artifacts repositories create $REPO \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker images for LLMOps demo"
```

Verify:

```bash
gcloud artifacts repositories list
```

You should see something similar to:

```text
llmops-docker
```

Conceptually:

```text
Artifact Registry
|
`-- llmops-docker
    |
    |-- rahul-chatbot:v1
    |-- rahul-chatbot:v2
    `-- ...
```

---

# 9. Clone the GitHub Repository in Cloud Shell

Clone the application repository:

```bash
git clone https://github.com/rahul8879/llmops-docker-cicd-demo.git
```

Move into the repository:

```bash
cd llmops-docker-cicd-demo
```

Verify your current location:

```bash
pwd
```

List the files:

```bash
ls
```

You should see:

```text
Dockerfile
requirements.txt
app
test
README.md
```

---

# 10. Very Important: Run Cloud Build from the Project Root

The command:

```bash
gcloud builds submit --tag $IMAGE .
```

contains:

```text
.
```

The dot means:

```text
Use the CURRENT directory as the build context.
```

Therefore, you must run the command from the directory that contains the `Dockerfile`.

Correct:

```text
~/llmops-docker-cicd-demo/
|
|-- Dockerfile
|-- requirements.txt
`-- app/
```

Incorrect:

```text
~/
```

because the home directory does not contain the Dockerfile.

---

# 11. Common Error: Dockerfile Required

You may see:

```text
ERROR: (gcloud.builds.submit) Invalid value for [source]:
Dockerfile required when specifying --tag
```

This normally means you executed:

```bash
gcloud builds submit --tag $IMAGE .
```

from the wrong directory.

For example:

```text
rtiwarirahul123@cloudshell:~$
```

The `~` means you are in your home directory.

Fix:

```bash
cd llmops-docker-cicd-demo
```

Verify:

```bash
ls -l Dockerfile
```

Then run Cloud Build again.

This is an important lesson:

```text
The build context matters.
```

---

# 12. Check the Correct Git Branch

For production deployment, use the branch you want to deploy.

For example:

```bash
git checkout main
git pull
```

Check:

```bash
git branch
```

Expected:

```text
* main
```

---

# 13. Dockerfile for This Demo

For this first demo, the application is listening on port:

```text
7860
```

Example Dockerfile:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "7860"]
```

Later, we can make the container more cloud-portable by reading the `PORT` environment variable.

For now, we keep the existing working container unchanged.

---

# 14. Create the Full Artifact Registry Image Name

Run:

```bash
export IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$SERVICE:v1"
```

Verify:

```bash
echo $IMAGE
```

Example output:

```text
asia-south1-docker.pkg.dev/jupyter-last-sheet/llmops-docker/rahul-chatbot:v1
```

Understand the structure:

```text
asia-south1-docker.pkg.dev
|
|-- GCP Artifact Registry endpoint

jupyter-last-sheet
|
|-- GCP Project ID

llmops-docker
|
|-- Artifact Registry repository

rahul-chatbot
|
|-- Docker image name

v1
|
`-- Image tag
```

This is similar to Docker Hub:

```text
appliedskill/rahul-chatbot:2.0
```

---

# 15. Build the Docker Image Using Cloud Build

Make sure you are inside the repository first:

```bash
pwd
ls
```

Then run:

```bash
gcloud builds submit \
  --tag $IMAGE \
  .
```

Cloud Build now performs:

```text
Application Source Code
        |
        v
Dockerfile
        |
        v
Cloud Build
        |
        v
Docker Image
        |
        v
Artifact Registry
```

You will see Docker build output in Cloud Shell.

The first build may take some time.

---

# 16. What `gcloud builds submit` Actually Does

This command:

```bash
gcloud builds submit --tag $IMAGE .
```

does several things.

### Step 1

Uploads the build context.

### Step 2

Reads the Dockerfile.

### Step 3

Builds the Docker image.

### Step 4

Tags the image.

### Step 5

Pushes it into Artifact Registry.

So you do not need to manually execute:

```bash
docker build
docker tag
docker push
```

for this Cloud Build approach.

---

# 17. Verify the Image in Artifact Registry

Run:

```bash
gcloud artifacts docker images list \
  $REGION-docker.pkg.dev/$PROJECT_ID/$REPO
```

You should see the application image.

Example:

```text
rahul-chatbot
```

At this stage:

```text
Docker image built        -> YES
Docker image stored       -> YES
Application running       -> NO
```

Artifact Registry only stores the image.

We still need Cloud Run to execute it.

---

# 18. Deploy the Image to Cloud Run

Run:

```bash
gcloud run deploy $SERVICE \
  --image $IMAGE \
  --region $REGION \
  --port 7860 \
  --allow-unauthenticated
```

Explanation:

```text
gcloud run deploy $SERVICE
    -> Create/update Cloud Run service

--image $IMAGE
    -> Use our Artifact Registry image

--region $REGION
    -> Deploy in asia-south1

--port 7860
    -> Our FastAPI container listens on port 7860

--allow-unauthenticated
    -> Make the endpoint publicly accessible
```

After deployment, Cloud Run provides a public HTTPS URL.

Example:

```text
https://rahul-chatbot-xxxxxxxxxx.asia-south1.run.app
```

---

# 19. Get the Cloud Run Service URL

Instead of manually copying the URL, retrieve it using:

```bash
export SERVICE_URL=$(gcloud run services describe $SERVICE \
  --region $REGION \
  --format='value(status.url)')
```

Print it:

```bash
echo $SERVICE_URL
```

---

# 20. Test the Health Endpoint

Run:

```bash
curl $SERVICE_URL/health
```

Expected response:

```json
{
  "status": "healthy"
}
```

If this works, your application is successfully running in GCP.

---

# 21. Test FastAPI Swagger UI

Open:

```text
YOUR_CLOUD_RUN_URL/docs
```

Example:

```text
https://rahul-chatbot-xxxxxxxxxx.asia-south1.run.app/docs
```

You should see FastAPI Swagger UI.

Now your local Docker application is available on the public internet.

---

# 22. Complete Manual Deployment Architecture

```text
                  Developer
                      |
                      v
                GitHub Repo
                      |
                      | git clone
                      v
                 Cloud Shell
                      |
                      v
                Cloud Build
                      |
                      | docker build
                      v
          +-------------------------+
          |    Artifact Registry    |
          |                         |
          |   rahul-chatbot:v1      |
          +------------+------------+
                       |
                       | container image
                       v
               +---------------+
               |   Cloud Run   |
               |               |
               | Docker        |
               | FastAPI       |
               +-------+-------+
                       |
                       v
                Public HTTPS URL
                  /         \
                 /           \
            /health          /docs
```

---

# 23. Local Docker vs GCP

Before GCP:

```text
Laptop
  |
  v
docker build
  |
  v
Docker Image
  |
  v
docker run
  |
  v
localhost:7860
```

After GCP:

```text
Source Code
    |
    v
Cloud Build
    |
    v
Artifact Registry
    |
    v
Cloud Run
    |
    v
Public Internet
```

---

# 24. What Is Artifact Registry?

Artifact Registry stores software artifacts.

In our demo it stores:

```text
Docker/container images
```

Think of it as Google's alternative to Docker Hub.

Docker Hub example:

```text
appliedskill/rahul-chatbot:2.0
```

Artifact Registry example:

```text
asia-south1-docker.pkg.dev/
jupyter-last-sheet/
llmops-docker/
rahul-chatbot:v1
```

---

# 25. What Is Cloud Build?

Cloud Build executes build operations inside Google Cloud.

Instead of building locally:

```bash
docker build -t rahul-chatbot:v1 .
```

we executed:

```bash
gcloud builds submit --tag $IMAGE .
```

Benefits:

- Reproducible cloud build environment
- No dependency on developer laptop
- Easy integration with CI/CD
- Direct integration with Artifact Registry

---

# 26. What Is Cloud Run?

Cloud Run is a managed platform for running containers.

We give Cloud Run:

```text
A container image
```

Cloud Run handles much of the underlying infrastructure.

For this demo, we do not need to manually create:

```text
Virtual Machine
Operating System
Docker daemon
Load balancer
Kubernetes cluster
```

We simply deploy the container.

---

# 27. Why We Did Manual Deployment Before CD

The manual process was:

```text
1. Clone source
2. Build image
3. Push image
4. Deploy container
5. Test endpoint
```

This gives us confidence that:

```text
Application works
Dockerfile works
Artifact Registry works
Cloud Run works
Permissions work
```

Now automation becomes much easier to understand.

The next phase is simply:

```text
Replace the human running commands
with GitHub Actions.
```

---

# 28. Current CI Architecture

Our GitHub CI performs:

```text
Pull Request
     |
     v
GitHub Actions
     |
     +-- Install dependencies
     |
     +-- pytest
     |
     +-- docker build
     |
     +-- docker run
     |
     `-- /health check
```

If CI fails:

```text
NO DEPLOYMENT
```

If CI passes:

```text
PR can be merged
```

---

# 29. Final Target CI/CD Architecture

The final automated architecture will be:

```text
Feature Branch
      |
      v
Pull Request
      |
      v
+----------------------+
|          CI          |
|                      |
| pytest               |
| docker build         |
| docker run           |
| health check         |
+----------+-----------+
           |
         PASS
           |
           v
       Merge Main
           |
           v
+----------------------+
|          CD          |
|                      |
| Authenticate to GCP  |
| Build Docker image   |
| Push image           |
| Deploy Cloud Run     |
+----------+-----------+
           |
           v
      Artifact Registry
           |
           v
        Cloud Run
           |
           v
     Production URL
```

---

# 30. Why CI and CD Are Different

## Continuous Integration

CI asks:

```text
Is this code safe to integrate?
```

Typical CI steps:

```text
Unit tests
Code checks
Docker build
Container startup
Health checks
```

## Continuous Deployment

CD asks:

```text
The code passed CI. Where should we deploy it?
```

In our case:

```text
GCP Cloud Run
```

The deployment destination could later be changed to:

```text
Hugging Face
AWS
Azure
Kubernetes
Another Cloud Run service
```

This is why CI can remain mostly platform-independent while CD depends more heavily on the target platform.

---

# 31. Important Production Lesson

A successful Docker build does not mean the application works.

For example:

```text
docker build
    |
    v
SUCCESS
```

but:

```text
docker run
    |
    v
uvicorn executable not found
```

is still possible.

Therefore our CI performs:

```text
docker build
     |
     v
docker run
     |
     v
curl /health
```

This is stronger than only checking whether the image builds.

---

# 32. Common Errors and Fixes

## Error 1: Dockerfile Not Found

Error:

```text
Dockerfile required when specifying --tag
```

Cause:

You are not inside the repository directory.

Check:

```bash
pwd
ls
```

Fix:

```bash
cd llmops-docker-cicd-demo
```

Then verify:

```bash
ls -l Dockerfile
```

---

## Error 2: Image Variable Is Empty

Check:

```bash
echo $IMAGE
```

If nothing is returned:

```bash
export PROJECT_ID="YOUR_PROJECT_ID"
export REGION="asia-south1"
export REPO="llmops-docker"
export SERVICE="rahul-chatbot"

export IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$SERVICE:v1"
```

---

## Error 3: Wrong Project

Check:

```bash
gcloud config get-value project
```

Fix:

```bash
gcloud config set project $PROJECT_ID
```

---

## Error 4: API Not Enabled

Enable required APIs:

```bash
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com
```

---

## Error 5: Cloud Run Cannot Start the Container

Check:

- Correct port
- Uvicorn installed
- FastAPI installed
- Correct `CMD`
- Application starts successfully
- `/health` works locally

Useful Docker test:

```bash
docker build -t rahul-chatbot:test .
```

Then:

```bash
docker run -p 7860:7860 rahul-chatbot:test
```

Test:

```bash
curl http://localhost:7860/health
```

---

# 33. Command Cheat Sheet

## Configure Project

```bash
export PROJECT_ID="YOUR_PROJECT_ID"
export REGION="asia-south1"
export REPO="llmops-docker"
export SERVICE="rahul-chatbot"

gcloud config set project $PROJECT_ID
```

## Enable APIs

```bash
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  compute.googleapis.com
```

## Create Artifact Registry

```bash
gcloud artifacts repositories create $REPO \
  --repository-format=docker \
  --location=$REGION
```

## Clone Application

```bash
git clone https://github.com/rahul8879/llmops-docker-cicd-demo.git

cd llmops-docker-cicd-demo
```

## Define Image

```bash
export IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$SERVICE:v1"
```

## Build and Push Image

```bash
gcloud builds submit \
  --tag $IMAGE \
  .
```

## List Images

```bash
gcloud artifacts docker images list \
  $REGION-docker.pkg.dev/$PROJECT_ID/$REPO
```

## Deploy Cloud Run

```bash
gcloud run deploy $SERVICE \
  --image $IMAGE \
  --region $REGION \
  --port 7860 \
  --allow-unauthenticated
```

## Get Service URL

```bash
export SERVICE_URL=$(gcloud run services describe $SERVICE \
  --region $REGION \
  --format='value(status.url)')
```

## Test Service

```bash
curl $SERVICE_URL/health
```

---

# 34. Recommended Teaching Flow

Teach this demo in the following sequence.

```text
1. Show local FastAPI application

2. Build Docker image locally

3. Run container locally

4. Test /health

5. Explain why we need cloud deployment

6. Introduce:
   - GCP Project
   - Cloud Build
   - Artifact Registry
   - Cloud Run

7. Build image using Cloud Build

8. Show image inside Artifact Registry

9. Deploy to Cloud Run

10. Open public /docs endpoint

11. Explain manual deployment

12. Ask:
    "Do we want to repeat these commands manually
     every time we merge code?"

13. Introduce Continuous Deployment

14. Move the same commands into GitHub Actions
```

That naturally creates the motivation for CI/CD.

---

# 35. Key Takeaway

The most important architecture to remember is:

```text
CODE
 |
 v
BUILD
 |
 v
IMAGE
 |
 v
REGISTRY
 |
 v
RUNTIME
 |
 v
PUBLIC APPLICATION
```

In GCP:

```text
CODE
 |
 v
Cloud Build
 |
 v
Docker Image
 |
 v
Artifact Registry
 |
 v
Cloud Run
 |
 v
FastAPI Application
```

This pattern is not specific to Google Cloud.

The same idea appears across cloud platforms:

```text
Source Code
    |
    v
Build
    |
    v
Container Registry
    |
    v
Container Runtime
```

Understanding this flow makes later topics such as Kubernetes, deployment pipelines, autoscaling, and LLMOps infrastructure much easier.

---

# Next Demo

The next step is:

```text
GitHub Actions
      |
      v
Authenticate with GCP
      |
      v
Build Docker Image
      |
      v
Artifact Registry
      |
      v
Cloud Run Deployment
```

At that point we will have a complete:

```text
Feature Branch
      ->
Pull Request
      ->
CI
      ->
Merge to Main
      ->
CD
      ->
GCP Cloud Run
```

pipeline.
