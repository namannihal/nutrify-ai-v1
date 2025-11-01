
# 🧠 Nutrify-AI — Engineering Guide  
### (LangChain + LangSmith + FastAPI backend | React + shadcn/ui frontend)

---

## 1. Engineering Summary

**Nutrify-AI** is an agentic, adaptive fitness platform powered by open-source LangChain + LangSmith and built for scalability and privacy from day one.

The architecture enables:
- Modular **AI agent orchestration** for fitness, nutrition, and behavioral feedback.
- **High observability** using LangSmith, Prometheus, and OpenTelemetry.
- **PWA scalability** using React + shadcn/ui, with backend API federation via FastAPI.
- **Event-driven microservices** for long-running AI tasks, such as plan generation and adaptation.

### Key Architectural Goals:
| Goal | Description |
|------|--------------|
| **Scalable** | Each service (auth, AI, data, notifications) runs independently in containers; supports autoscaling. |
| **Private by Design** | Sensitive biometric data processed on-device or anonymized. |
| **Composable Agents** | Each domain (nutrition, workout, motivation) has an autonomous LangChain agent supervised by an orchestrator. |
| **Observable** | LangSmith traces + metrics + feedback loops for all agent actions. |
| **Low Latency** | Async-first FastAPI backend + Redis cache + optimized CDN edge delivery. |

---

## 2. System Architecture Overview

### 2.1 High-Level Architecture

```
Frontend (React + shadcn/ui + PWA)
        ↓
FastAPI Gateway (Auth, Routing, Rate Limiting)
        ↓
Microservices (modular APIs)
    ├── Auth Service
    ├── User Profile Service
    ├── AI Orchestrator Service (LangChain Agents)
    ├── Plan Engine (Fitness/Nutrition generation)
    ├── Integration Service (Wearables, OCR, APIs)
    ├── Notification Service
        ↓
Data Layer (PostgreSQL, Redis, S3, Vector DB)
        ↓
LangSmith (Observability + Tracing)
```

### 2.2 Core Components

| Component | Tech Stack | Description |
|------------|-------------|--------------|
| **Frontend** | React, TypeScript, shadcn/ui, Tailwind | PWA with offline sync, push notifications, and clean UI primitives |
| **Backend API** | FastAPI (Python 3.11+), Uvicorn, Pydantic | Async REST APIs, JWT/OAuth2 auth, OpenAPI docs |
| **AI Layer** | LangChain + LangSmith | Multi-agent orchestration, plan adaptation, feedback logging |
| **Data Layer** | PostgreSQL, Redis, FAISS | Structured + vector data for personalization and caching |
| **Storage** | AWS S3 | User images, documents, and plan exports |
| **Infra** | Docker, Kubernetes, Terraform | Cloud-native, horizontally scalable setup |
| **Monitoring** | Prometheus, Grafana, OpenTelemetry | Metrics, logs, traces across backend and AI agents |

---

## 3. Agentic Architecture (LangChain + LangSmith)

### 3.1 Core Agents
| Agent | Function | Models |
|--------|-----------|--------|
| **NutritionAgent** | Creates and adapts meal plans, tracks macros | GPT-5, domain fine-tuned models |
| **FitnessAgent** | Generates adaptive workouts | GPT-5, local exercise embeddings |
| **MotivationAgent** | Behavioral reinforcement, notifications | GPT-5-turbo or distilled models |
| **OrchestratorAgent** | Supervises all agents, validates safety | LangGraph / LangSmith traces |

### 3.2 Data Flow
1. User submits onboarding data → stored securely in PostgreSQL.
2. AI Orchestrator calls NutritionAgent + FitnessAgent via LangChain pipelines.
3. Agents query FAISS embeddings for personalization.
4. Plans are generated, versioned, and logged in LangSmith.
5. FastAPI exposes REST endpoints to the frontend.

---

## 4. Frontend Engineering (React + shadcn/ui + PWA)

### 4.1 Stack
- React 18 + TypeScript
- Vite or Next.js (App Router)
- TailwindCSS + shadcn/ui
- React Query (TanStack Query)
- Workbox for PWA and caching

### 4.2 Directory Layout
```
/src
 ├── components/ (shadcn primitives)
 ├── pages/ (Next.js routes)
 ├── hooks/
 ├── services/ (API clients)
 ├── state/ (Zustand or Redux Toolkit)
 ├── utils/
 └── workers/ (background sync)
```

### 4.3 PWA Capabilities
- Service Worker caching
- Push Notifications (Firebase or OneSignal)
- Offline Mode for meal/workout logging
- Background Sync for AI plan updates

---

## 5. Backend Engineering (FastAPI + LangChain)

### 5.1 Directory Layout
```
/backend
 ├── main.py
 ├── api/
 │   ├── routes/
 │   ├── schemas/
 │   ├── services/
 ├── core/
 │   ├── config.py
 │   ├── security.py
 ├── agents/
 │   ├── orchestrator_agent.py
 │   ├── nutrition_agent.py
 │   ├── fitness_agent.py
 │   └── motivation_agent.py
 ├── db/
 │   ├── models.py
 │   ├── session.py
 ├── utils/
 │   ├── langsmith_logging.py
 │   ├── data_validation.py
 └── tests/
```

### 5.2 Services
- **Auth Service:** OAuth2/JWT, refresh tokens, optional Auth0.
- **AI Orchestrator Service:** Connects LangChain pipelines to FastAPI routes.
- **Plan Engine:** Weekly auto-regeneration via Celery worker.
- **Integrations:** Apple Health, Fitbit, Google Fit APIs.

---

## 6. Deployment & Scaling

| Layer | Tech | Scaling Method |
|-------|------|----------------|
| API | FastAPI + Uvicorn | Horizontal scaling via K8s HPA |
| Workers | Celery + Redis | Auto-scale via queue depth |
| Frontend | React PWA on Vercel/CloudFront | CDN edge caching |
| DB | PostgreSQL + read replicas | Vertical & horizontal read scaling |
| Vector Store | FAISS/Milvus | Sharding & async indexing |

### Observability
- **LangSmith traces** for all AI calls.
- **OpenTelemetry** integrated with FastAPI.
- **Grafana dashboards** for latency and throughput.

---

## 7. CI/CD Pipeline

1. **GitHub Actions** → linting, pytest, build images.
2. **Docker Build** → multi-stage images, push to ECR/GCR.
3. **ArgoCD** → GitOps-style continuous deployment.
4. **Terraform** → Infrastructure provisioning (RDS, EKS, S3, etc.).

---

## 8. Security & Compliance

- JWT + OAuth2 auth with token rotation.
- Data encryption (AES-256 for storage, TLS in transit).
- Federated learning support (future roadmap).
- Audit logs for all AI interactions.
- SOC2/HIPAA-ready logging + retention policies.

---

## 9. Future Extensions

- **Voice coaching** via Whisper or ElevenLabs API.
- **Real-time pose detection** for form correction.
- **Closed-loop feedback model** retraining using LangSmith annotations.
- **Multi-agent scheduling** using LangGraph.

---

### 🔒 Core Principle:
> “Build for privacy, scale for personalization, optimize for behavior change.”
