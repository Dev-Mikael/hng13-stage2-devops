# DECISION.md

## 🧠 Thought Process & Design Decisions

As a beginner in DevOps, my main goal for this Stage 2 task was to understand **Blue/Green deployment** and how **Nginx failover mechanisms** work in a real-world setup.  
I approached the task step-by-step, focusing on clarity and stability rather than complexity.

### 1. Containerization and Environment Setup
I used **Docker Compose** to orchestrate all services — Nginx, app_blue, and app_green.  
Each service was defined in the `docker-compose.yml` file and parameterized using environment variables from a `.env` file.  
This helped me understand the importance of **configuration as code** and how environment variables can make deployments portable and flexible.

### 2. Nginx Configuration (Failover Logic)
For routing and failover, I created a templated Nginx configuration file (`nginx.conf.template`) that dynamically points to the active pool (blue or green) using `$ACTIVE_POOL`.  
I used `envsubst` inside an entrypoint script to generate the final Nginx config at runtime before starting the service.

The upstream configuration uses:
- **`max_fails`** and **`fail_timeout`** to detect unhealthy instances quickly.  
- **`backup`** keyword for automatic fallback to the Green instance.  
- **retry policies** to ensure that failed requests are retried on the backup server before returning an error to the client.

This part helped me understand how **Nginx load balancing** and **health-based routing** work internally.

### 3. Handling Health Checks and Failures
Each Node.js container exposes a `/healthz` endpoint for liveness checks and `/chaos/start` for simulating failure.  
During downtime simulation on Blue, Nginx automatically reroutes traffic to Green without client interruptions.  
Testing this behavior using `curl` taught me how **zero-downtime deployments** are achieved in production environments.

### 4. Parameterization and Reusability
I parameterized the Compose setup with:
- `BLUE_IMAGE`, `GREEN_IMAGE`
- `ACTIVE_POOL`
- `RELEASE_ID_BLUE`, `RELEASE_ID_GREEN`

This ensured the grader (or any CI/CD pipeline) could dynamically control which service is active without editing files manually.  
I learned the importance of **.env standardization** and **12-Factor App principles** in deployment automation.

### 5. Documentation and Structure
I added a detailed `README.md` explaining setup instructions, commands, and how to test failover.  
The `DECISION.md` (this file) explains my reasoning and lessons learned, which I now realize is very useful for communication and collaboration in real DevOps teams.

---

## 🧩 Challenges Faced

1. **YAML formatting issues** — I initially got errors about duplicate keys, which taught me to properly indent and structure services in YAML.
2. **Image not found** — I learned to verify image tags on Docker Hub before referencing them.
3. **Nginx “invalid proto” error** — This happened when I mistakenly added a full URL instead of `host:port` inside upstream blocks.
4. **Env substitution** — Understanding how `envsubst` works with shell variables helped me debug config generation issues.

Each of these mistakes helped me improve my debugging skills, understand container networking better, and learn how Nginx expects configurations.

---

## 🧰 Tools & Technologies Used
- **Docker Compose** — service orchestration
- **Nginx** — reverse proxy and failover handling
- **Shell scripting (`entrypoint.sh`)** — dynamic config generation
- **.env files** — configuration parameterization
- **curl** — manual endpoint testing

---

## 🎓 Lessons Learned

1. **Automation beats manual editing.**  
   Using templates and environment variables makes deployments cleaner and more maintainable.

2. **Nginx is more powerful than I thought.**  
   Understanding its upstream, fail_timeout, and backup features deepened my appreciation for how reverse proxies enhance reliability.

3. **Always validate YAML and environment variables.**  
   Small syntax issues can break automation pipelines.

4. **Blue/Green deployment isn’t just theory.**  
   I now see how it enables smooth version transitions and zero-downtime updates in production.

5. **Debugging is part of learning.**  
   Every error message (from “invalid proto” to “manifest unknown”) became a learning opportunity.

---

## 🚀 Future Improvements

- Implement an automatic CI/CD pipeline (e.g., GitHub Actions) to validate health and headers after each deployment.
- Add monitoring and alerting using tools like Prometheus + Grafana.
- Experiment with canary deployments after mastering Blue/Green.
- Deploy the setup to Azure or AWS for cloud-based resilience testing.

---

## 👤 Author
**Name:** Modu Michael  
**Role:** DevOps Intern (HNG Stage 2)  
**Focus:** Beginner-level automation, Nginx, Docker, and failover systems.

---
