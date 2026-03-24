# ChoreRobotics Backend Architecture

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 1.0.0 |
| Date | 2026-03-17 |
| Status | Architecture Decision Record (ADR) — Production Blueprint |
| Scope | Complete cloud backend for robot fleet, mobile app, and internal dashboard |

---

## Table of Contents

1. [Technology Decisions](#1-technology-decisions)
2. [Database Architecture](#2-database-architecture)
3. [Message Broker (MQTT)](#3-message-broker)
4. [Service Architecture](#4-service-architecture)
5. [API Design](#5-api-design)
6. [OTA Update System](#6-ota-update-system)
7. [MQTT Topic Structure](#7-mqtt-topic-structure)
8. [Database Schemas](#8-database-schemas)
9. [Infrastructure](#9-infrastructure)
10. [Infrastructure Diagram](#10-infrastructure-diagram)
11. [Security Architecture](#11-security-architecture)
12. [Observability](#12-observability)
13. [Cost Estimates](#13-cost-estimates)
14. [API Endpoint Reference](#14-api-endpoint-reference)
15. [Deployment Strategy](#15-deployment-strategy)
16. [Disaster Recovery](#16-disaster-recovery)

---

## 1. Technology Decisions

### 1.1 Backend Language & Framework

#### Evaluation Matrix

| Criterion (weighted) | Go (net/http + stdlib) | Rust (Axum) | Python (FastAPI) | Node.js (NestJS) | Elixir (Phoenix) |
|---|---|---|---|---|---|
| **Concurrency model** (25%) | Goroutines. Millions of lightweight green threads. Trivial to write concurrent telemetry handlers. | async/await via Tokio. Excellent, but more verbose. Steeper learning curve. | asyncio. Adequate but GIL limits true CPU parallelism. Worker pools needed. | Event loop + libuv. Good for I/O, poor for CPU-bound telemetry aggregation. | BEAM VM + OTP. Best-in-class for massive concurrent connections. Designed for telecom. |
| **MQTT ecosystem** (20%) | Paho-Go, mochi-mqtt (embeddable broker in Go). First-class. | rumqttc. Solid but smaller community. | paho-mqtt, aiomqtt. Mature. | mqtt.js. Very mature, used in AWS IoT. | emqtt, tortoise. Adequate. |
| **Telemetry throughput** (15%) | Excellent. 100K+ msg/sec on single node. Benchmarked. | Best raw throughput. 150K+ msg/sec. Memory-safe without GC pauses. | Adequate with uvloop, but 30-50K msg/sec ceiling per process. | 50-80K msg/sec with clustering. GC pauses under high load. | Excellent. BEAM handles 100K+ concurrent connections natively. |
| **Hiring & team scaling** (15%) | Large talent pool. Readable by any backend developer. 1-2 week ramp-up. | Small talent pool. 3-6 month ramp-up for Rust-proficient developers. | Largest talent pool. Immediate productivity. | Large pool. Fast onboarding. | Very small talent pool. Niche community. |
| **Binary deployment** (10%) | Single static binary. 10-20MB. No runtime dependency. Trivial Docker images. | Single static binary. 5-15MB. Even smaller. | Requires Python runtime, virtualenv, pip. Heavier containers. | Requires Node runtime, node_modules. 100MB+ containers. | Requires BEAM VM. Specialized deployment. |
| **Safety-critical patterns** (10%) | Strong typing. No null panics with proper error handling. Context cancellation for timeouts. | Ownership model prevents data races at compile time. Best safety guarantees. | Type hints optional. Runtime errors in production. Not ideal for safety-critical. | TypeScript helps but runtime is still JS. Not ideal for safety-critical paths. | "Let it crash" philosophy with supervisors. Excellent fault isolation. |
| **Protobuf/gRPC support** (5%) | First-class. Google's own implementation. | tonic. Excellent. | grpcio. Works. | @grpc/grpc-js. Works. | grpc-elixir. Adequate. |

#### Decision: Go 1.24

**Primary reasons:**

1. **Concurrency model matches the problem.** Each robot is a long-lived concurrent connection (MQTT subscription, telemetry ingestion, command dispatch). Go's goroutine-per-connection model handles 1,000 robots on a single node with negligible overhead. No async coloring, no callback hell, no futures chains.

2. **Single binary deployment.** The robot edge agent (a thin cloud-side proxy per robot) compiles to a 15MB static binary. No runtime, no dependency manager, no virtualenv. Docker images are 20MB scratch-based. This matters for cost (smaller containers = faster scaling) and reliability (fewer moving parts).

3. **MQTT and IoT ecosystem maturity.** The Go MQTT ecosystem (Paho, mochi-mqtt) is battle-tested in production IoT systems. EMQX itself is partially Go. AWS IoT device SDKs have first-class Go support.

4. **Hiring pragmatics for a startup.** Go developers are abundant, productive within weeks, and the language's simplicity means any backend engineer can contribute. Rust's safety guarantees are academically superior but the 3-6 month ramp-up is a non-starter for a startup shipping hardware in 2026.

5. **Performance is more than sufficient.** At 1,000 robots x 10Hz = 10,000 messages/sec aggregate. Go handles this on a single core. We are orders of magnitude away from needing Rust-level optimization.

6. **Strong typing without ceremony.** Go's type system catches the class of bugs that matter (nil pointer dereferences, type mismatches, unhandled errors) without the cognitive overhead of Rust's borrow checker or Haskell-style type gymnastics.

**What Go is NOT ideal for (and mitigations):**

| Weakness | Mitigation |
|---|---|
| No generics until recently (1.18+) | Go 1.24 generics are mature enough for our use cases |
| Error handling verbosity | Consistent `if err != nil` patterns with custom error types and wrapping |
| No built-in ORM | sqlc (compile-time SQL verification) + pgx (native PostgreSQL driver) |
| GC pauses under extreme load | At 10K msg/sec we are nowhere near GC pressure. Profile before optimizing. |

**Rejected alternatives:**

- **Rust**: Superior safety guarantees but hiring bottleneck kills velocity. Revisit for the robot edge firmware, not the cloud backend.
- **Elixir/Phoenix**: BEAM VM is ideal for this workload but hiring in most markets is impractical. Team of 2-3 backend engineers cannot all be Elixir specialists.
- **Python (FastAPI)**: Prototyping speed is excellent but GIL, runtime typing, and container bloat make it wrong for a telemetry-heavy production system. Use Python for ML pipelines and data science, not the core API.
- **Node.js (NestJS)**: JavaScript in safety-critical command paths is a liability. TypeScript helps but runtime behavior is still JS semantics.

### 1.2 Exact Versions (Dependency Lockfile)

| Component | Version | Purpose |
|---|---|---|
| Go | 1.24.1 | Language runtime |
| pgx | v5 | PostgreSQL driver (native, no database/sql wrapper) |
| sqlc | 1.27 | Compile-time SQL to Go code generation |
| golang-migrate | v4 | Database schema migrations |
| chi | v5 | HTTP router (lightweight, stdlib-compatible) |
| connectrpc | 1.17 | Connect protocol (gRPC + HTTP/JSON dual protocol) |
| protoc | 28.3 | Protocol buffer compiler |
| paho.mqtt.golang | v1.5 | MQTT client library |
| golang-jwt | v5 | JWT token handling |
| otel-go | 1.32 | OpenTelemetry instrumentation |
| viper | 1.19 | Configuration management |
| zap | 1.27 | Structured logging |
| testify | 1.9 | Testing assertions |
| golangci-lint | 1.62 | Linting and static analysis |

---

## 2. Database Architecture

### 2.1 The Polyglot Persistence Strategy

ChoreRobotics has five fundamentally different data access patterns. Using a single database for all of them would force compromises that degrade performance and increase operational complexity. Instead, we use purpose-built databases for each pattern.

```
DATA TYPE MATRIX

                        Write Rate    Read Pattern       Retention    Consistency
                        ──────────    ────────────       ─────────    ───────────
User/Robot Metadata     Low (1/min)   Random lookup      Forever      Strong (ACID)
Telemetry Time-Series   High (10K/s)  Range scan + agg   90d raw      Eventual OK
OTA Binaries            Rare          Sequential read     Forever      Strong
Real-Time State         High (10K/s)  Key lookup          Ephemeral   Eventual OK
Task History            Medium        Append + analytics  1 year       Strong (ACID)
Zone Polygons           Low           By user/robot       Forever      Strong (ACID)
```

### 2.2 Database Selections

#### PostgreSQL 17 -- Relational Data (Users, Robots, Zones, Tasks, Schedules, Orders)

**Why PostgreSQL over MySQL:**

| Factor | PostgreSQL | MySQL |
|---|---|---|
| JSON/JSONB support | Native, indexed, queryable with GIN indexes | JSON type exists but indexing is limited |
| PostGIS for geospatial | First-class extension. ST_Contains, ST_Area on zone polygons | Spatial support exists but PostGIS is industry standard |
| ACID compliance | Full MVCC, serializable isolation | InnoDB is ACID but historically weaker isolation |
| Array types | Native array columns for polygon vertices | No native array type |
| Partitioning | Declarative partitioning (range, list, hash) | Partitioning exists but less flexible |
| Extension ecosystem | TimescaleDB, PostGIS, pg_cron, pgvector | Limited extension model |
| Logical replication | Built-in, row-level, selective | Built-in but less flexible |

**Decision: PostgreSQL 17** with PostGIS extension for geospatial zone queries.

Zone polygons are stored as PostGIS `GEOGRAPHY(POLYGON, 4326)` columns, enabling:
- `ST_Area(zone.boundary)` for area calculation in square meters
- `ST_Contains(zone.boundary, robot_position)` for geofencing
- `ST_Distance(zone.boundary, point)` for proximity queries
- Spatial indexing via GiST for sub-millisecond containment checks

#### TimescaleDB 2.17 -- Time-Series Telemetry

**Evaluation:**

| Factor | TimescaleDB | InfluxDB 3.0 | QuestDB | ClickHouse |
|---|---|---|---|---|
| **Query language** | SQL (standard PostgreSQL) | InfluxQL / SQL | SQL | SQL (ClickHouse dialect) |
| **Compression** | 90-95% on time-series | 90%+ | 85-90% | 95%+ (best) |
| **Write throughput** | 100K rows/sec per node | 200K+ points/sec | 500K+ rows/sec | 1M+ rows/sec |
| **Downsampling** | Continuous aggregates (materialized) | Retention policies + tasks | Not built-in | Materialized views |
| **Integration with PostgreSQL** | IS PostgreSQL (extension) | Separate system, separate query language | Separate system | Separate system |
| **Operational complexity** | Zero -- same PostgreSQL cluster | Separate cluster, separate backup, separate monitoring | Separate cluster | Separate cluster, complex replication |
| **Retention policies** | Built-in `drop_chunks()` + compression policies | Built-in retention policies | Manual | TTL on tables |
| **Geospatial in telemetry** | Full PostGIS support on hypertables | Limited | Not supported | Limited |

**Decision: TimescaleDB 2.17** (extension on the same PostgreSQL 17 instance)

**Primary reason: operational simplicity.** TimescaleDB is a PostgreSQL extension, not a separate database. This means:
- One database cluster to operate, backup, monitor, and scale
- Telemetry queries can JOIN directly to the relational tables (e.g., "show me telemetry for robots in zone X")
- Same connection pool, same authentication, same tooling
- Engineers write standard SQL, not a proprietary query language

At 1,000 robots x 10Hz = 10,000 rows/sec, TimescaleDB handles this trivially. ClickHouse and QuestDB have higher raw throughput but that headroom is irrelevant at our scale and adds operational burden.

**Continuous aggregates** handle downsampling automatically:
- Raw data: 10Hz, retained 90 days
- 1-minute aggregates: retained 1 year
- 1-hour aggregates: retained indefinitely

#### Amazon S3 (or MinIO for self-hosted) -- OTA Binary Storage

**Why S3 over filesystem:**

| Factor | S3 / MinIO | Local Filesystem |
|---|---|---|
| Durability | 99.999999999% (11 nines) | Single disk failure = data loss |
| Scalability | Unlimited | Disk capacity bound |
| Pre-signed URLs | Built-in. Robot downloads directly from S3 without proxying through API server. | Must proxy through application server, consuming bandwidth and memory. |
| Versioning | Built-in object versioning | Manual (symlinks, directories) |
| CDN integration | CloudFront / CDN edge caching for global distribution | Requires separate CDN setup |
| Cost | $0.023/GB/month (S3 Standard) | Disk cost + server cost |

**Decision: Amazon S3** with CloudFront CDN for firmware distribution.

Firmware binaries are 10-500MB. A pre-signed S3 URL lets the robot download directly from S3/CloudFront, bypassing the API server entirely. This eliminates the API server as a bandwidth bottleneck during fleet-wide OTA rollouts.

For local development and testing: MinIO (S3-compatible API) runs in Docker.

#### Redis 7.4 (Valkey 8.0 compatible) -- Real-Time State & Cache

**Evaluation:**

| Factor | Redis 7.4 | Valkey 8.0 | KeyDB |
|---|---|---|---|
| **Performance** | 100K+ ops/sec | Same (fork of Redis) | Higher throughput (multi-threaded) |
| **Pub/Sub** | Built-in, pattern matching | Same | Same |
| **Streams** | Redis Streams for ordered message log | Same | Same |
| **Licensing** | SSPL (not OSS since Redis 7.4) | BSD 3-Clause (true open source) | BSD 2-Clause |
| **Managed options** | AWS ElastiCache, all major clouds | AWS ElastiCache (Valkey mode) | Limited managed options |
| **Ecosystem maturity** | 15+ years, massive community | 2 years, growing fast | Smaller community |
| **Cluster mode** | Redis Cluster | Same | Same |

**Decision: Start with Redis 7.4 on AWS ElastiCache.** Migrate to Valkey 8.0 if licensing becomes a concern. The API is identical. ElastiCache supports both.

**Use cases:**
- **Robot state cache**: Last-known state per robot (battery, GPS, status). Key: `robot:{id}:state`. TTL: 5 minutes. Updated on every telemetry packet.
- **Session cache**: JWT session data, rate limiting counters.
- **Pub/Sub**: Internal service-to-service real-time events (robot state changes, command acknowledgments).
- **Redis Streams**: Ordered command queue per robot. Commands are appended to `robot:{id}:commands` stream. Robot's cloud proxy reads from stream and publishes to MQTT.
- **Distributed locks**: OTA rollout coordination, preventing concurrent firmware installs on same robot.

#### PostgreSQL (JSONB) for Zone Polygons -- NOT MongoDB

**Why PostgreSQL JSONB over MongoDB for zone polygons:**

The zone polygon schema is well-defined (id, name, type, vertices as coordinate array, area). This is not a "flexible document" problem -- it is a relational problem with a geospatial component.

| Factor | PostgreSQL + PostGIS | MongoDB + GeoJSON |
|---|---|---|
| Geospatial queries | PostGIS: mature, SQL-based, supports all OGC operations | MongoDB geospatial: adequate but less capable than PostGIS |
| Schema enforcement | Strong. `CHECK` constraints ensure valid polygons. | Schema validation exists but is optional and often skipped. |
| Joins with user/robot data | Native SQL JOINs. Zero overhead. | Requires application-level joins or $lookup (slow). |
| Transactions | Full ACID across zones + schedules + tasks in one transaction | Multi-document transactions exist but are slower and have caveats |
| Operational burden | Already running PostgreSQL. Zero additional infrastructure. | Separate database cluster to operate, backup, monitor. |

**Decision: PostgreSQL 17 with PostGIS.** Zones are stored in the same PostgreSQL instance as all other relational data. No MongoDB in the stack.

### 2.3 Database Topology Summary

```
┌──────────────────────────────────────────────────────────────────────┐
│                     DATABASE TOPOLOGY                                 │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  PostgreSQL 17 + TimescaleDB 2.17 + PostGIS 3.5                      │
│  ─────────────────────────────────────────────────                    │
│  Primary (write) + 1 Read Replica (read-heavy queries)               │
│                                                                       │
│  Schemas:                                                             │
│  ├── public           → Users, robots, orders, auth                  │
│  ├── zones            → Zone polygons (PostGIS GEOGRAPHY)            │
│  ├── tasks            → Schedules, task history, task configs        │
│  ├── ota              → Firmware versions, rollout state, device ver │
│  ├── notifications    → Push notification log, FCM tokens            │
│  └── telemetry        → TimescaleDB hypertables (partitioned)        │
│      ├── telemetry_raw      (10Hz, 90-day retention)                 │
│      ├── telemetry_1min     (continuous aggregate, 1-year)           │
│      └── telemetry_1hour    (continuous aggregate, indefinite)       │
│                                                                       │
│  Redis 7.4 (ElastiCache)                                             │
│  ─────────────────────                                                │
│  ├── Robot state cache     (robot:{id}:state)                        │
│  ├── Command streams       (robot:{id}:commands)                     │
│  ├── Session store         (session:{token})                         │
│  ├── Rate limit counters   (ratelimit:{ip}:{endpoint})               │
│  └── Pub/Sub channels      (events:robot_state, events:ota)         │
│                                                                       │
│  Amazon S3                                                            │
│  ─────────                                                            │
│  ├── chorerobotics-firmware/    (OTA binaries, versioned)            │
│  ├── chorerobotics-maps/        (exported map tiles, optional)       │
│  └── chorerobotics-backups/     (database backups)                   │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 3. Message Broker

### 3.1 MQTT Broker Selection

| Factor | EMQX 5.8 | Mosquitto 2.0 | HiveMQ 4.x | VerneMQ |
|---|---|---|---|---|
| **Clustering** | Native clustering, auto-discovery. Horizontal scaling. | Single node only. No built-in clustering. | Clustering (commercial only). | Clustering. Erlang-based. |
| **mTLS support** | Full mTLS with per-client certificate verification. X.509 auth plugin. | mTLS supported but certificate-based ACL requires custom plugin. | Full mTLS. Enterprise feature. | mTLS supported. |
| **MQTT 5.0** | Full support including shared subscriptions, topic aliases, flow control. | MQTT 5.0 supported since v2.0. | Full MQTT 5.0. | MQTT 5.0 supported. |
| **WebSocket bridge** | Built-in. MQTT over WebSocket for browser clients. | Built-in WebSocket listener. | Built-in. | Built-in. |
| **ACL per device** | Fine-grained ACL: each robot can only publish/subscribe to its own topics. File-based, database-backed, or HTTP auth hook. | ACL file. Limited dynamic ACL without plugins. | ACL via extensions. | ACL via Lua scripting or webhooks. |
| **Throughput** | 100M+ msg/sec in cluster benchmarks. | 50K msg/sec single node (sufficient for us). | High (commercial benchmarks). | High (Erlang VM). |
| **Rule engine** | Built-in SQL-based rule engine. Route MQTT messages to PostgreSQL, Redis, HTTP directly. No custom code needed. | None. All routing is external. | HiveMQ extensions (Java). | Lua scripting. |
| **Cost** | Open source (Apache 2.0). Enterprise features free up to 25 connections on EMQX Enterprise, but open source is sufficient. | Free (EPL/EDL). | Free tier limited. Enterprise is expensive. | Free (Apache 2.0). |
| **Ops complexity** | Medium. Erlang-based. Good Docker support. Helm charts available. | Low. Single binary. Simplest to operate. | Medium-High. JVM-based. | Medium. Erlang-based. |

**Decision: EMQX 5.8 (Open Source Edition)**

**Primary reasons:**

1. **Rule engine eliminates glue code.** EMQX's built-in rule engine can route telemetry MQTT messages directly to TimescaleDB and Redis without writing a custom consumer. Rule: "When message arrives on `robot/+/telemetry`, parse JSON, INSERT into `telemetry_raw` table." This eliminates an entire microservice (telemetry ingestion worker).

2. **Native clustering for growth.** When we exceed 1,000 robots, EMQX scales horizontally by adding nodes to the cluster. Mosquitto would require a complete architecture change at that point.

3. **mTLS with X.509 authentication.** Each robot's client certificate CN (Common Name) is extracted and used as the MQTT client ID. EMQX verifies the certificate chain against our CA and enforces that robot `CHOREROBOT-001` can only publish to `robot/CHOREROBOT-001/#`. This is built-in, not a custom plugin.

4. **WebSocket bridge for the mobile app and dashboard.** The Flutter app connects via MQTT over WebSocket (when in cloud mode). The internal dashboard connects via MQTT over WebSocket for real-time fleet monitoring. Same broker, same topic structure, different transport.

**Mosquitto is the backup plan.** If EMQX's operational complexity proves too high for a small team, Mosquitto is a drop-in replacement for the MQTT protocol layer. We would lose the rule engine (requiring a custom telemetry ingestion service) and clustering (fine for <1,000 robots).

### 3.2 EMQX Configuration Highlights

```
# Authentication: mTLS with X.509 certificate CN extraction
authentication = [
  {
    mechanism = password_based    # For app users (JWT-based MQTT auth)
    backend = http                # Verify JWT against auth service
  },
  {
    mechanism = x509              # For robots (mTLS certificate CN)
    ssl.verify = verify_peer
    ssl.certfile = "/certs/server.pem"
    ssl.keyfile = "/certs/server.key"
    ssl.cacertfile = "/certs/ca.pem"
  }
]

# ACL: Robot can only access its own topics
authorization = [
  {
    type = built_in_database
    rules = [
      # Robot identified by certificate CN
      {allow, {client, "${clientid}"}, publish,
        ["robot/${clientid}/telemetry", "robot/${clientid}/status",
         "robot/${clientid}/ota/status"]},
      {allow, {client, "${clientid}"}, subscribe,
        ["robot/${clientid}/commands/#", "robot/${clientid}/ota/deploy",
         "robot/${clientid}/zones/sync"]},
      # Deny everything else
      {deny, all}
    ]
  }
]

# Rule Engine: Telemetry to TimescaleDB
rule_engine.rules.telemetry_to_db = {
  sql = """
    SELECT
      clientid as robot_id,
      payload.battery_percent,
      payload.battery_voltage,
      payload.speed_ms,
      payload.heading_deg,
      payload.latitude,
      payload.longitude,
      payload.rtk_status,
      payload.satellite_count,
      payload.motor_fl_rpm,
      payload.motor_fr_rpm,
      payload.motor_rl_rpm,
      payload.motor_rr_rpm,
      payload.system_temp_c,
      payload.state,
      payload.active_task_id,
      timestamp
    FROM "robot/+/telemetry"
  """
  actions = [
    {
      function = "postgresql"
      args = {
        sql = "INSERT INTO telemetry.telemetry_raw (...) VALUES (...)"
      }
    },
    {
      function = "redis"
      args = {
        command = "SET robot:${clientid}:state '${payload}' EX 300"
      }
    }
  ]
}
```

---

## 4. Service Architecture

### 4.1 Service Decomposition

The backend is structured as a **modular monolith** that can be decomposed into microservices if needed. All services run in a single Go binary initially, separated by Go packages with clean interfaces. This gives us:
- Microservice-quality code boundaries
- Monolith deployment simplicity (single binary, single deploy, single debug)
- Option to extract any service into its own binary when scale demands it

```
SERVICE MAP

┌─────────────────────────────────────────────────────────────────────┐
│                         API GATEWAY (chi router)                     │
│  Rate limiting, JWT validation, request logging, CORS               │
│  Port 8080 (HTTP/REST) + Port 8443 (Connect/gRPC)                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐   │
│  │ Auth Service  │  │ Robot Service │  │ Telemetry Service        │   │
│  │              │  │              │  │                          │   │
│  │ - Sign up    │  │ - Register   │  │ - Query raw telemetry    │   │
│  │ - Sign in    │  │ - Provision  │  │ - Query aggregates       │   │
│  │ - JWT issue  │  │ - List/Get   │  │ - Live WebSocket stream  │   │
│  │ - JWT refresh│  │ - Update     │  │ - Export CSV             │   │
│  │ - Password   │  │ - Heartbeat  │  │                          │   │
│  │   reset      │  │ - Status     │  │ (Ingestion via EMQX     │   │
│  │ - mTLS cert  │  │              │  │  rule engine, not this   │   │
│  │   validation │  │              │  │  service)                │   │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘   │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐   │
│  │ Command      │  │ Zone Service │  │ Task Service             │   │
│  │ Service      │  │              │  │                          │   │
│  │              │  │ - Create zone│  │ - Create schedule        │   │
│  │ - Send cmd   │  │ - Update zone│  │ - Update schedule        │   │
│  │ - E-Stop     │  │ - Delete zone│  │ - List schedules         │   │
│  │ - Ack track  │  │ - List zones │  │ - Task history (CRUD)    │   │
│  │ - Cmd history│  │ - Sync to    │  │ - Task execution log     │   │
│  │              │  │   robot      │  │ - Analytics queries      │   │
│  │ (publishes   │  │ - Area calc  │  │                          │   │
│  │  to MQTT)    │  │   (PostGIS)  │  │                          │   │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘   │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐   │
│  │ OTA Service  │  │ Notification │  │ Weather Service          │   │
│  │              │  │ Service      │  │                          │   │
│  │ - Upload fw  │  │              │  │ - Fetch forecast         │   │
│  │ - Create     │  │ - Send push  │  │ - Cache per location     │   │
│  │   rollout    │  │   (FCM)      │  │ - Schedule adjustment    │   │
│  │ - Stage mgmt │  │ - Template   │  │   recommendations        │   │
│  │ - Robot pull │  │   management │  │ - Webhook for alerts     │   │
│  │ - Status     │  │ - Preference │  │                          │   │
│  │   tracking   │  │   management │  │                          │   │
│  │ - Rollback   │  │ - History    │  │                          │   │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │ Fleet Management Service (internal dashboard only)           │    │
│  │                                                              │    │
│  │ - All robots overview          - Telemetry dashboards       │    │
│  │ - Robot detail drill-down      - OTA deployment console     │    │
│  │ - User management              - Audit log                  │    │
│  │ - Analytics & reporting        - Alert management           │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 Service-by-Service Detail

#### Auth Service

| Aspect | Detail |
|---|---|
| **Responsibility** | User authentication, JWT issuance, device certificate validation |
| **Database** | PostgreSQL `public.users`, `public.refresh_tokens` |
| **External deps** | None |
| **Auth flow (app)** | Email/password -> bcrypt verify -> issue JWT access (15min) + refresh (30d) |
| **Auth flow (robot)** | mTLS handshake at EMQX broker. Certificate CN = robot serial number. No JWT needed. |
| **Password hashing** | bcrypt cost=12. Argon2id considered but bcrypt is sufficient and universally audited. |
| **JWT signing** | RS256 with rotating key pairs. Public key published at `/.well-known/jwks.json`. |
| **Rate limiting** | 5 login attempts per IP per 15 minutes. Progressive lockout. |

#### Robot Service

| Aspect | Detail |
|---|---|
| **Responsibility** | Robot lifecycle: registration, provisioning, status tracking |
| **Database** | PostgreSQL `public.robots`, `public.robot_certificates` |
| **Provisioning flow** | 1. Manufacturing: generate unique keypair + CSR for each robot. 2. Cloud CA signs CSR, issues device certificate. 3. Certificate + CA bundle flashed to robot during manufacturing. 4. Robot connects to EMQX with mTLS. Certificate CN = serial number. |
| **Heartbeat** | Robot publishes to `robot/{id}/status` every 30 seconds. If no heartbeat for 2 minutes, robot marked `offline` in Redis and PostgreSQL. Notification triggered. |
| **Registration** | User scans robot (BLE pairing in app) -> app calls `POST /api/v1/robots/register` with robot serial number + pairing code -> backend verifies pairing code -> associates robot with user account. |

#### Command Service

| Aspect | Detail |
|---|---|
| **Responsibility** | Relay commands from app to robot via MQTT |
| **Flow** | App sends `POST /api/v1/robots/{id}/commands` -> Command Service validates command + user authorization -> publishes to `robot/{id}/commands/{type}` MQTT topic -> robot receives and executes -> robot publishes ack to `robot/{id}/commands/{type}/ack` -> Command Service updates command status |
| **E-Stop path** | E-Stop commands skip all queuing. Published immediately to MQTT QoS 1 with `retain=false`. Timeout: if no ACK within 500ms, app shows "press physical button" warning. |
| **Command authority** | Commands from cloud connection are filtered per the tiered authority table (no joystick, no blade control via cloud). Enforced server-side, not just in the app. |
| **Idempotency** | Each command has a UUID. Robot ignores duplicate command IDs. |

#### Telemetry Service

| Aspect | Detail |
|---|---|
| **Responsibility** | Query interface for telemetry data. NOT responsible for ingestion (EMQX handles that). |
| **Database** | TimescaleDB hypertables `telemetry.telemetry_raw`, `telemetry.telemetry_1min`, `telemetry.telemetry_1hour` |
| **WebSocket endpoint** | `wss://api.chorerobotics.com/ws/telemetry/{robot_id}` -- streams live telemetry to the app when in cloud mode. Subscribes to Redis pub/sub internally, forwards to WebSocket. |
| **Query API** | `GET /api/v1/robots/{id}/telemetry?from=&to=&resolution=raw|1min|1hour` |
| **Auto-resolution** | If requested time range > 1 day, automatically serve from 1-minute aggregates. If > 30 days, serve from 1-hour aggregates. Prevents full-table scans on raw data. |

#### Zone Service

| Aspect | Detail |
|---|---|
| **Responsibility** | Zone polygon CRUD, area calculation, robot sync |
| **Database** | PostgreSQL with PostGIS `zones.zones` |
| **Sync flow** | App creates/edits zone -> API stores in PostgreSQL -> publishes zone update to `robot/{id}/zones/sync` MQTT topic -> robot downloads updated zone set |
| **Validation** | PostGIS `ST_IsValid()` ensures polygon is geometrically valid. Minimum 3 vertices. Maximum 1000 vertices. Self-intersecting polygons rejected. |
| **Area calculation** | Server-side via `ST_Area(boundary::geography)` returning square meters. |

#### OTA Service

Detailed in Section 6.

#### Notification Service

| Aspect | Detail |
|---|---|
| **Responsibility** | Push notifications to mobile app via FCM |
| **Database** | PostgreSQL `notifications.fcm_tokens`, `notifications.notification_log` |
| **FCM integration** | Firebase Admin SDK (Go). Topic-based for fleet-wide, token-based for per-user. |
| **Notification types** | `task_complete`, `task_error`, `battery_low`, `connection_lost`, `weather_alert`, `ota_available`, `estop_triggered` |
| **User preferences** | Per-user toggle for each notification type. Stored in PostgreSQL. Checked before sending. |
| **Deduplication** | Same notification type + robot_id suppressed for 5 minutes to prevent alert storms. |

#### Weather Service

| Aspect | Detail |
|---|---|
| **Responsibility** | Fetch weather forecasts, recommend schedule adjustments |
| **External API** | OpenWeatherMap One Call API 3.0 ($0.0015/call, ~1000 calls/day at scale) |
| **Cache** | Redis. Forecast cached per lat/lng grid cell (0.01 degree resolution) for 30 minutes. |
| **Schedule integration** | Weather Service checks forecast before scheduled task execution. If rain probability > 70% or wind > 25mph or temperature < -20C, recommends skip. Notification sent to user. Robot's local scheduler also has independent weather-hold logic. |

#### Fleet Management Service

| Aspect | Detail |
|---|---|
| **Responsibility** | Internal dashboard API for operations team |
| **Access control** | Separate admin JWT with role-based permissions (viewer, operator, admin) |
| **Features** | Fleet map (all robots on world map), per-robot drill-down, OTA deployment console, user management, audit log, analytics dashboards |
| **Database** | Reads from all schemas. Writes to `public.admin_audit_log`. |

---

## 5. API Design

### 5.1 Protocol Selection

| Client | Protocol | Justification |
|---|---|---|
| **Mobile App (Flutter)** | REST (JSON over HTTPS) + MQTT over WebSocket | REST for CRUD operations. MQTT/WS for real-time telemetry and commands when in cloud mode. Flutter's `dio` library handles REST. `mqtt_client` handles MQTT/WS. |
| **Robot (Jetson)** | MQTT (native TCP) + HTTPS (for OTA download) | MQTT for all real-time communication (telemetry publish, command subscribe). HTTPS only for large file downloads (OTA firmware). mTLS on both. |
| **Internal Dashboard (Web)** | REST (JSON over HTTPS) + MQTT over WebSocket | Same as mobile app. Dashboard is a React/Vue web app consuming the same API. |

**Why REST over GraphQL or gRPC for the mobile app:**

| Factor | REST | GraphQL | gRPC/Connect |
|---|---|---|---|
| Flutter ecosystem | dio is mature, interceptors, mTLS support | graphql_flutter exists but less mature | connectrpc-dart exists but very new |
| Caching | HTTP caching (ETags, Cache-Control) works out of the box | Requires client-side cache (Apollo) | No HTTP caching |
| Debugging | curl, Postman, browser dev tools | Requires GraphQL-aware tools | Requires gRPC-aware tools (grpcurl) |
| Over-fetching concern | Not a concern -- our resources are small and well-defined. A robot has ~15 fields. | GraphQL solves a problem we do not have. | N/A |
| Real-time | WebSocket/MQTT (separate channel) | GraphQL subscriptions (complex) | Server-streaming (good) |
| Code generation | OpenAPI spec -> client generation | Schema -> codegen (good) | Protobuf -> codegen (excellent) |

**Decision: REST for CRUD + MQTT over WebSocket for real-time.**

GraphQL's flexibility is unnecessary -- our data shapes are fixed and known at design time. gRPC/Connect is considered for internal service-to-service communication if we decompose into microservices later.

### 5.2 API Conventions

```
Base URL:       https://api.chorerobotics.com/api/v1
Auth:           Bearer JWT in Authorization header
Content-Type:   application/json
Error format:   { "error": { "code": "ROBOT_NOT_FOUND", "message": "...", "details": {} } }
Pagination:     ?page=1&per_page=20 (response includes total_count, page, per_page)
Timestamps:     ISO 8601 with timezone (2026-03-17T14:30:00Z)
IDs:            UUID v7 (time-ordered for database performance)
Versioning:     URL path (/api/v1/, /api/v2/)
Rate limiting:  X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset headers
```

---

## 6. OTA Update System

### 6.1 OTA Architecture Overview

The OTA system handles three distinct artifact types with different sizes, installation procedures, and risk profiles:

| Artifact Type | Typical Size | Installation Method | Rollback Method | Risk Level |
|---|---|---|---|---|
| **Robot firmware** (custom C/C++ on TC397) | 10-50MB | Flash via CAN bootloader | Dual-bank flash (A/B partitioning) | HIGH -- bad firmware bricks the safety controller |
| **ROS2 packages** (.deb on Jetson) | 50-200MB | `dpkg -i` on Jetson Linux | `dpkg --configure -a` + previous .deb re-install | MEDIUM -- bad package crashes ROS2 nodes |
| **Jetson system updates** (L4T) | 200-500MB | NVIDIA OTA tools (nv-l4t-update) | A/B rootfs partitioning | HIGH -- bad system update bricks the Jetson |

### 6.2 OTA Pipeline

```
FIRMWARE UPLOAD & DEPLOYMENT PIPELINE

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Engineer      │────>│ OTA Service  │────>│ Amazon S3     │
│ uploads       │ POST│ (API)        │ PUT │ (binary store)│
│ firmware.bin  │     │              │     │               │
│ + manifest    │     │ Validates:   │     │ Path:         │
│               │     │ - checksum   │     │ /firmware/    │
│               │     │ - signature  │     │  {type}/      │
│               │     │ - manifest   │     │  {version}/   │
│               │     │   schema     │     │  artifact.bin │
└──────────────┘     └──────┬───────┘     └──────────────┘
                            │
                            │ Creates rollout record in PostgreSQL
                            ▼
                     ┌──────────────┐
                     │ Rollout      │
                     │ Manager      │
                     │              │
                     │ State machine│
                     │ per rollout: │
                     │              │
                     │ CREATED      │
                     │   ↓          │
                     │ CANARY (1)   │──── Select 1 robot, deploy, wait 24h
                     │   ↓          │     Monitor: health checks pass?
                     │ STAGE_10%    │──── Deploy to 10% of fleet, wait 12h
                     │   ↓          │     Monitor: error rate < 0.1%?
                     │ STAGE_50%    │──── Deploy to 50% of fleet, wait 6h
                     │   ↓          │
                     │ STAGE_100%   │──── Deploy to remaining fleet
                     │   ↓          │
                     │ COMPLETE     │
                     │              │
                     │ At any stage:│
                     │ ERROR →      │──── Auto-halt rollout
                     │ ROLLBACK     │──── Revert affected robots
                     └──────────────┘
```

### 6.3 Firmware Manifest Schema

Every firmware upload includes a manifest file (JSON) that describes the artifact:

```json
{
  "manifest_version": 1,
  "artifact_type": "robot_firmware",
  "version": "2.4.1",
  "version_code": 241,
  "release_channel": "stable",
  "min_compatible_version": "2.0.0",
  "max_compatible_version": null,
  "target_hardware": ["CHOREROBOT-MK1", "CHOREROBOT-MK1-PRO"],
  "artifact": {
    "filename": "robot-firmware-2.4.1.bin",
    "size_bytes": 15728640,
    "sha256": "a1b2c3d4e5f6...",
    "signature": "base64-encoded-ed25519-signature"
  },
  "release_notes": "Fixed RTK reconnection after GPS signal loss. Improved snow plow depth sensing.",
  "rollback_safe": true,
  "requires_reboot": true,
  "estimated_install_time_sec": 120,
  "pre_install_checks": [
    { "type": "battery_min_percent", "value": 50 },
    { "type": "state_must_be", "value": ["idle", "docked"] },
    { "type": "attachment_detached", "value": true }
  ]
}
```

### 6.4 Robot-Side OTA Flow

```
ROBOT OTA STATE MACHINE

1. IDLE
   Robot periodically checks (every 6 hours or on MQTT notification):
   GET https://api.chorerobotics.com/api/v1/ota/check
   Headers: X-Robot-Serial, X-Current-Version, X-Hardware-Model

   Response: { "update_available": true, "version": "2.4.1", "manifest_url": "..." }

2. DOWNLOAD
   Robot downloads manifest, verifies schema.
   Robot downloads artifact via pre-signed S3 URL.
   Downloads to /tmp/ota/ with progress tracking.
   Robot publishes progress to: robot/{id}/ota/status
   {"state": "downloading", "progress_percent": 45, "version": "2.4.1"}

3. VERIFY
   Robot computes SHA-256 of downloaded binary.
   Compares to manifest sha256. MUST match exactly.
   Robot verifies Ed25519 signature using embedded public key.
   Signature MUST verify. If not: abort, report tampering.

   Robot publishes: {"state": "verified", "version": "2.4.1"}

4. PRE-INSTALL CHECKS
   Check battery >= 50%
   Check robot state is idle or docked
   Check attachment is detached (for firmware updates)
   If any check fails: defer update, retry in 1 hour.

5. INSTALL
   For robot firmware: flash to inactive bank (A/B partition)
   For ROS2 packages: dpkg -i in chroot, systemd service restart
   For Jetson system: nv-l4t-update apply

   Robot publishes: {"state": "installing", "progress_percent": 80, "version": "2.4.1"}

6. REBOOT (if required by manifest)
   Robot gracefully stops all ROS2 nodes.
   Robot sends final status: {"state": "rebooting", "version": "2.4.1"}
   Robot reboots.

7. HEALTH CHECK (post-reboot)
   Robot boots on new firmware (active bank B).
   Robot runs self-test sequence:
   - CAN bus communication check
   - Motor controller response check
   - GPS/RTK module response check
   - IMU calibration check
   - MQTT reconnection within 60 seconds

   If ALL checks pass:
     Robot marks bank B as "confirmed good"
     Robot publishes: {"state": "complete", "version": "2.4.1", "health": "ok"}

   If ANY check fails:
     Robot marks bank B as "failed"
     Robot reboots to bank A (previous firmware)
     Robot publishes: {"state": "rollback", "version": "2.4.1", "reason": "health_check_failed",
                       "failed_checks": ["can_bus_timeout"]}

8. CLOUD-SIDE ROLLBACK TRACKING
   OTA Service receives rollback status.
   If canary robot rolled back: halt entire rollout.
   If >2% of robots in a stage roll back: halt rollout, alert operations team.
   Operations team can manually resume or abort.
```

### 6.5 Security: Firmware Signing

```
FIRMWARE SIGNING CHAIN

  Build Server (CI/CD)
       │
       │ 1. Compile firmware
       │ 2. Sign with Ed25519 private key (stored in HSM / AWS KMS)
       │ 3. Include signature in manifest
       ▼
  S3 (binary + manifest uploaded)
       │
       │ 4. Pre-signed URL generated (time-limited, 1 hour)
       ▼
  Robot downloads
       │
       │ 5. Verify Ed25519 signature with PUBLIC key
       │    (public key embedded in robot at manufacturing, in read-only partition)
       │
       │ 6. If signature invalid: ABORT, report to cloud, NEVER install
       ▼
  Install proceeds only if signature valid
```

The Ed25519 signing key is stored in AWS KMS (Hardware Security Module backed). The private key never leaves KMS. The CI/CD pipeline calls KMS to sign, receives the signature, and includes it in the manifest. Even if S3 is compromised, an attacker cannot produce a valid signature without KMS access.

---

## 7. MQTT Topic Structure

### 7.1 Topic Hierarchy

```
MQTT TOPIC TREE

robot/{serial}/                          ← Per-robot namespace
├── telemetry                            ← Robot PUBLISHES at 10Hz
│   Payload: {
│     "battery_percent": 82.5,
│     "battery_voltage": 48.2,
│     "battery_current_amps": -2.1,
│     "battery_temp_c": 35.0,
│     "speed_ms": 1.2,
│     "heading_deg": 147.3,
│     "latitude": 33.684412,
│     "longitude": -73.047923,
│     "rtk_status": "fix",
│     "satellite_count": 18,
│     "motor_fl_rpm": 1200,
│     "motor_fr_rpm": 1180,
│     "motor_rl_rpm": 1195,
│     "motor_rr_rpm": 1210,
│     "system_temp_c": 42.0,
│     "state": "working",
│     "active_task_id": "task-uuid-here",
│     "signal_strength": 3,
│     "ts": 1710680400000
│   }
│   QoS: 0 (fire and forget — telemetry is high-frequency, loss of
│          individual packets is acceptable)
│
├── status                               ← Robot PUBLISHES every 30s
│   Payload: {
│     "state": "idle",
│     "firmware_version": "2.4.1",
│     "ros2_version": "1.3.0",
│     "jetson_version": "36.4.0",
│     "uptime_sec": 86400,
│     "attachment": "mower_blade",
│     "wifi_ssid": "HomeNetwork",
│     "ip_address": "192.168.1.42",
│     "ts": 1710680400000
│   }
│   QoS: 1 (at least once — status is important for online/offline detection)
│   Retain: true (last status always available for new subscribers)
│
├── commands/                            ← Robot SUBSCRIBES
│   ├── drive                            ← Joystick commands (only via LAN/BLE, never cloud)
│   │   Payload: {"linear_x": 0.5, "angular_z": 0.1, "cmd_id": "uuid"}
│   │   QoS: 0 (latest value wins for drive commands)
│   │
│   ├── task                             ← Start/stop/pause task
│   │   Payload: {"action": "start", "task_id": "uuid", "type": "mow",
│   │             "zone_id": "uuid", "parameters": {...}, "cmd_id": "uuid"}
│   │   QoS: 1
│   │
│   ├── estop                            ← EMERGENCY STOP
│   │   Payload: {"action": "stop", "cmd_id": "uuid", "ts": 1710680400000}
│   │   QoS: 1 (CRITICAL — must be delivered)
│   │
│   ├── dock                             ← Return to dock
│   │   Payload: {"cmd_id": "uuid"}
│   │   QoS: 1
│   │
│   ├── config                           ← Robot configuration updates
│   │   Payload: {"cutting_height_mm": 50, "speed_limit_ms": 1.5, "cmd_id": "uuid"}
│   │   QoS: 1
│   │
│   └── ack                              ← Robot PUBLISHES command acknowledgments
│       Payload: {"cmd_id": "uuid", "status": "accepted|rejected|completed",
│                 "reason": "battery_too_low", "ts": 1710680400000}
│       QoS: 1
│
├── ota/                                 ← OTA update channel
│   ├── deploy                           ← Cloud PUBLISHES when update available
│   │   Payload: {"version": "2.4.1", "type": "robot_firmware",
│   │             "manifest_url": "https://...", "cmd_id": "uuid"}
│   │   QoS: 1, Retain: true
│   │
│   └── status                           ← Robot PUBLISHES OTA progress
│       Payload: {"state": "downloading|verified|installing|complete|rollback",
│                 "version": "2.4.1", "progress_percent": 45,
│                 "error": null, "ts": 1710680400000}
│       QoS: 1
│
├── zones/
│   └── sync                             ← Cloud PUBLISHES zone updates
│       Payload: {"zones": [{...}], "version": 12, "ts": 1710680400000}
│       QoS: 1, Retain: true
│
└── tasks/
    └── history                          ← Robot PUBLISHES completed task records
        Payload: {"task_id": "uuid", "type": "mow", "zone_id": "uuid",
                  "started_at": "iso8601", "completed_at": "iso8601",
                  "area_completed_sqm": 450.2, "battery_used_percent": 15.3,
                  "distance_traveled_m": 1200.5, "status": "complete"}
        QoS: 1


FLEET-WIDE TOPICS (internal dashboard)

fleet/                                   ← Dashboard subscribes
├── status                               ← Aggregated fleet status (published by backend)
│   Payload: {"online": 87, "offline": 13, "working": 42, "error": 2}
│   Published every 10 seconds by Fleet Management Service
│
└── alerts                               ← Real-time alerts for dashboard operators
    Payload: {"robot_serial": "CR-001", "type": "estop_triggered",
              "severity": "critical", "message": "...", "ts": ...}
```

### 7.2 QoS and Retain Strategy

| Topic | QoS | Retain | Rationale |
|---|---|---|---|
| `telemetry` | 0 | No | High frequency, loss of individual packets is fine. QoS 1 would overwhelm the broker at 10Hz x 1000 robots. |
| `status` | 1 | Yes | Must be delivered. Retained so new subscribers (app reconnect) immediately get last known status. |
| `commands/*` | 1 | No | Commands must be delivered exactly. Not retained -- stale commands are dangerous. |
| `commands/estop` | 1 | No | CRITICAL. Must be delivered. Not retained -- E-Stop is instantaneous, not persistent. |
| `ota/deploy` | 1 | Yes | Retained so robot gets the update notification even if it reconnects after the publish. |
| `ota/status` | 1 | No | Status reports must be delivered for rollout tracking. Not retained. |
| `zones/sync` | 1 | Yes | Retained so robot gets latest zone set on reconnect. |
| `tasks/history` | 1 | No | Task records must be delivered to cloud. Not retained. |

---

## 8. Database Schemas

### 8.1 Core Relational Schema (PostgreSQL)

```sql
-- =============================================================
-- SCHEMA: public (users, robots, auth)
-- =============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "timescaledb";

-- Users
CREATE TABLE public.users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,  -- bcrypt cost=12
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    phone           VARCHAR(20),
    role            VARCHAR(20) NOT NULL DEFAULT 'owner'
                    CHECK (role IN ('owner', 'household', 'guest', 'admin')),
    email_verified  BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_users_email ON public.users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role ON public.users(role) WHERE deleted_at IS NULL;

-- Refresh tokens
CREATE TABLE public.refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(255) NOT NULL,  -- SHA-256 of the token
    device_info VARCHAR(255),
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at  TIMESTAMPTZ
);

CREATE INDEX idx_refresh_tokens_user ON public.refresh_tokens(user_id)
    WHERE revoked_at IS NULL;
CREATE INDEX idx_refresh_tokens_expires ON public.refresh_tokens(expires_at)
    WHERE revoked_at IS NULL;

-- Robots
CREATE TABLE public.robots (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    serial_number   VARCHAR(50) UNIQUE NOT NULL,  -- e.g., "CR-MK1-00001"
    model           VARCHAR(50) NOT NULL,          -- e.g., "CHOREROBOT-MK1"
    name            VARCHAR(100) NOT NULL DEFAULT 'My ChoreBot',
    owner_id        UUID REFERENCES public.users(id) ON DELETE SET NULL,
    pairing_code    VARCHAR(10),                   -- 6-digit code, cleared after pairing
    paired_at       TIMESTAMPTZ,
    firmware_version    VARCHAR(20),
    ros2_version        VARCHAR(20),
    jetson_version      VARCHAR(20),
    last_seen_at        TIMESTAMPTZ,
    last_known_lat      DOUBLE PRECISION,
    last_known_lng      DOUBLE PRECISION,
    status          VARCHAR(20) NOT NULL DEFAULT 'provisioned'
                    CHECK (status IN ('provisioned', 'paired', 'active', 'offline',
                                      'maintenance', 'decommissioned')),
    attachment_type VARCHAR(30)
                    CHECK (attachment_type IN ('mower_blade', 'snow_plow',
                                               'leaf_collector', 'none', NULL)),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_robots_owner ON public.robots(owner_id);
CREATE INDEX idx_robots_serial ON public.robots(serial_number);
CREATE INDEX idx_robots_status ON public.robots(status);

-- Robot certificates (for mTLS provisioning tracking)
CREATE TABLE public.robot_certificates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    robot_id        UUID NOT NULL REFERENCES public.robots(id) ON DELETE CASCADE,
    serial_number   VARCHAR(255) NOT NULL,  -- X.509 serial number
    fingerprint     VARCHAR(64) NOT NULL,   -- SHA-256 fingerprint
    issued_at       TIMESTAMPTZ NOT NULL,
    expires_at      TIMESTAMPTZ NOT NULL,
    revoked_at      TIMESTAMPTZ,
    revocation_reason VARCHAR(255)
);

CREATE INDEX idx_robot_certs_robot ON public.robot_certificates(robot_id);
CREATE INDEX idx_robot_certs_fingerprint ON public.robot_certificates(fingerprint);

-- FCM push notification tokens
CREATE TABLE public.fcm_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    token       VARCHAR(500) NOT NULL,
    platform    VARCHAR(10) NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_fcm_tokens_user ON public.fcm_tokens(user_id);

-- User notification preferences
CREATE TABLE public.notification_preferences (
    user_id             UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    task_complete       BOOLEAN NOT NULL DEFAULT true,
    task_error          BOOLEAN NOT NULL DEFAULT true,
    battery_low         BOOLEAN NOT NULL DEFAULT true,
    connection_lost     BOOLEAN NOT NULL DEFAULT true,
    weather_alert       BOOLEAN NOT NULL DEFAULT false,
    ota_available       BOOLEAN NOT NULL DEFAULT true,
    estop_triggered     BOOLEAN NOT NULL DEFAULT true,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Orders (robot reservations / purchases)
CREATE TABLE public.orders (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES public.users(id),
    order_number        VARCHAR(20) UNIQUE NOT NULL,  -- e.g., "ORD-555-01"
    status              VARCHAR(20) NOT NULL DEFAULT 'reserved'
                        CHECK (status IN ('reserved', 'confirmed', 'manufacturing',
                                          'shipping', 'delivered', 'cancelled')),
    configuration       JSONB NOT NULL,  -- chassis, drive_train, battery, modules
    shipping_address    JSONB NOT NULL,
    total_price_cents   INTEGER NOT NULL,
    deposit_paid_cents  INTEGER NOT NULL DEFAULT 0,
    payment_intent_id   VARCHAR(255),    -- Stripe payment intent
    estimated_delivery  DATE,
    robot_id            UUID REFERENCES public.robots(id),  -- assigned after manufacturing
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_user ON public.orders(user_id);
CREATE INDEX idx_orders_status ON public.orders(status);

-- =============================================================
-- SCHEMA: zones
-- =============================================================

CREATE SCHEMA IF NOT EXISTS zones;

CREATE TABLE zones.zones (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    robot_id    UUID NOT NULL REFERENCES public.robots(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES public.users(id),
    name        VARCHAR(100) NOT NULL,
    zone_type   VARCHAR(20) NOT NULL
                CHECK (zone_type IN ('mow', 'snow', 'leaf', 'no_go')),
    boundary    GEOGRAPHY(POLYGON, 4326) NOT NULL,
    area_sqm    DOUBLE PRECISION GENERATED ALWAYS AS
                (ST_Area(boundary::geography)) STORED,
    vertices    JSONB NOT NULL,  -- Original vertex list for app consumption
                                 -- [{"lat": 33.684, "lng": -73.047}, ...]
    version     INTEGER NOT NULL DEFAULT 1,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_zones_robot ON zones.zones(robot_id) WHERE is_active = true;
CREATE INDEX idx_zones_user ON zones.zones(user_id);
CREATE INDEX idx_zones_boundary ON zones.zones USING GIST(boundary);

-- =============================================================
-- SCHEMA: tasks
-- =============================================================

CREATE SCHEMA IF NOT EXISTS tasks;

-- Scheduled tasks (recurring)
CREATE TABLE tasks.schedules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    robot_id        UUID NOT NULL REFERENCES public.robots(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES public.users(id),
    name            VARCHAR(100),
    task_type       VARCHAR(20) NOT NULL
                    CHECK (task_type IN ('mow', 'plow', 'collect')),
    zone_id         UUID NOT NULL REFERENCES zones.zones(id),
    days_of_week    INTEGER[] NOT NULL,  -- 0=Sunday, 6=Saturday
    start_time      TIME NOT NULL,
    parameters      JSONB NOT NULL DEFAULT '{}',
                    -- Mow: {"pattern": "straight", "angle_deg": 0, "overlap_pct": 10,
                    --        "cutting_height_mm": 50}
                    -- Snow: {"start_position": "entrance", "depth": "medium",
                    --         "disposal_direction": "left"}
                    -- Leaf: {"mode": "full_zone", "collection_mode": "mulch",
                    --         "dump_point": {"lat": 33.68, "lng": -73.04}}
    is_enabled      BOOLEAN NOT NULL DEFAULT true,
    weather_hold    BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_schedules_robot ON tasks.schedules(robot_id) WHERE is_enabled = true;

-- Task execution history
CREATE TABLE tasks.task_history (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    robot_id            UUID NOT NULL REFERENCES public.robots(id),
    user_id             UUID REFERENCES public.users(id),
    schedule_id         UUID REFERENCES tasks.schedules(id),
    task_type           VARCHAR(20) NOT NULL,
    zone_id             UUID REFERENCES zones.zones(id),
    status              VARCHAR(20) NOT NULL
                        CHECK (status IN ('pending', 'active', 'paused',
                                          'complete', 'failed', 'cancelled')),
    parameters          JSONB NOT NULL DEFAULT '{}',
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    duration_sec        INTEGER,
    area_completed_sqm  DOUBLE PRECISION,
    distance_traveled_m DOUBLE PRECISION,
    battery_used_pct    DOUBLE PRECISION,
    error_code          VARCHAR(50),
    error_message       TEXT,
    path_geojson        JSONB,  -- GeoJSON LineString of robot's actual path
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_task_history_robot ON tasks.task_history(robot_id);
CREATE INDEX idx_task_history_robot_time ON tasks.task_history(robot_id, started_at DESC);
CREATE INDEX idx_task_history_status ON tasks.task_history(status);

-- =============================================================
-- SCHEMA: ota
-- =============================================================

CREATE SCHEMA IF NOT EXISTS ota;

-- Firmware versions (uploaded artifacts)
CREATE TABLE ota.firmware_versions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    artifact_type       VARCHAR(30) NOT NULL
                        CHECK (artifact_type IN ('robot_firmware', 'ros2_package',
                                                  'jetson_system')),
    version             VARCHAR(20) NOT NULL,
    version_code        INTEGER NOT NULL,
    release_channel     VARCHAR(20) NOT NULL DEFAULT 'stable'
                        CHECK (release_channel IN ('alpha', 'beta', 'stable')),
    target_hardware     VARCHAR(50)[] NOT NULL,
    manifest            JSONB NOT NULL,  -- Full manifest JSON
    s3_key              VARCHAR(500) NOT NULL,
    size_bytes          BIGINT NOT NULL,
    sha256              VARCHAR(64) NOT NULL,
    signature           TEXT NOT NULL,  -- Ed25519 signature (base64)
    release_notes       TEXT,
    uploaded_by         UUID REFERENCES public.users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(artifact_type, version)
);

-- Rollout campaigns
CREATE TABLE ota.rollouts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firmware_version_id UUID NOT NULL REFERENCES ota.firmware_versions(id),
    status              VARCHAR(20) NOT NULL DEFAULT 'created'
                        CHECK (status IN ('created', 'canary', 'stage_10',
                                          'stage_50', 'stage_100',
                                          'complete', 'halted', 'rolled_back')),
    target_filter       JSONB,  -- Optional filter: {"model": "MK1", "min_version": "2.0.0"}
    canary_robot_id     UUID REFERENCES public.robots(id),
    total_target_count  INTEGER,
    deployed_count      INTEGER NOT NULL DEFAULT 0,
    success_count       INTEGER NOT NULL DEFAULT 0,
    failure_count       INTEGER NOT NULL DEFAULT 0,
    rollback_count      INTEGER NOT NULL DEFAULT 0,
    auto_advance        BOOLEAN NOT NULL DEFAULT false,
    created_by          UUID REFERENCES public.users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Per-robot OTA deployment status
CREATE TABLE ota.robot_deployments (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rollout_id          UUID NOT NULL REFERENCES ota.rollouts(id),
    robot_id            UUID NOT NULL REFERENCES public.robots(id),
    firmware_version_id UUID NOT NULL REFERENCES ota.firmware_versions(id),
    status              VARCHAR(20) NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'notified', 'downloading',
                                          'verified', 'installing', 'complete',
                                          'failed', 'rolled_back')),
    progress_percent    INTEGER DEFAULT 0,
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    error_message       TEXT,
    attempts            INTEGER NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(rollout_id, robot_id)
);

CREATE INDEX idx_robot_deployments_rollout ON ota.robot_deployments(rollout_id);
CREATE INDEX idx_robot_deployments_robot ON ota.robot_deployments(robot_id);
CREATE INDEX idx_robot_deployments_status ON ota.robot_deployments(status);

-- =============================================================
-- SCHEMA: telemetry (TimescaleDB hypertables)
-- =============================================================

CREATE SCHEMA IF NOT EXISTS telemetry;

CREATE TABLE telemetry.telemetry_raw (
    time                TIMESTAMPTZ NOT NULL,
    robot_id            UUID NOT NULL,
    battery_percent     REAL,
    battery_voltage     REAL,
    battery_current_amps REAL,
    battery_temp_c      REAL,
    speed_ms            REAL,
    heading_deg         REAL,
    latitude            DOUBLE PRECISION,
    longitude           DOUBLE PRECISION,
    rtk_status          SMALLINT,  -- 0=none, 1=single, 2=float, 3=fix
    satellite_count     SMALLINT,
    motor_fl_rpm        SMALLINT,
    motor_fr_rpm        SMALLINT,
    motor_rl_rpm        SMALLINT,
    motor_rr_rpm        SMALLINT,
    system_temp_c       REAL,
    state               SMALLINT,  -- 0=idle, 1=working, 2=charging, etc.
    active_task_id      UUID,
    signal_strength     SMALLINT
);

-- Convert to TimescaleDB hypertable (partitioned by time, 1-day chunks)
SELECT create_hypertable('telemetry.telemetry_raw', 'time',
    chunk_time_interval => INTERVAL '1 day');

-- Compression policy: compress chunks older than 7 days
ALTER TABLE telemetry.telemetry_raw SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'robot_id',
    timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('telemetry.telemetry_raw', INTERVAL '7 days');

-- Retention policy: drop raw data older than 90 days
SELECT add_retention_policy('telemetry.telemetry_raw', INTERVAL '90 days');

-- Index for per-robot time range queries
CREATE INDEX idx_telemetry_raw_robot_time ON telemetry.telemetry_raw(robot_id, time DESC);

-- Continuous aggregate: 1-minute averages
CREATE MATERIALIZED VIEW telemetry.telemetry_1min
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 minute', time) AS bucket,
    robot_id,
    AVG(battery_percent) AS avg_battery_percent,
    MIN(battery_percent) AS min_battery_percent,
    AVG(battery_voltage) AS avg_battery_voltage,
    AVG(speed_ms) AS avg_speed_ms,
    MAX(speed_ms) AS max_speed_ms,
    AVG(system_temp_c) AS avg_system_temp_c,
    MAX(system_temp_c) AS max_system_temp_c,
    LAST(latitude, time) AS last_latitude,
    LAST(longitude, time) AS last_longitude,
    LAST(rtk_status, time) AS last_rtk_status,
    LAST(state, time) AS last_state,
    COUNT(*) AS sample_count
FROM telemetry.telemetry_raw
GROUP BY bucket, robot_id;

-- Refresh policy for 1-minute aggregate
SELECT add_continuous_aggregate_policy('telemetry.telemetry_1min',
    start_offset => INTERVAL '2 hours',
    end_offset => INTERVAL '1 minute',
    schedule_interval => INTERVAL '1 minute');

-- Retention policy: keep 1-minute data for 1 year
SELECT add_retention_policy('telemetry.telemetry_1min', INTERVAL '1 year');

-- Continuous aggregate: 1-hour averages (built on 1-minute aggregate)
CREATE MATERIALIZED VIEW telemetry.telemetry_1hour
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', bucket) AS bucket,
    robot_id,
    AVG(avg_battery_percent) AS avg_battery_percent,
    MIN(min_battery_percent) AS min_battery_percent,
    AVG(avg_speed_ms) AS avg_speed_ms,
    MAX(max_speed_ms) AS max_speed_ms,
    AVG(avg_system_temp_c) AS avg_system_temp_c,
    MAX(max_system_temp_c) AS max_system_temp_c,
    LAST(last_latitude, bucket) AS last_latitude,
    LAST(last_longitude, bucket) AS last_longitude,
    LAST(last_rtk_status, bucket) AS last_rtk_status,
    SUM(sample_count) AS sample_count
FROM telemetry.telemetry_1min
GROUP BY time_bucket('1 hour', bucket), robot_id;

SELECT add_continuous_aggregate_policy('telemetry.telemetry_1hour',
    start_offset => INTERVAL '25 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

-- 1-hour data retained indefinitely (no retention policy)

-- =============================================================
-- SCHEMA: notifications
-- =============================================================

CREATE SCHEMA IF NOT EXISTS notifications;

CREATE TABLE notifications.notification_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES public.users(id),
    robot_id        UUID REFERENCES public.robots(id),
    type            VARCHAR(30) NOT NULL,
    title           VARCHAR(255) NOT NULL,
    body            TEXT NOT NULL,
    data            JSONB,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    delivered_at    TIMESTAMPTZ,
    read_at         TIMESTAMPTZ
);

CREATE INDEX idx_notification_log_user ON notifications.notification_log(user_id, sent_at DESC);

-- =============================================================
-- Audit log (for admin/fleet management)
-- =============================================================

CREATE TABLE public.admin_audit_log (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id    UUID NOT NULL REFERENCES public.users(id),
    action      VARCHAR(100) NOT NULL,
    resource    VARCHAR(100) NOT NULL,
    resource_id UUID,
    details     JSONB,
    ip_address  INET,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_log_admin ON public.admin_audit_log(admin_id, created_at DESC);
CREATE INDEX idx_audit_log_resource ON public.admin_audit_log(resource, resource_id);
```

### 8.2 Data Volume Estimates

| Table | Write Rate | Row Size | Daily Volume | 90-Day Raw | 1-Year (aggregated) |
|---|---|---|---|---|---|
| `telemetry_raw` | 10K rows/sec (1K robots) | ~120 bytes | ~103 GB/day | ~9.3 TB raw (before compression) | N/A (dropped after 90d) |
| `telemetry_raw` (compressed) | — | ~12 bytes (90% compression) | ~10.3 GB/day | ~930 GB | N/A |
| `telemetry_1min` | 16.6K rows/min (1K robots) | ~80 bytes | ~1.9 GB/day | N/A | ~700 GB |
| `telemetry_1hour` | 1K rows/hour | ~80 bytes | ~1.9 MB/day | N/A | ~700 MB |
| `task_history` | ~5K rows/day (1K robots) | ~500 bytes | ~2.5 MB/day | N/A | ~900 MB |
| All relational tables | Low | — | Negligible | — | < 1 GB total |

**At 100 robots:** Divide all numbers by 10. Total storage is well under 100 GB/year compressed.

**At 1,000 robots:** Total storage approximately 1 TB/year compressed for telemetry. This is well within a single PostgreSQL node with TimescaleDB.

---

## 9. Infrastructure

### 9.1 Cloud Provider Selection

| Factor | AWS | GCP | Self-Hosted |
|---|---|---|---|
| **IoT-specific services** | AWS IoT Core: managed MQTT broker with device shadows, certificate management, rules engine. Mature, used by major IoT companies. | GCP IoT Core: DISCONTINUED (Aug 2023). No replacement. | Full control but all responsibility. |
| **MQTT broker** | IoT Core (managed) OR self-hosted EMQX on ECS/EKS | Must self-host EMQX on GKE | Self-hosted EMQX |
| **Time-series database** | Timestream (managed) OR self-hosted TimescaleDB on RDS/EC2 | BigQuery (overkill) OR self-hosted TimescaleDB on GCE | Self-hosted TimescaleDB |
| **Object storage** | S3 (industry standard, cheapest at scale) | GCS (competitive) | MinIO |
| **CDN** | CloudFront (global edge, integrated with S3) | Cloud CDN | None without extra setup |
| **Container orchestration** | ECS Fargate (serverless containers, simpler) OR EKS (Kubernetes) | GKE Autopilot | Kubernetes (full ops burden) |
| **Managed PostgreSQL** | RDS for PostgreSQL (one-click, automated backups, read replicas) | Cloud SQL for PostgreSQL (good) | Manual PostgreSQL administration |
| **Redis managed** | ElastiCache (Redis or Valkey mode) | Memorystore (Redis) | Manual Redis ops |
| **Certificate management** | ACM (free TLS certs), IoT Core device certificates | Let's Encrypt + manual | Manual |
| **Cost at 100 robots** | ~$400-600/month | ~$350-550/month | ~$200-400/month (hardware) + ops time |
| **Cost at 1,000 robots** | ~$1,500-2,500/month | ~$1,400-2,300/month | ~$800-1,500/month (hardware) + significant ops time |

**Decision: AWS**

**Primary reasons:**

1. **AWS IoT Core as a complement to EMQX.** While we use EMQX as our primary MQTT broker (for the rule engine and flexibility), AWS IoT Core provides managed device certificate lifecycle management (issuance, rotation, revocation) and device shadows (last-known state) that reduce custom code. We can use IoT Core for device provisioning and certificate management while EMQX handles the real-time MQTT traffic.

2. **RDS for PostgreSQL with TimescaleDB.** RDS handles automated backups, point-in-time recovery, read replicas, and patching. TimescaleDB is available as an RDS extension. This eliminates database operations as a team responsibility.

3. **S3 + CloudFront** is the undisputed standard for large binary distribution (firmware). Pre-signed URLs, versioning, and edge caching are built-in.

4. **ECS Fargate** for running our Go services. No Kubernetes cluster to manage. Fargate charges per vCPU-second and GB-second, which is cost-effective for a small fleet. Migrate to EKS if complexity demands Kubernetes.

5. **Ecosystem maturity.** AWS has the deepest IoT ecosystem, the largest community of IoT engineers, and the most battle-tested services at scale. This matters for hiring and troubleshooting.

### 9.2 Infrastructure Topology

```
AWS REGION: us-east-1 (primary)
Future: eu-west-1 (when GDPR/European customers require it)

┌─────────────────────────────────────────────────────────────────────┐
│                          VPC (10.0.0.0/16)                           │
│                                                                      │
│  ┌─── Public Subnets (10.0.1.0/24, 10.0.2.0/24) ───┐              │
│  │                                                    │              │
│  │  ┌──────────────┐   ┌──────────────┐              │              │
│  │  │ ALB          │   │ NLB          │              │              │
│  │  │ (HTTP/HTTPS) │   │ (MQTT/TLS)   │              │              │
│  │  │ Port 443     │   │ Port 8883    │              │              │
│  │  └──────┬───────┘   └──────┬───────┘              │              │
│  │         │                   │                      │              │
│  └─────────┼───────────────────┼──────────────────────┘              │
│            │                   │                                     │
│  ┌─── Private Subnets (10.0.10.0/24, 10.0.11.0/24) ──┐             │
│  │         │                   │                       │             │
│  │  ┌──────▼───────┐   ┌──────▼───────┐               │             │
│  │  │ ECS Fargate  │   │ EMQX Cluster │               │             │
│  │  │              │   │              │               │             │
│  │  │ chorerobotics│   │ 2x nodes     │               │             │
│  │  │ -api         │   │ (ECS or EC2) │               │             │
│  │  │              │   │              │               │             │
│  │  │ Desired: 2   │   │ mTLS + WSS   │               │             │
│  │  │ Min: 1       │   │ + Rule Engine│               │             │
│  │  │ Max: 10      │   │              │               │             │
│  │  └──────┬───────┘   └──────┬───────┘               │             │
│  │         │                   │                       │             │
│  │  ┌──────▼───────────────────▼───────────────┐       │             │
│  │  │                                          │       │             │
│  │  │  ┌──────────────┐  ┌──────────────────┐  │       │             │
│  │  │  │ RDS          │  │ ElastiCache      │  │       │             │
│  │  │  │ PostgreSQL 17│  │ Redis 7.4        │  │       │             │
│  │  │  │ + TimescaleDB│  │                  │  │       │             │
│  │  │  │ + PostGIS    │  │ cache.r7g.large  │  │       │             │
│  │  │  │              │  │ (2 vCPU, 12GB)   │  │       │             │
│  │  │  │ db.r7g.large │  │                  │  │       │             │
│  │  │  │ (2 vCPU, 16GB│  │ Cluster mode: off│  │       │             │
│  │  │  │  Multi-AZ)   │  │ (single node     │  │       │             │
│  │  │  │              │  │  sufficient)      │  │       │             │
│  │  │  │ + Read       │  │                  │  │       │             │
│  │  │  │   Replica    │  │                  │  │       │             │
│  │  │  └──────────────┘  └──────────────────┘  │       │             │
│  │  │                                          │       │             │
│  │  └──────────────────────────────────────────┘       │             │
│  │                                                     │             │
│  └─────────────────────────────────────────────────────┘             │
│                                                                      │
│  ┌─── S3 (outside VPC) ───────────────────────────────┐             │
│  │                                                     │             │
│  │  chorerobotics-firmware (OTA binaries)              │             │
│  │  chorerobotics-backups  (DB backups)                │             │
│  │                                                     │             │
│  └─────────────────────────────────────────────────────┘             │
│                                                                      │
│  ┌─── CloudFront CDN ─────────────────────────────────┐             │
│  │                                                     │             │
│  │  Distribution for firmware.chorerobotics.com        │             │
│  │  Origin: chorerobotics-firmware S3 bucket           │             │
│  │  Edge caching for global firmware distribution      │             │
│  │                                                     │             │
│  └─────────────────────────────────────────────────────┘             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 10. Infrastructure Diagram

### 10.1 Full System Architecture (ASCII)

```
                                     CHOREROBOTICS BACKEND ARCHITECTURE
                                     ===================================

    ┌─────────────┐         ┌─────────────┐         ┌──────────────────┐
    │   ROBOT     │         │ MOBILE APP  │         │ INTERNAL         │
    │ (Jetson)    │         │ (Flutter)   │         │ DASHBOARD (Web)  │
    │             │         │             │         │                  │
    │ ROS2 + C/C++│         │ iOS/Android │         │ React + TypeScript│
    └──────┬──────┘         └──────┬──────┘         └────────┬─────────┘
           │                       │                          │
           │ mTLS (MQTT 5.0)       │ JWT (HTTPS)              │ JWT (HTTPS)
           │ Port 8883             │ Port 443                 │ Port 443
           │                       │ + MQTT/WSS               │ + MQTT/WSS
           │                       │   Port 8084              │   Port 8084
           │                       │                          │
    ───────┼───────────────────────┼──────────────────────────┼──────────
           │          CLOUD BOUNDARY (AWS VPC)                │
           │                       │                          │
           │                ┌──────▼──────┐                   │
           │                │    ALB      │◄──────────────────┘
           │                │ (HTTPS/443) │
           │                └──────┬──────┘
           │                       │
           │                ┌──────▼──────────────────────────────────┐
           │                │         GO API SERVER (ECS Fargate)      │
           │                │                                          │
           │                │  ┌────────┐ ┌────────┐ ┌─────────────┐  │
           │                │  │ Auth   │ │ Robot  │ │ Telemetry   │  │
           │                │  │Service │ │Service │ │ Query       │  │
           │                │  └────────┘ └────────┘ │ + WebSocket │  │
           │                │                        └─────────────┘  │
           │                │  ┌────────┐ ┌────────┐ ┌─────────────┐  │
           │                │  │Command │ │ Zone   │ │ Task        │  │
           │                │  │Service │ │Service │ │ Service     │  │
           │                │  └───┬────┘ └────────┘ └─────────────┘  │
           │                │      │                                   │
           │                │  ┌───┴────┐ ┌────────┐ ┌─────────────┐  │
           │                │  │ OTA    │ │Notif.  │ │ Weather     │  │
           │                │  │Service │ │Service │ │ Service     │  │
           │                │  └────────┘ └───┬────┘ └─────────────┘  │
           │                │                 │                        │
           │                │  ┌──────────────┴────────────────────┐   │
           │                │  │ Fleet Management Service          │   │
           │                │  └──────────────────────────────────-┘   │
           │                │                                          │
           │                └──────┬───────────────────┬──────────────┘
           │                       │                   │
           │                       │ SQL               │ Redis
    ┌──────▼──────┐         ┌──────▼──────┐     ┌─────▼──────────┐
    │ EMQX 5.8   │         │ PostgreSQL  │     │ Redis 7.4       │
    │ MQTT Broker │         │ 17          │     │ (ElastiCache)   │
    │             │         │             │     │                 │
    │ ┌─────────┐ │  Rule   │ + Timescale │     │ Robot state     │
    │ │ mTLS    │ │ Engine  │   DB 2.17   │     │ Session cache   │
    │ │ Auth    │ │────────>│ + PostGIS   │     │ Command streams │
    │ │         │ │ INSERT  │   3.5       │     │ Pub/Sub         │
    │ └─────────┘ │         │             │     │ Rate limits     │
    │ ┌─────────┐ │         │ Primary +   │     │                 │
    │ │ ACL per │ │         │ Read Replica│     │                 │
    │ │ device  │ │         │             │     │                 │
    │ └─────────┘ │         └─────────────┘     └─────────────────┘
    │ ┌─────────┐ │
    │ │ WSS     │ │
    │ │ Bridge  │ │◄──── Mobile App + Dashboard connect here
    │ └─────────┘ │       (MQTT over WebSocket)
    │             │
    └─────────────┘
           │
           │ Pre-signed URL for OTA download
           │
    ┌──────▼──────┐         ┌──────────────┐
    │ Amazon S3   │────────>│ CloudFront   │
    │             │         │ CDN          │
    │ Firmware    │         │              │
    │ binaries    │         │ Global edge  │
    │             │         │ distribution │
    └─────────────┘         └──────────────┘


    EXTERNAL SERVICES
    ─────────────────

    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
    │ Firebase     │    │OpenWeather  │    │ Stripe      │
    │ Cloud        │    │ Map API     │    │ Payments    │
    │ Messaging    │    │             │    │             │
    │ (FCM)        │    │ Forecast    │    │ Deposits    │
    │              │    │ data        │    │ + orders    │
    └─────────────┘    └─────────────┘    └─────────────┘
```

### 10.2 Data Flow Diagram

```
DATA FLOW: ROBOT TELEMETRY (10Hz)

Robot → [MQTT Publish QoS 0] → EMQX Broker
                                    │
                                    ├──[Rule Engine]──→ TimescaleDB INSERT
                                    │                   (telemetry.telemetry_raw)
                                    │
                                    ├──[Rule Engine]──→ Redis SET
                                    │                   (robot:{id}:state, TTL 300s)
                                    │
                                    └──[MQTT Forward]──→ App subscribers
                                                        (MQTT over WebSocket)


DATA FLOW: APP SENDS COMMAND

App → [HTTPS POST] → API Server (Command Service)
                          │
                          ├── Validate JWT
                          ├── Check command authority (cloud tier)
                          ├── Assign command UUID
                          ├── Store in PostgreSQL (command log)
                          │
                          └── [MQTT Publish QoS 1] → EMQX Broker
                                                        │
                                                        └── → Robot
                                                               (MQTT Subscribe)
                                                               │
                                                               └── [Execute + ACK]
                                                                    │
                                                                    └── MQTT Publish
                                                                        robot/{id}/commands/ack
                                                                        │
                                                                        └── → API Server
                                                                             (update command status)
                                                                             │
                                                                             └── → App
                                                                                  (WebSocket notification)


DATA FLOW: E-STOP (CLOUD PATH)

App → [HTTPS POST /robots/{id}/commands] → API Server
       body: {"type": "estop"}                │
                                              ├── NO queue, NO validation delay
                                              ├── Immediate MQTT publish QoS 1
                                              └── robot/{id}/commands/estop
                                                   │
                                                   └── → EMQX → Robot
                                                                 │
                                                                 ├── Kill all motor power
                                                                 ├── Engage brakes
                                                                 └── ACK within 500ms target


DATA FLOW: OTA UPDATE

Admin uploads firmware
    │
    └── API Server (OTA Service)
            │
            ├── Validate checksum + signature
            ├── Upload to S3
            ├── Create rollout record (PostgreSQL)
            │
            └── (When stage advances)
                │
                └── MQTT Publish to each target robot
                    robot/{id}/ota/deploy
                    {"version": "2.4.1", "manifest_url": "..."}
                        │
                        └── Robot receives notification
                            │
                            ├── Download manifest (HTTPS)
                            ├── Download binary (S3 pre-signed URL)
                            ├── Verify SHA-256 + Ed25519 signature
                            ├── Pre-install checks (battery, state)
                            ├── Install (A/B flash / dpkg / nv-l4t-update)
                            ├── Reboot
                            ├── Post-reboot health check
                            │
                            └── MQTT Publish status
                                robot/{id}/ota/status
                                {"state": "complete|rollback", ...}
                                    │
                                    └── OTA Service updates rollout counters
                                        (advance stage or halt)
```

---

## 11. Security Architecture

### 11.1 Authentication & Authorization

```
SECURITY LAYERS

Layer 1: Network
├── All traffic TLS 1.3 (no TLS 1.2 for new connections)
├── VPC with private subnets for all data stores
├── Security groups: least-privilege port access
└── WAF on ALB (OWASP Top 10 rules)

Layer 2: Identity
├── Mobile App / Dashboard
│   ├── JWT (RS256) access tokens (15-minute expiry)
│   ├── Refresh tokens (30-day expiry, single-use rotation)
│   ├── bcrypt password hashing (cost=12)
│   └── Optional: TOTP 2FA for admin accounts
│
├── Robot
│   ├── mTLS (mutual TLS) with device certificates
│   ├── Certificate CN = robot serial number
│   ├── Certificates issued by private CA (AWS Private CA or self-managed)
│   ├── Certificate rotation: annual, automated
│   └── Certificate revocation: CRL published, checked by EMQX
│
└── Internal Dashboard (admin)
    ├── Same JWT system with "admin" role
    ├── IP allowlist for admin endpoints
    └── Audit log for all admin actions

Layer 3: Authorization
├── RBAC (Role-Based Access Control)
│   ├── owner: full control of their robots
│   ├── household: control robots, cannot delete zones or change settings
│   ├── guest: view-only telemetry, no commands
│   └── admin: fleet management, OTA deployment, user management
│
├── Resource ownership enforcement
│   └── User can only access robots they own (enforced at SQL query level)
│
└── Command authority (cloud tier)
    └── Joystick and blade commands rejected if connection is cloud mode

Layer 4: Data Protection
├── Encryption at rest: RDS encryption (AES-256), S3 encryption (SSE-S3)
├── Encryption in transit: TLS 1.3 everywhere
├── PII minimization: only collect necessary user data
├── Soft deletes: user data retained 30 days after deletion request, then purged
└── Database backups encrypted with AWS KMS customer-managed key
```

### 11.2 Device Provisioning Flow

```
MANUFACTURING → CLOUD REGISTRATION → FIELD DEPLOYMENT

1. Manufacturing Line:
   ├── Generate ECDSA P-256 keypair on secure element (if available)
   │   or in Jetson's TEE (Trusted Execution Environment)
   ├── Create CSR (Certificate Signing Request) with CN = serial number
   ├── Submit CSR to cloud provisioning API
   ├── Cloud CA signs certificate (valid 2 years)
   ├── Download signed certificate + CA bundle
   ├── Flash to robot:
   │   ├── /etc/chorerobotics/certs/device.pem   (signed cert)
   │   ├── /etc/chorerobotics/certs/device.key    (private key, 0600 perms)
   │   ├── /etc/chorerobotics/certs/ca-bundle.pem (CA chain)
   │   └── /etc/chorerobotics/certs/ota-pubkey.pem (Ed25519 OTA verification key)
   ├── Generate random 6-digit pairing code
   ├── Store pairing code in cloud database + on robot display/label
   └── Robot status: "provisioned"

2. User Pairing:
   ├── User opens app, scans BLE for robot
   ├── App reads robot serial from BLE advertisement
   ├── User enters 6-digit pairing code (displayed on robot)
   ├── App calls: POST /api/v1/robots/register
   │   body: {"serial_number": "CR-MK1-00001", "pairing_code": "482917"}
   ├── Backend verifies pairing code
   ├── Backend associates robot with user account
   ├── Robot status: "paired"
   ├── Pairing code invalidated (one-time use)
   └── Robot connects to EMQX with mTLS, starts publishing telemetry

3. Certificate Rotation (annual):
   ├── 30 days before expiry: cloud pushes new CSR request via MQTT
   ├── Robot generates new keypair + CSR
   ├── Robot submits CSR via MQTT (encrypted payload)
   ├── Cloud CA signs new certificate
   ├── Cloud pushes signed certificate via MQTT
   ├── Robot installs new certificate, restarts MQTT connection
   └── Old certificate added to CRL after grace period
```

---

## 12. Observability

### 12.1 Monitoring Stack

| Component | Tool | Purpose |
|---|---|---|
| **Metrics** | Prometheus + Grafana (or AWS CloudWatch) | System metrics, custom business metrics |
| **Logging** | Structured JSON logs (zap) + CloudWatch Logs | Centralized log aggregation |
| **Tracing** | OpenTelemetry + AWS X-Ray (or Jaeger) | Distributed request tracing |
| **Alerting** | Grafana Alerting or PagerDuty | On-call notifications |
| **Uptime** | AWS Route 53 health checks + external monitoring (Uptime Robot) | External endpoint monitoring |

### 12.2 Key Metrics and Alerts

| Metric | Source | Warning Threshold | Critical Threshold |
|---|---|---|---|
| API response time (p95) | Go instrumentation | > 200ms | > 500ms |
| API error rate (5xx) | ALB metrics | > 1% | > 5% |
| MQTT connected clients | EMQX metrics | N/A | Drop > 20% in 5 min |
| Telemetry ingestion rate | TimescaleDB | Drop > 30% | Drop > 60% |
| Database connection pool | pgx metrics | > 80% utilized | > 95% utilized |
| Database replication lag | RDS metrics | > 1 second | > 10 seconds |
| Redis memory usage | ElastiCache metrics | > 70% | > 90% |
| E-Stop command latency | Custom metric | > 200ms | > 500ms |
| OTA rollout failure rate | Custom metric | > 2% per stage | > 5% per stage |
| Robot offline count | Heartbeat monitor | > 5% of fleet | > 15% of fleet |
| S3 firmware download errors | CloudWatch | > 1% | > 5% |
| Certificate expiry | Custom check | < 30 days | < 7 days |

### 12.3 Dashboards

| Dashboard | Audience | Content |
|---|---|---|
| **System Health** | Engineering | API latency, error rates, DB performance, queue depths |
| **Fleet Overview** | Operations | Online/offline count, geographic distribution, firmware versions |
| **Telemetry Pipeline** | Engineering | Ingestion rate, compression ratio, storage growth, query performance |
| **OTA Rollout** | Engineering + Operations | Rollout status, per-stage success/failure, rollback events |
| **Security** | Engineering | Failed auth attempts, certificate issues, rate limit hits |

---

## 13. Cost Estimates

### 13.1 At 100 Robots (Year 1 Launch)

| Service | Specification | Monthly Cost |
|---|---|---|
| **ECS Fargate** (API) | 2x tasks, 0.5 vCPU, 1GB RAM each | $30 |
| **ECS Fargate** (EMQX) | 2x tasks, 1 vCPU, 2GB RAM each | $60 |
| **RDS PostgreSQL** | db.t4g.medium (2 vCPU, 4GB), Multi-AZ | $130 |
| **RDS Read Replica** | db.t4g.medium | $65 |
| **ElastiCache Redis** | cache.t4g.medium (2 vCPU, 3GB) | $50 |
| **S3** | ~50GB firmware + backups | $2 |
| **CloudFront** | ~500GB/month data transfer (OTA) | $45 |
| **ALB** | 1 ALB + LCU hours | $25 |
| **NLB** | 1 NLB for MQTT | $18 |
| **Data transfer** | ~200GB/month outbound | $18 |
| **CloudWatch** | Logs + metrics | $15 |
| **Route 53** | DNS | $2 |
| **AWS Certificate Manager** | Public TLS certs | $0 |
| **AWS KMS** | 1 key for DB encryption, 1 for OTA signing | $2 |
| **OpenWeatherMap API** | ~300 calls/day | $0 (free tier) |
| **Firebase (FCM)** | Push notifications | $0 (free tier) |
| **Stripe** | Payment processing (variable, per transaction) | ~$50 |
| | | |
| **TOTAL** | | **~$512/month** |

### 13.2 At 1,000 Robots (Year 2)

| Service | Specification | Monthly Cost |
|---|---|---|
| **ECS Fargate** (API) | 4x tasks, 1 vCPU, 2GB RAM each | $120 |
| **ECS Fargate** (EMQX) | 3x tasks, 2 vCPU, 4GB RAM each | $180 |
| **RDS PostgreSQL** | db.r7g.large (2 vCPU, 16GB), Multi-AZ | $420 |
| **RDS Read Replica** | db.r7g.large | $210 |
| **ElastiCache Redis** | cache.r7g.large (2 vCPU, 12GB) | $200 |
| **S3** | ~500GB firmware + backups + telemetry exports | $12 |
| **CloudFront** | ~5TB/month (fleet-wide OTA) | $400 |
| **ALB** | 1 ALB + higher LCU | $40 |
| **NLB** | 1 NLB for MQTT | $25 |
| **Data transfer** | ~2TB/month outbound | $180 |
| **CloudWatch** | Logs + metrics (higher volume) | $60 |
| **Route 53** | DNS | $2 |
| **KMS** | Same | $2 |
| **OpenWeatherMap API** | ~3000 calls/day | $45 (paid tier) |
| **Firebase (FCM)** | Push notifications | $0 |
| **Stripe** | Variable | ~$200 |
| | | |
| **TOTAL** | | **~$2,096/month** |

### 13.3 Cost Optimization Notes

1. **Reserved Instances** for RDS and ElastiCache save 30-40% with 1-year commitment. At 1,000 robots, this saves ~$300/month.

2. **TimescaleDB compression** reduces storage by 90%, keeping disk costs minimal even at scale.

3. **EMQX rule engine** eliminates a separate telemetry ingestion service, saving 2 additional Fargate tasks (~$60-120/month).

4. **CloudFront caching** for OTA means each firmware binary is downloaded from S3 once per edge location, not once per robot. This dramatically reduces S3 request costs during fleet-wide rollouts.

5. **Fargate Spot** can be used for non-critical batch tasks (telemetry aggregation, report generation) at 70% discount.

---

## 14. API Endpoint Reference

### 14.1 Auth Endpoints

```
POST   /api/v1/auth/register            Register new user account
POST   /api/v1/auth/login               Login (email + password → JWT)
POST   /api/v1/auth/refresh             Refresh JWT access token
POST   /api/v1/auth/logout              Revoke refresh token
POST   /api/v1/auth/forgot-password     Request password reset email
POST   /api/v1/auth/reset-password      Reset password with token
GET    /api/v1/auth/me                  Get current user profile
PUT    /api/v1/auth/me                  Update user profile
DELETE /api/v1/auth/me                  Delete user account (soft delete)
```

### 14.2 Robot Endpoints

```
POST   /api/v1/robots/register              Register robot to user account (pairing)
GET    /api/v1/robots                        List user's robots
GET    /api/v1/robots/{id}                   Get robot details
PUT    /api/v1/robots/{id}                   Update robot (name, settings)
DELETE /api/v1/robots/{id}                   Unpair robot from account
GET    /api/v1/robots/{id}/status            Get current robot status (from Redis cache)
POST   /api/v1/robots/{id}/commands          Send command to robot
GET    /api/v1/robots/{id}/commands          List recent commands + status
```

### 14.3 Telemetry Endpoints

```
GET    /api/v1/robots/{id}/telemetry         Query telemetry data
       ?from=2026-03-17T00:00:00Z
       &to=2026-03-17T23:59:59Z
       &resolution=raw|1min|1hour
       &fields=battery_percent,speed_ms      (optional field filter)
       &format=json|csv

WSS    /ws/telemetry/{robot_id}              Live telemetry WebSocket stream
```

### 14.4 Zone Endpoints

```
POST   /api/v1/robots/{id}/zones             Create zone
GET    /api/v1/robots/{id}/zones             List zones for robot
GET    /api/v1/robots/{id}/zones/{zone_id}   Get zone detail
PUT    /api/v1/robots/{id}/zones/{zone_id}   Update zone
DELETE /api/v1/robots/{id}/zones/{zone_id}   Delete zone
POST   /api/v1/robots/{id}/zones/sync        Trigger zone sync to robot
```

### 14.5 Task & Schedule Endpoints

```
POST   /api/v1/robots/{id}/schedules          Create schedule
GET    /api/v1/robots/{id}/schedules          List schedules
PUT    /api/v1/robots/{id}/schedules/{sid}    Update schedule
DELETE /api/v1/robots/{id}/schedules/{sid}    Delete schedule
PATCH  /api/v1/robots/{id}/schedules/{sid}    Toggle enable/disable

GET    /api/v1/robots/{id}/tasks/history      List task history
       ?from=&to=&type=mow|plow|collect&page=&per_page=
GET    /api/v1/robots/{id}/tasks/history/{tid} Get task detail
GET    /api/v1/robots/{id}/tasks/analytics    Task analytics
       ?from=&to=&granularity=day|week|month
       Response: { area_total_sqm, task_count, avg_duration_sec,
                   avg_battery_used_pct, by_type: {...} }
```

### 14.6 OTA Endpoints

```
POST   /api/v1/ota/firmware                   Upload firmware (admin only)
       Content-Type: multipart/form-data
       Fields: binary (file), manifest (JSON)
GET    /api/v1/ota/firmware                   List firmware versions
GET    /api/v1/ota/firmware/{id}              Get firmware detail

POST   /api/v1/ota/rollouts                   Create rollout (admin only)
GET    /api/v1/ota/rollouts                   List rollouts
GET    /api/v1/ota/rollouts/{id}              Get rollout detail + per-robot status
POST   /api/v1/ota/rollouts/{id}/advance      Advance rollout to next stage
POST   /api/v1/ota/rollouts/{id}/halt         Halt rollout
POST   /api/v1/ota/rollouts/{id}/rollback     Rollback rollout

GET    /api/v1/ota/check                      Robot checks for available update
       Headers: X-Robot-Serial, X-Current-Firmware-Version,
                X-Current-ROS2-Version, X-Hardware-Model
       Response: { update_available: bool, updates: [{type, version, manifest_url}] }
```

### 14.7 Notification Endpoints

```
POST   /api/v1/notifications/fcm-token        Register FCM token
DELETE /api/v1/notifications/fcm-token         Remove FCM token
GET    /api/v1/notifications/preferences       Get notification preferences
PUT    /api/v1/notifications/preferences       Update notification preferences
GET    /api/v1/notifications/history           List past notifications
       ?page=&per_page=
POST   /api/v1/notifications/{id}/read         Mark notification as read
```

### 14.8 Weather Endpoints

```
GET    /api/v1/weather/forecast                Get forecast for user's location
       ?lat=33.684&lng=-73.047
       Response: { current: {...}, hourly: [...], daily: [...],
                   schedule_recommendations: [{schedule_id, action: "skip", reason: "rain"}] }
```

### 14.9 Order Endpoints

```
POST   /api/v1/orders/configure                Submit robot configuration + pricing
POST   /api/v1/orders/reserve                  Place reservation with payment
GET    /api/v1/orders                           List user's orders
GET    /api/v1/orders/{id}                      Get order detail
```

### 14.10 Fleet Management Endpoints (Admin Only)

```
GET    /api/v1/admin/fleet                      All robots overview
       ?status=active|offline&model=&firmware_version=&page=&per_page=
GET    /api/v1/admin/fleet/{robot_id}           Robot detail (admin view)
GET    /api/v1/admin/fleet/stats                Fleet statistics
       Response: { total, online, offline, by_status: {...},
                   by_firmware: {...}, by_model: {...} }
GET    /api/v1/admin/fleet/map                  All robot locations
GET    /api/v1/admin/users                      List all users
GET    /api/v1/admin/users/{id}                 User detail (admin view)
GET    /api/v1/admin/audit-log                  Audit log
       ?admin_id=&action=&from=&to=&page=&per_page=
```

---

## 15. Deployment Strategy

### 15.1 CI/CD Pipeline

```
GitHub Repository
      │
      └── Push to main / PR merge
            │
            ├── GitHub Actions CI
            │   ├── go vet / golangci-lint
            │   ├── go test ./... (unit + integration tests)
            │   ├── sqlc verify (SQL correctness)
            │   ├── protoc compile check
            │   └── docker build (multi-stage, scratch base)
            │
            ├── Build Docker image
            │   ├── FROM golang:1.24 AS builder
            │   ├── CGO_ENABLED=0 go build -o server
            │   ├── FROM scratch
            │   ├── COPY server /server
            │   └── Image size: ~20MB
            │
            ├── Push to ECR
            │
            └── Deploy
                ├── Staging environment (always, on every push to main)
                │   ├── Run integration tests against staging
                │   ├── Run smoke tests (health check, auth flow, MQTT connect)
                │   └── Manual approval gate for production
                │
                └── Production (after approval)
                    ├── ECS rolling update (minimum healthy 50%)
                    ├── Blue/green deployment via ECS
                    ├── Health check: /healthz returns 200
                    ├── If health check fails: automatic rollback
                    └── Post-deploy: run canary tests
```

### 15.2 Database Migrations

```
Migration Strategy: golang-migrate with sequential numbered migrations

migrations/
├── 000001_create_users.up.sql
├── 000001_create_users.down.sql
├── 000002_create_robots.up.sql
├── 000002_create_robots.down.sql
├── 000003_create_zones.up.sql
├── ...

Deployment:
1. Migrations run BEFORE application deployment
2. Migrations must be backwards compatible (old code must work with new schema)
3. Destructive changes (column drops) happen in 3 phases:
   Phase 1: Stop writing to column (code deploy)
   Phase 2: Drop column (migration, next deploy cycle)
   Phase 3: Remove column references from code (cleanup)
4. Tested in staging before production
5. Rollback: apply .down.sql migrations (tested in CI)
```

### 15.3 Environment Configuration

```
Environments:
├── local       → Docker Compose (PostgreSQL, Redis, EMQX, MinIO)
├── staging     → AWS (scaled down: t4g.small instances, single-AZ)
└── production  → AWS (full spec: Multi-AZ, read replicas, autoscaling)

Configuration: Viper reads from:
1. Environment variables (12-factor, production)
2. .env file (local development)
3. AWS Secrets Manager (database passwords, API keys)
```

---

## 16. Disaster Recovery

### 16.1 Backup Strategy

| Data Store | Backup Method | Frequency | Retention | RTO | RPO |
|---|---|---|---|---|---|
| PostgreSQL | RDS automated backup + manual snapshots | Continuous (point-in-time), daily snapshot | 7 days PITR, 30 days snapshots | 15 minutes | 5 minutes |
| Redis | ElastiCache daily backup | Daily | 7 days | 30 minutes | 24 hours (cache rebuild acceptable) |
| S3 (firmware) | S3 versioning + cross-region replication | Continuous | Indefinite | 0 (always available) | 0 |
| EMQX config | Infrastructure as Code (Terraform) | On every change | Git history | 15 minutes (redeploy) | 0 |

### 16.2 Failure Scenarios

| Scenario | Impact | Mitigation | Recovery |
|---|---|---|---|
| API server crash | App cannot send commands or fetch data | ECS auto-restart + multiple tasks | < 30 seconds (container restart) |
| EMQX broker failure | Robots lose cloud connection, no telemetry | 2-node cluster, client reconnect with backoff | < 60 seconds (failover to healthy node) |
| PostgreSQL primary failure | All writes fail | Multi-AZ automatic failover | < 2 minutes (RDS failover) |
| Redis failure | Stale robot state, session loss | App gracefully degrades (fetch from DB) | < 5 minutes (ElastiCache recovery) |
| S3 outage | OTA downloads fail | CDN cache serves recent files. Retry with backoff. | S3 has 99.99% availability SLA |
| Full region outage | Everything down | DNS failover to disaster recovery region (future) | 1-4 hours (manual regional failover) |

### 16.3 Robot Resilience (When Cloud is Down)

The robot is designed to operate independently of the cloud:

1. **BLE and LAN modes continue working.** The app can control the robot directly via BLE or WiFi LAN when the cloud is unreachable.
2. **Scheduled tasks execute locally.** The robot stores its schedule locally. Cloud sync is periodic, not required for execution.
3. **Safety systems are fully local.** E-Stop (physical button), boundary geofencing, obstacle avoidance, and all safety controllers run on the robot hardware with zero cloud dependency.
4. **Telemetry is buffered.** If MQTT connection is lost, the robot buffers telemetry in local storage and uploads when connectivity is restored (up to 1 hour of buffered data).
5. **OTA updates are deferred.** If a download is interrupted, the robot retries with exponential backoff. Partial downloads resume from where they stopped (HTTP Range requests against S3).

---

## Appendix A: Go Project Structure

```
chorerobotics-backend/
├── cmd/
│   └── server/
│       └── main.go                  # Application entrypoint
│
├── internal/
│   ├── auth/
│   │   ├── handler.go               # HTTP handlers
│   │   ├── service.go               # Business logic
│   │   ├── repository.go            # Database access (generated by sqlc)
│   │   └── jwt.go                   # JWT utilities
│   │
│   ├── robot/
│   │   ├── handler.go
│   │   ├── service.go
│   │   └── repository.go
│   │
│   ├── telemetry/
│   │   ├── handler.go
│   │   ├── service.go
│   │   ├── repository.go
│   │   └── websocket.go             # WebSocket handler for live telemetry
│   │
│   ├── command/
│   │   ├── handler.go
│   │   ├── service.go
│   │   ├── mqtt.go                  # MQTT publish/subscribe logic
│   │   └── authority.go             # Command tier enforcement
│   │
│   ├── zone/
│   │   ├── handler.go
│   │   ├── service.go
│   │   └── repository.go
│   │
│   ├── task/
│   │   ├── handler.go
│   │   ├── service.go
│   │   └── repository.go
│   │
│   ├── ota/
│   │   ├── handler.go
│   │   ├── service.go
│   │   ├── repository.go
│   │   ├── rollout.go               # Rollout state machine
│   │   └── s3.go                    # S3 upload/pre-signed URL
│   │
│   ├── notification/
│   │   ├── handler.go
│   │   ├── service.go
│   │   └── fcm.go                   # Firebase Cloud Messaging client
│   │
│   ├── weather/
│   │   ├── handler.go
│   │   ├── service.go
│   │   └── openweathermap.go        # External API client
│   │
│   ├── fleet/
│   │   ├── handler.go
│   │   └── service.go
│   │
│   └── platform/
│       ├── config/
│       │   └── config.go            # Viper configuration
│       ├── database/
│       │   └── postgres.go          # pgx connection pool
│       ├── cache/
│       │   └── redis.go             # Redis client
│       ├── mqtt/
│       │   └── client.go            # Paho MQTT client wrapper
│       ├── middleware/
│       │   ├── auth.go              # JWT middleware
│       │   ├── ratelimit.go         # Rate limiting middleware
│       │   ├── logging.go           # Request logging
│       │   └── cors.go              # CORS configuration
│       └── errors/
│           └── errors.go            # Custom error types
│
├── db/
│   ├── migrations/                  # golang-migrate SQL files
│   ├── queries/                     # sqlc SQL query files
│   └── sqlc.yaml                    # sqlc configuration
│
├── proto/                           # Protocol buffer definitions (if needed later)
│
├── deployments/
│   ├── docker/
│   │   ├── Dockerfile               # Multi-stage Go build
│   │   └── docker-compose.yml       # Local development stack
│   ├── terraform/                   # Infrastructure as Code
│   │   ├── main.tf
│   │   ├── ecs.tf
│   │   ├── rds.tf
│   │   ├── elasticache.tf
│   │   ├── s3.tf
│   │   ├── cloudfront.tf
│   │   └── variables.tf
│   └── k8s/                         # Kubernetes manifests (future)
│
├── scripts/
│   ├── migrate.sh                   # Run database migrations
│   ├── seed.sh                      # Seed development data
│   └── gen-certs.sh                 # Generate development mTLS certificates
│
├── go.mod
├── go.sum
└── Makefile
```

---

## Appendix B: Local Development (Docker Compose)

```yaml
# docker-compose.yml (local development)
version: "3.9"

services:
  postgres:
    image: timescale/timescaledb-ha:pg17
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: chorerobotics
      POSTGRES_PASSWORD: localdev
      POSTGRES_DB: chorerobotics
    volumes:
      - pg_data:/var/lib/postgresql/data
    command: >
      postgres
      -c shared_preload_libraries='timescaledb'

  redis:
    image: redis:7.4-alpine
    ports:
      - "6379:6379"

  emqx:
    image: emqx/emqx:5.8
    ports:
      - "1883:1883"     # MQTT
      - "8883:8883"     # MQTT/TLS
      - "8083:8083"     # MQTT/WS
      - "8084:8084"     # MQTT/WSS
      - "18083:18083"   # Dashboard
    environment:
      EMQX_NAME: emqx
      EMQX_HOST: 127.0.0.1

  minio:
    image: minio/minio:latest
    ports:
      - "9000:9000"
      - "9001:9001"     # Console
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data

volumes:
  pg_data:
  minio_data:
```

---

## Appendix C: Technology Decision Summary

| Decision Area | Choice | Version | Alternatives Rejected |
|---|---|---|---|
| Language | Go | 1.24.1 | Rust (hiring), Python (GIL), Node (safety), Elixir (hiring) |
| HTTP Router | chi | v5 | Gin (less stdlib-compatible), Echo, Fiber |
| SQL Codegen | sqlc | 1.27 | GORM (runtime reflection), sqlx (less type-safe) |
| DB Driver | pgx | v5 | database/sql + lib/pq (less performant) |
| Migrations | golang-migrate | v4 | goose, atlas |
| Relational DB | PostgreSQL | 17 | MySQL (weaker JSON/PostGIS) |
| Time-Series DB | TimescaleDB | 2.17 | InfluxDB (separate system), ClickHouse (overkill), QuestDB |
| Geospatial | PostGIS | 3.5 | MongoDB GeoJSON (separate system) |
| Cache/Pub-Sub | Redis | 7.4 | Valkey (API-compatible backup plan), KeyDB |
| Object Storage | Amazon S3 | — | MinIO (self-hosted), local filesystem |
| MQTT Broker | EMQX | 5.8 (OSS) | Mosquitto (no clustering), HiveMQ (expensive), VerneMQ |
| Cloud Provider | AWS | — | GCP (no IoT Core), self-hosted (ops burden) |
| Container Runtime | ECS Fargate | — | EKS (over-engineered for <10 services), EC2 (ops burden) |
| CDN | CloudFront | — | Cloudflare (also good, but CloudFront integrates with S3) |
| Push Notifications | Firebase (FCM) | — | OneSignal (vendor lock-in), SNS (less feature-rich) |
| Weather API | OpenWeatherMap | 3.0 | WeatherAPI, AccuWeather (more expensive) |
| Payments | Stripe | — | — |
| Logging | zap | 1.27 | zerolog (also good), logrus (slower) |
| Observability | OpenTelemetry | 1.32 | Datadog (expensive), custom instrumentation |
