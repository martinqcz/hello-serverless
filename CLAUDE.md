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

Backend tests use:
- JUnit 5
- Mockito for mocking
- Strikt for assertions (Kotlin-friendly)
- TestContainers with LocalStack for DynamoDB integration tests

## Build Artifacts

Backend:
- Standard: `hello-backend/build/libs/hello-backend-0.1-all.jar` (shadow JAR)
- Native: `hello-backend/build/libs/hello-backend-0.1-lambda.zip` (GraalVM native Lambda)

Frontend:
- Production build: `hello-frontend/dist/`
