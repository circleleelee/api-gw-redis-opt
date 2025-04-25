# api-gw-redis-opt
## Microservice Architecture’s API Gateway Performance Optimization
### Project Introduction
This project aims to evaluate the performance of the Kong API gateway in a microservice architecture by introducing Redis cache and dynamic routing mechanisms.

### Project Architecture and Main Technology Stack
* Kong API Gateway
* Redis (cache layer)
* Flask microservice (as a simulated backend service)
* Lua script (custom cache and dynamic routing logic)
* Docker Compose (for one-click environment building and experimental reproduction)
* k6 performance testing tool (for performance stress testing and experimental evaluation)

### Quick Start
Step1: Clone this repository

       git clone https://github.com/circleleelee/api-gw-redis-opt.git

       cd api-gw-redis-opt

Step2: Start a complete experimental environment (Docker Compose)

       docker compose up -d
       
Check container status

       docker compose ps

Step3: Performance test (k6)

Performance test of optimized version (cache enabled):

       k6 run loadtest/k6.js

Disable Redis cache for baseline control test:

* Edit kong/route.lua and comment out the Redis cache logic.

* Restart Kong:

       docker compose restart kong

* Re-execute the test script.

### Warehouse structure description:

### Repository structure

```text
api-gw-redis-opt/
├── docker-compose.yml        # Compose file that builds/starts the entire stack
├── kong                      # Kong gateway configuration
│   ├── kong.yml              # Declarative routing config
│   ├── kong.conf             # Base Kong configuration (loads route.lua)
│   └── route.lua             # Lua script – Redis cache + dynamic routing
├── services                  # Back-end micro-services
│   └── svc_flask
│       ├── Dockerfile        # Builds the Flask container image
│       └── app.py            # Toy service used in all three instances
└── loadtest                  # Performance-test scripts
    └── k6.js                 # k6 scenario (100 VUs, 30 s)
    └── k6-ec2.js             # Testing on EC2 Platform
```
### Expected experimental results

The table below shows the qualitative difference you should observe when you run the two k6 workloads (baseline vs optimised).  
Replace the placeholders with your actual numbers once you have run the scripts.

| Scenario                                            | Average latency&nbsp;(ms) | 95-th percentile&nbsp;(ms) | Throughput&nbsp;(req/s) |
|-----------------------------------------------------|---------------------------|---------------------------|-------------------------|
| **Baseline** – cache **OFF** (static routing)       | *e.g.* **185**            | *e.g.* **260**            | *e.g.* **610**          |
| **Optimised** – cache **ON** + dynamic routing      | *e.g.* **55**             | *e.g.* **80**             | *e.g.* **1 800**        |
| **Improvement** (Optimised ÷ Baseline)              | −70 %                     | −69 %                     | × 3 ↑                   |

<sup>*Numbers shown are illustrative—run `k6` and fill in the real values from your own test output.*</sup>

### View the number of Redis cache hits

       docker exec -it redis redis-cli info stats | grep hits




