# DevOps Project Documentation

## Project Overview

The project is made for the Modern DevOps practices at FMI - Sofia. The pipeline integrates multiple phases of the Software Development Lifecycle (SDLC) with a focus on automation, security, and scalability.

The solution includes the following components:

- Continuous Integration
- Source Control
- Trunk-Based Development
- Building Pipelines
- CI
- Security (Snyk and Trivy)
- Docker
- Kubernetes

This approach adheres to the E-shaped model, showcasing broad implementation across multiple domains with deep dives into specific areas such as SAST and Rolling Deployments in Kubernetes.

---

## High-Level Solution Design

### Workflow Summary

1. _Create Feature Branch_: Implement changes in isolation.
2. _Pipeline Workflow_:
    - _Unit Testing_
    - _Linter and Style Checks_
    - _Static Application Security Testing (SAST)_
    - _Build Docker Image_
    - _Vulnerability Scanning_ (Snyk/Trivy)
3. _Push to Central Repository_: Merge changes after review.
4. _Rolling Deploy to Kubernetes_: Deploy the application in a scalable, zero-downtime manner.

---

## Low-Level Solution Design

### 1. _Source Control_

- _Tool_: Git
- _Workflow_: Git repository hosted on a platform such as GitHub.
- _Integration_: Git hooks trigger the pipeline upon commit or pull request.

### 2. _Branching Strategies_

- _Methodology_: Trunk-Based Development
- _Process_:
  - Developers create short-lived feature branches from the trunk (develop branch).
  - Frequent merges ensure minimal merge conflicts and updated develop branch.

### 3. _Building Pipelines_

- _Tool_: GitHub Actions
- _Stages_:
  1. _Source_: Fetch the latest code from the repository.
  2. _Build_: Compile the code and package it as a Docker image.
  3. _Test_: Run automated tests.
  4. _Security Scans_: Integrate tools like Snyk and Trivy.
  5. _Deploy_: Deploy to Kubernetes clusters.

### 4. _Continuous Integration (CI)_

- _Features_:
  - Automated build and test on every commit.
  - Integration with testing frameworks (Swift Testing).
  - Notifications for failed builds (Email).

### 5. _Security_

#### a. _Static Application Security Testing (SAST)_

- _Tool_: Snyk
- _Process_:
  - Analyze codebase for vulnerabilities during the build stage.
  - Break builds for critical vulnerabilities.

#### b. _Container Security_

- _Tool_: Trivy
- _Process_:
  - Scan Docker images for known vulnerabilities.
  - Generate detailed reports and prioritize fixes.

### 6. _Docker_

- _Role_:
  - Package the application into lightweight, portable containers.
  - Use a multi-stage Dockerfile for optimized image sizes.
- _Integration_:
  - Build Docker images in the CI pipeline.
  - Store images in a container registry (Docker Hub).

### 7. _Kubernetes_

- _Components_:
  - _Deployment_: YAML definitions for rolling updates and scaling.
  - _Service_: Expose the application for internal and external access.
  - _ConfigMaps and Secrets_: Manage configuration and sensitive data.
- _Tool_: kubectl for managing deployments.

---

## GitHub Actions (_Deep dive_)

GitHub Actions is a feature integrated into GitHub that allows developers to automate, customize, and execute software development workflows directly in their repositories. It is a versatile tool designed for continuous integration (CI) and continuous deployment (CD), among other use cases.

### Description

GitHub Actions is a CI/CD service that uses YAML configuration files to define workflows. These workflows automate processes like testing, building, and deploying applications.

Key Benefits:

- Integration with GitHub: Native support for GitHub repositories ensures seamless collaboration and automation.
- Ease of Use: Prebuilt actions and straightforward YAML syntax simplify workflow creation.
- Customizability: Custom actions allow developers to tailor workflows to unique project requirements.

### Elements

- _Workflow_: A workflow is an automated process defined in a repository and triggered by specific events. It is represented by a YAML file located in the `.github/workflows` directory.

Example:

```yaml
name: CI Workflow
on:
  push:
    branches:
      - main
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: "Setup Swift"
        uses: SwiftyLab/setup-swift@latest
        with:
          swift-version: "5.10"
      - name: Run tests
        run: swift test
```

- _Events_: Events are triggers that start workflows. Common events include `push`, `pull_request`, `schedule`, `workflow_dispatch`
- _Jobs_: Jobs are tasks executed as part of a workflow. Each job runs in an isolated virtual machine or container and can have dependencies on other jobs.
- _Steps_: Steps are individual tasks within a job. They can include running shell commands or using prebuilt actions.
- _Actions_: Actions are reusable components in workflows. They can be written in JavaScript, Docker, or YAML, and are stored in the GitHub Marketplace or repositories.

### Advanced features

- _Matrix builds_: Matrix builds allow jobs to run with multiple configurations, such as different operating systems or programming language versions.

Example:

