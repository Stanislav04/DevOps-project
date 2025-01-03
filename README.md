# DevOps Project Documentation

## Project Overview
The project is made for the Modern DevOps practices at FMI - Sofia. The pipeline integrates multiple phases of the Software Development Lifecycle (SDLC) with a focus on automation, security, and scalability. 

The solution includes the following components:
 * Continuous Integration  
 * Source Control
 * Trunk-Based Development 
 * Building Pipelines 
 * CI
 * Security (Snyk and Trivy) 
 * Docker
 * Kubernetes. 

This approach adheres to the E-shaped model, showcasing broad implementation across multiple domains with deep dives into specific areas such as SAST and Rolling Deployments in Kubernetes.

---

## High-Level Solution Design

### Workflow Summary
1. *Create Feature Branch*: Implement changes in isolation.
2. *Pipeline Workflow*:
    - *Unit Testing*
    - *Linter and Style Checks*
    - *Static Application Security Testing (SAST)*
    - *Build Docker Image*
    - *Vulnerability Scanning* (Snyk/Trivy)
3. *Push to Central Repository*: Merge changes after review.
4. *Rolling Deploy to Kubernetes*: Deploy the application in a scalable, zero-downtime manner.

---

## Low-Level Solution Design

### 1. *Source Control*
- *Tool*: Git
- *Workflow*: Git repository hosted on a platform such as GitHub.
- *Integration*: Git hooks trigger the pipeline upon commit or pull request.

### 2. *Branching Strategies*
- *Methodology*: Trunk-Based Development
- *Process*:
  - Developers create short-lived feature branches from the trunk (develop branch).
  - Frequent merges ensure minimal merge conflicts and updated develop branch.

### 3. *Building Pipelines*
- *Tool*: GitHub Actions
- *Stages*:
  1. *Source*: Fetch the latest code from the repository.
  2. *Build*: Compile the code and package it as a Docker image.
  3. *Test*: Run automated tests.
  4. *Security Scans*: Integrate tools like Snyk and Trivy.
  5. *Deploy*: Deploy to Kubernetes clusters.

### 4. *Continuous Integration (CI)*
- *Features*:
  - Automated build and test on every commit.
  - Integration with testing frameworks (Swift Testing).
  - Notifications for failed builds (Email).

### 5. *Security*
#### a. *Static Application Security Testing (SAST)*
- *Tool*: Snyk
- *Process*:
  - Analyze codebase for vulnerabilities during the build stage.
  - Break builds for critical vulnerabilities.
#### b. *Container Security*
- *Tool*: Trivy
- *Process*:
  - Scan Docker images for known vulnerabilities.
  - Generate detailed reports and prioritize fixes.

### 6. *Docker*
- *Role*:
  - Package the application into lightweight, portable containers.
  - Use a multi-stage Dockerfile for optimized image sizes.
- *Integration*:
  - Build Docker images in the CI pipeline.
  - Store images in a container registry (Docker Hub).

### 7. *Kubernetes*
- *Components*:
  - *Deployment*: YAML definitions for rolling updates and scaling.
  - *Service*: Expose the application for internal and external access.
  - *ConfigMaps and Secrets*: Manage configuration and sensitive data.
- *Tool*: kubectl for managing deployments.

---

## Deep Dive: SAST

### Static Application Security Testing with Snyk
- *Purpose*: Identify and fix vulnerabilities in the source code.
- *Integration*:
  - Integrated into the CI pipeline.
  - Reports generated in HTML or JSON format.
- *Example*:
  
  snyk auth
  snyk test --severity-threshold=high
  
- *Benefits*:
  - Early detection of security issues.
  - Compliance with industry standards (e.g., OWASP Top 10).

---

## Future Improvements
1. *Enhanced Monitoring*: Integrate tools like Prometheus and Grafana for performance metrics.
2. *Test Automation*: Expand test coverage to include end-to-end and load testing.
3. *GitOps*: Automate Kubernetes deployments using ArgoCD or Flux.

---