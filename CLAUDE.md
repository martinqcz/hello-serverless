# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a serverless full-stack application designed for AWS Lambda deployment with two main components:

- **hello-backend**: Micronaut 4.10.6 Kotlin backend (AWS Lambda function)
- **hello-frontend**: Vue 3 + Vuetify 3 frontend application

## Backend (hello-backend)

### Technology Stack
- Micronaut 4.10.6 framework
- Kotlin 1.9.25 with Java 21
- AWS Lambda with API Gateway proxy
- DynamoDB for data persistence
- GraalVM native image support
- Gradle build system with KSP (Kotlin Symbol Processing)

### Project Structure
- `src/main/kotlin/com/qapil/hello/`
  - `api/` - REST controllers (e.g., HomeController.kt)
  - `dynamodb/` - DynamoDB repository and configuration
  - `Application.kt` - Main application entry point
  - `DevBootstrap.kt` - Development initialization
- `src/main/resources/application.yml` - Micronaut configuration
- `build.gradle.kts` - Build configuration

### Common Commands

Run locally:
```bash
cd hello-backend
./gradlew run
```

Run tests:
```bash
cd hello-backend
./gradlew test
```

Build standard Lambda JAR:
```bash
cd hello-backend
./gradlew shadowJar
```

Build GraalVM native Lambda (requires Docker):
```bash
cd hello-backend
./gradlew buildNativeLambda -Pmicronaut.runtime=lambda_provided
```

Clean build:
```bash
cd hello-backend
./gradlew clean build
```

### AWS Lambda Configuration
- Handler: `io.micronaut.function.aws.proxy.payload1.ApiGatewayProxyRequestEventFunction`
- Runtime: Java 21 (standard) or provided.al2 (GraalVM native)
- The backend uses API Gateway proxy integration

### Key Configuration
- DynamoDB table name configured in `application.yml` under `dynamodb.table-name`
- Test resources automatically spin up LocalStack DynamoDB for tests
- Controllers are under `/api/v1` base path

## Frontend (hello-frontend)

### Technology Stack
- Vue 3 with TypeScript
- Vuetify 3 (Material Design components)
- Pinia for state management with persistence
- Vue Router with file-based routing (unplugin-vue-router)
- Vue I18n for internationalization
- Vite build tool
- Axios for HTTP requests

### Project Structure
- `src/pages/` - Auto-routed page components
- `src/layouts/` - Layout templates
- `src/components/` - Reusable Vue components
- `src/stores/` - Pinia store definitions
- `src/plugins/` - Vue plugins (vuetify, i18n, router)
- `src/i18n/` - Internationalization files
- `src/styles/` - Global styles and Vuetify settings

### Common Commands

Install dependencies:
```bash
cd hello-frontend
bun install
```

