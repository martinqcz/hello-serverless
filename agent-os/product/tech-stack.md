# Tech Stack

## Backend

- **Framework:** Micronaut 4.10.6
- **Language:** Kotlin 1.9.25
- **Runtime:** Java 21 / GraalVM native image
- **Build:** Gradle with KSP

## Frontend

- **Framework:** Vue 3
- **UI Library:** Vuetify 3
- **Language:** TypeScript
- **State:** Pinia with persistence
- **Build:** Vite
- **Routing:** unplugin-vue-router (file-based)

## Database

- **Production:** AWS DynamoDB
- **Local/Test:** LocalStack via TestContainers

## Infrastructure

- **Compute:** AWS Lambda (provided.al2023 runtime for native arm64 architecture)
- **API:** AWS API Gateway
- **CDN:** CloudFront
- **Storage:** S3 (frontend assets)
- **IaC:** AWS SAM (CloudFormation)
- **Regions:** us-east-1 (cert + app)
