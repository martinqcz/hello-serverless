# API Path Convention

All REST endpoints use `/api/v1` prefix.

```kotlin
@Controller("/api/v1")
open class HomeController {
    @Get("/hello")
    fun index() { ... }
}
```

**Why:**
- CloudFront routes `/api/*` to API Gateway in production
- Version prefix (`v1`) enables future API versioning for backward compatibility

**Pattern:**
- Apply `@Controller("/api/v1")` at class level
- Method paths are relative: `@Get("/hello")` → `/api/v1/hello`
- Full URL in production: `https://domain.com/api/v1/hello`

**Note:** Current codebase uses v1 consistently. Exceptions (health checks, admin endpoints) not yet defined.