Run development server (http://localhost:3000):
```bash
cd hello-frontend
bun dev
```

Type check:
```bash
cd hello-frontend
bun type-check
```

Lint and fix:
```bash
cd hello-frontend
bun lint
```

Build for production:
```bash
cd hello-frontend
bun run build
```

Preview production build:
```bash
cd hello-frontend
bun preview
```

### Development Features
- Hot Module Replacement (HMR) via Vite
- Auto-import for Vue composables, Pinia, and components
- File-based routing (pages in `src/pages/` become routes automatically)
- Dev server proxy: `/api` requests proxy to `http://127.0.0.1:8080` (backend)

### Important Configuration
- Vite config: `vite.config.mts`
- TypeScript configs: `tsconfig.json`, `tsconfig.app.json`, `tsconfig.node.json`
- ESLint config: `eslint.config.js`
- API proxy configured to backend at localhost:8080

### API Calls
- Centralized axios instance configured in `src/plugins/axios.ts`
- Base URL configured via `VITE_API_BASE_URL` environment variable (`.env`, `.env.production`)
- Import API client: `import { api } from '@/plugins'`
- Make requests: `api.get('/v1/endpoint')`, `api.post('/v1/endpoint', data)`
- Base URL is automatically prepended (e.g., `/v1/hello` → `/api/v1/hello`)
- Development: Vite proxy forwards `/api` to `http://127.0.0.1:8080`
- Production: CloudFront routes `/api` to API Gateway

## Architecture Notes

### Frontend-Backend Communication
- Frontend dev server (port 3000) proxies `/api/*` requests to backend (port 8080)
- Backend exposes REST endpoints under `/api/v1` prefix
- Production deployment likely serves frontend from S3/CloudFront with API Gateway backend

### DynamoDB Integration
- Backend uses AWS SDK v2 for DynamoDB
- Custom configuration for local development (DynamoDbClientBuilderListener)
- TestContainers with LocalStack for integration tests
- Repository pattern in `dynamodb/DynamoRepository.kt`

### Lambda Deployment Options
1. **Standard JVM**: Faster cold starts improvement via AOT, larger package size (~50MB)
2. **GraalVM Native**: Ultra-fast cold starts, smaller package (~15MB), longer build time

### State Management
- Frontend uses Pinia with persisted state plugin
- Store modules in `src/stores/`
- App-wide state in `src/stores/app.ts`

## Development Workflow

1. Start backend: `cd hello-backend && ./gradlew run --continuous`
2. Start frontend: `cd hello-frontend && bun dev`
3. Access application at http://localhost:3000
4. Backend API available at http://localhost:8080

## Testing

### Testing Requirements
**IMPORTANT**: When changing implementation code (backend or frontend):
1. **Always run tests** after making changes to ensure nothing breaks
2. **Fix any failing tests** immediately - update test assertions or fix the implementation
3. **Update test expectations** when intentionally changing behavior
4. Never leave tests in a failing state

### Backend Testing
Backend tests use:
- JUnit 5
- Mockito for mocking
- Strikt for assertions (Kotlin-friendly)
- TestContainers with LocalStack for DynamoDB integration tests

Run backend tests:
```bash
cd hello-backend
./gradlew test
```

## Build Artifacts

Backend:
- Standard: `hello-backend/build/libs/hello-backend-0.1-all.jar` (shadow JAR)
- Native: `hello-backend/build/libs/hello-backend-0.1-lambda.zip` (GraalVM native Lambda)

Frontend:
- Production build: `hello-frontend/dist/`

## AWS Deployment

### Environment Configuration

Environment-to-domain mappings are configured in `scripts/env-config.sh`:

```bash
# Domain configuration per environment
declare -A ENV_DOMAINS
ENV_DOMAINS[dev]="hello-dev.qapil.com"
ENV_DOMAINS[prod]="hello-app.qapil.com"
```

To add new environments or change domain names, edit this file.

### Deployment Scripts

All deployment scripts are located in the `scripts/` directory and take a single parameter: **environment** (`dev` or `prod`).

#### 1. Build Backend Lambda

```bash
cd scripts
./build-backend.sh
```

This creates the GraalVM native Lambda artifact at `hello-backend/build/libs/hello-backend-0.1-lambda.zip`.

#### 2. Deploy Certificate (First Time Only)

```bash
cd scripts
./deploy-cert.sh [env]
```

Examples:
- `./deploy-cert.sh prod` - Deploy certificate for production
- `./deploy-cert.sh dev` - Deploy certificate for development

This creates an ACM certificate for the domain specified in `env-config.sh`. After running:
1. Note the DNS CNAME record(s) shown in the output
2. Add the CNAME record(s) to your DNS provider
3. Wait for certificate validation (status becomes `ISSUED`)

#### 3. Deploy Backend Infrastructure

```bash
cd scripts
./deploy-app.sh [env] [google-client-id] [google-client-secret]
```

Examples:
- `./deploy-app.sh prod` - Deploy to production
- `./deploy-app.sh dev` - Deploy to development

Environment variables for Cognito:
- `GOOGLE_CLIENT_ID` - Google OAuth Client ID
- `GOOGLE_CLIENT_SECRET` - Google OAuth Client Secret

This deploys:
- Lambda function (backend API)
- API Gateway
- DynamoDB table
- S3 bucket for frontend
- CloudFront distribution
- Cognito User Pool

After deployment:
1. Note the CloudFrontDomain output
2. Create DNS CNAME: `[domain] → [CloudFrontDomain]`
3. Update `hello-frontend/.env` with the displayed Cognito values

#### 4. Build Frontend

```bash
cd hello-frontend
bun run build
```

This creates production build in `hello-frontend/dist/`.

#### 5. Deploy Frontend

```bash
cd scripts
./deploy-frontend.sh [env]
```

Examples:
- `./deploy-frontend.sh prod` - Deploy frontend to production
- `./deploy-frontend.sh dev` - Deploy frontend to development

This uploads the frontend build to S3 and invalidates the CloudFront cache.

### Complete Deployment Flow

For a fresh deployment:

```bash
# 1. Build backend
cd scripts
./build-backend.sh

# 2. Deploy certificate (first time only)
./deploy-cert.sh prod
# Add DNS CNAME records and wait for validation

# 3. Deploy infrastructure
./deploy-app.sh prod
# Add DNS CNAME for domain to CloudFront

# 4. Build frontend
cd ../hello-frontend
bun run build

# 5. Deploy frontend
cd ../scripts
./deploy-frontend.sh prod
```

For deployment with Cognito authentication:

```bash
# Set Google OAuth credentials
export GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="your-client-secret"

# Deploy
./deploy-app.sh prod

# Note the Cognito outputs and update hello-frontend/.env:
# VITE_COGNITO_USER_POOL_ID=...
# VITE_COGNITO_CLIENT_ID=...
# VITE_COGNITO_REGION=...
# VITE_COGNITO_DOMAIN=...
```

For subsequent updates:

```bash
# Backend changes
cd scripts
./build-backend.sh
./deploy-app.sh prod

# Frontend changes
cd hello-frontend
bun run build
cd ../scripts
./deploy-frontend.sh prod
```

### Stack Names

Stacks are named using pattern: `hello-[resource]-[env]`
- Certificate stack: `hello-cert-prod`, `hello-cert-dev`
- App stack: `hello-app-prod`, `hello-app-dev`
