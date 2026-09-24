# Blogging App

A minimal Spring Boot blogging application (CRUD posts, login page, REST API, Actuator/Prometheus
metrics) built to plug into the CI/CD pipeline described in `DevOps-Project-EKS-CICD-Guide.md`.

## Structure

```
blogging-app/
├── pom.xml
├── Dockerfile
├── k8s/
│   └── deployment-service.yaml
└── src/main/
    ├── java/com/example/blog/
    │   ├── BlogApplication.java
    │   ├── model/Post.java
    │   ├── repository/PostRepository.java
    │   ├── controller/PostController.java       (web UI)
    │   ├── controller/PostRestController.java    (REST API at /api/posts)
    │   ├── controller/LoginController.java
    │   └── config/SecurityConfig.java
    └── resources/
        ├── application.properties
        └── templates/ (login.html, home.html, add-post.html, edit-post.html)
```

## Run locally

```bash
mvn spring-boot:run
```
Visit `http://localhost:8080` — login with `admin` / `admin123` (demo credentials, see below).

## Build & run with Docker

```bash
docker build -t blogging-app:local .
docker run -p 8080:8080 blogging-app:local
```

## Endpoints

- `/` — web UI (list, create, edit, delete posts) — requires login
- `/login` — login page
- `/api/posts` — REST API (GET/POST/PUT/DELETE), open for pipeline/integration testing
- `/actuator/health` — health check (used by Kubernetes probes)
- `/actuator/prometheus` — Prometheus metrics scrape endpoint

## ⚠️ Before using this beyond a demo/training environment

- **Auth**: `SecurityConfig` uses a single in-memory user (`admin` / `admin123`) for demo
  purposes only. Replace with a real user store, hashed passwords from a database, and don't
  commit real credentials to source control.
- **Database**: uses file-based H2 (`./data/blogdb`) for simplicity. It's mounted on an
  `emptyDir` volume in `k8s/deployment-service.yaml`, meaning data is lost on pod restart and
  isn't shared across the 2 replicas. For anything persistent, swap in Postgres/MySQL (e.g. RDS)
  and update `application.properties` + the `pom.xml` driver dependency.
- **Image tag**: the Deployment references `<dockerhub_user>/blogging-app:latest` — in the
  Jenkinsfile, either `sed`/template this file to the real build tag before `kubectl apply`, or
  use `kubectl set image deployment/blogging-app blogging-app=<image>:<tag> -n webapps`.