```yaml
jobs:
  build:
    strategy:
      matrix:
        os: [macOS-latest, ubuntu-latest, windows-latest]
    runs-on: ${{ matrix.os }}
    steps:
    - name: "Checkout repository"
      uses: actions/checkout@v4
    - name: "Setup Swift"
      uses: SwiftyLab/setup-swift@latest
      with:
        swift-version: "5.10"
    - name: "Run Unit Tests"
      run: swift test
```

- _Secrets and Environment Variables_: GitHub Secrets is a storage for sensitive data, such as API keys. These values can be accessed securely in workflows. Environment variables are other values that are used as configuration without the need to commit any changes to the workflow.

Example:

```yaml
jobs:
  build_image:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs:
      - lint
      - static_code_analysis
      - unit_tests
    steps:
    - name: "Checkout repository"
      uses: actions/checkout@v4
    - name: "Build Docker Image"
      run: docker build -t ghcr.io/${{ secrets.DOCKER_USERNAME }}/culinary-chronicles-backend:${{ github.sha }} CulinaryChroniclesBackend
    - name: "Login to GitHub Container Registry"
      run: docker login ghcr.io -u ${{ secrets.DOCKER_USERNAME }} -p ${{ secrets.DOCKER_PASSWORD }}
    - name: "Push Docker Image"
      run: docker push ghcr.io/${{ secrets.DOCKER_USERNAME }}/culinary-chronicles-backend:${{ github.sha }}
    - name: "Logout from GitHub Container Registry"
      run: docker logout
```

- _Reusable Workflows_: Workflows can be reused across multiple repositories or workflows.

Example:

`.github/workflows/deploy.yml` (reusable workflow):

```yaml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to ${{ inputs.environment }}
        run: ./deploy.sh ${{ inputs.environment }}
```

Calling workflow:

```yaml
jobs:
  call-deploy:
    uses: ./.github/workflows/deploy.yml
    with:
      environment: production
```

---

## Brnching strategies (_Deep dive_)

A branching strategy defines the structure and workflow for creating, managing, and merging branches in a version control system, such as Git. It ensures consistency, reduces conflicts, and aligns development practices with project goals.

### Common Branching Strategies

- _Git Flow_

  Git Flow is a popular strategy for projects with a structured release process. It introduces multiple long-lived branches to separate development and production.
  - Branches:
    - `main`: Stable production code.
    - `develop`: Ongoing development for the next release.
    - `feature/*`: Temporary branches for new features.
    - `release/*`: Prepares a release for deployment.
    - `hotfix/*`: Urgent fixes to production.
  - Workflow:
    - Create a `feature/*` branch from `develop`.
    - Merge completed features into `develop`.
    - Create a `release/*` branch for testing.
    - Merge `release/*` into `main` for deployment.
    - Address urgent fixes with `hotfix/*` branches.
  - Benefits:
    - Clear separation of work stages.
    - Suitable for complex projects with predictable releases.
  - Challenges:
    - Overhead in managing multiple branches.
    - Slower feedback loops.

- _GitHub Flow_

  GitHub Flow is a simplified strategy focused on lightweight branching and continuous delivery.
  - Workflow:
    - Create a feature branch from `main`.
    - Push changes to the feature branch.
    - Open a pull request (PR) for code review.
    - Merge the PR into `main` after approval and testing.
    - Deploy from `main`.

  - Benefits:
    - Simple and intuitive.
    - Suitable for smaller teams and projects.
    - Encourages frequent deployments.
  - Challenges:
    - Limited guidance for complex workflows.
    - Relies on robust testing in the `main` branch.

- _Release Branching_

  Release branching focuses on maintaining stability in production while allowing ongoing development.
  - Branches:
    - `main`: Production-ready code.
    - `release/*`: Prepares new releases with rigorous testing.
    - `feature/*`: Develop new features.
  - Workflow:
    - Merge features into `main` or `release/*` branches.
    - Freeze `release/*` branches for testing and bug fixes.
    - Deploy `release/*` branches to production.
  - Benefits:
    - Stability in production.
    - Clear separation of release management.
  - Challenges:
    - Additional overhead in managing release branches.

- _Trunk-Based Development_

  Trunk-based development (TBD) emphasizes frequent integration of small changes into a single branch, typically referred to as the "trunk" or "main." This strategy minimizes long-lived feature branches and encourages continuous collaboration.
  - Key Practices:
    - Developers commit directly to the trunk or short-lived feature branches.
    - Feature branches are kept short-lived.
    - Continuous integration (CI) ensures frequent builds and tests.
    - Feature toggles (flags) control incomplete features in production.
  - Benefits:
    - Reduces merge conflicts.
    - Encourages faster feedback cycles.
    - Simplifies CI/CD pipelines.
    - Supports continuous delivery.
  - Challenges:
    - Requires strong discipline to maintain code quality.
    - Dependent on robust automated testing.

---

## Future Improvements

1. _Enhanced Monitoring_: Integrate tools like Prometheus and Grafana for performance metrics.
2. _Test Automation_: Expand test coverage to include end-to-end and load testing.
3. _GitOps_: Automate Kubernetes deployments using ArgoCD or Flux.
