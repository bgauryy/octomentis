# High-Signal Strings — Cursor.app Audit

## Hardcoded Keys & Secrets

| String | Type | Location |
|--------|------|----------|
| `KbZUR41cY7W6zRSdpSUJ7I7mLYBKOCmB` | Statsig SDK key | workbench:4223979 |
| `80ec2259ebfad12d8aa2afe6eb4f6dd5` | Sentry auth (metrics.cursor.sh) | main:99800, workbench:564100 |
| `0a7b82d23ca5f4635708bc8e9957e4bd` | Sentry auth (US ingest) | main:99800, workbench:564100 |
| `c1dfb07d783ad5325c245c1fd3725390` | Sentry key (browser check) | workbench:36682000 |
| `d5c0e77a0214208f36b56d42e8e787de88d02ea4` | Distro hash | package.json |
| `a80ff7dfcaa45d7750f6e30be457261379c29b00` | Internal sourcemap commit | main:317 |

## Cursor API Endpoints

| Endpoint | Purpose | Source |
|----------|---------|--------|
| `https://cursor.com` | Main site | workbench:4223400 |
| `https://api2.cursor.sh` | Core API | workbench:4223400 |
| `https://api3.cursor.sh` | Cursor Tab | workbench:4223500 |
| `https://api4.cursor.sh` | Cursor Tab (regional) | workbench:4223600 |
| `https://agent.api5.cursor.sh` | Agent API | workbench:4223700 |
| `https://agentn.api5.cursor.sh` | Agent N | workbench:4223750 |
| `https://agent-gcpp-uswest.api5.cursor.sh` | Agent GCP US West | workbench:4223800 |
| `https://agentn-gcpp-uswest.api5.cursor.sh` | Agent N GCP US West | workbench:4223850 |
| `https://agentn-gcpp-eucentral.api5.cursor.sh` | Agent N GCP EU Central | workbench:4223900 |
| `https://agentn-gcpp-apsoutheast.api5.cursor.sh` | Agent N GCP AP Southeast | workbench:4223950 |
| `https://repo42.cursor.sh` | Codebase indexing | workbench:4223700 |
| `https://prod.authentication.cursor.sh` | Auth service | workbench:4224020 |
| `https://api2.cursor.sh/extensions-control` | Extension control | product.json |
| `https://api2.cursor.sh/updates` | Update check | product.json |
| `https://api3.cursor.sh/tev1/v1` | Telemetry v1 | product.json |
| `https://metrics.cursor.sh` | Sentry relay | main:99800 |

## Staging/Dev Endpoints

| Endpoint | Location |
|----------|----------|
| `https://dev-staging.cursor.sh` | workbench |
| `https://staging.cursor.sh` | workbench |
| `https://staging-marketplace.cursor.sh` | workbench |
| `http://localhost:3000/sse` | workbench (MCP dev) |
| `http://localhost:4000` | workbench (dev) |

## Third-Party Services

| Endpoint | Service | Purpose |
|----------|---------|---------|
| `https://api.statsigcdn.com/v1` | Statsig | Feature flag config |
| `https://featureassets.org/v1` | Statsig | Feature assets |
| `https://prodregistryv2.org/v1` | Statsig | Registration |
| `https://statsigapi.net/v1/sdk_exception` | Statsig | Exception reporting |
| `https://o4504648565915648.ingest.us.sentry.io` | Sentry | Error reporting |
| `https://o447951.ingest.sentry.io` | Sentry | Error reporting |
| `https://api.openai.com/v1` | OpenAI | AI inference |
| `https://api.github.com/copilot_internal/*` | GitHub | Copilot integration |
| `https://app.datadoghq.com/` | Datadog | Monitoring |
| `https://marketplace.visualstudio.com` | Microsoft | VS Marketplace |
| `https://open-vsx.org` | Eclipse | Open VSX |

## Internal/Debug Strings

| String | Type | Location |
|--------|------|----------|
| `https://www.notion.so/cursorai/Ryo-s-Journal-161da74ef045007ac1bf36660e08e4a4` | Internal Notion page | workbench:30035609 |
| `http://go/debugdata` | Internal shortlink | main:135 |
| `http://go/sourcemap/sourcemaps/a80ff7df.../core/main.js.map` | Internal shortlink | main:317 |
| `https://cursor.blob.core.windows.net/remote-releases/` | Azure Blob Storage | product.json |

## MCP Integration Endpoints (product.json)

| Endpoint | Service |
|----------|---------|
| `https://mcp.asana.com` | Asana |
| `https://mcp.atlassian.com` | Atlassian |
| `https://mcp.context7.com` | Context7 |
| `https://mcp.figma.com` | Figma |
| `https://mcp.intercom.com` | Intercom |
| `https://mcp.linear.app` | Linear |
| `https://mcp.notion.com` | Notion |
| `https://mcp.prisma.io` | Prisma |
| `https://mcp.sentry.dev` | Sentry |
| `https://mcp.squareup.com` | Square |
