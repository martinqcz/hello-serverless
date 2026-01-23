# API Client Import

Use centralized axios instance from `@/plugins`.

```typescript
import { api } from '@/plugins'

// GET request
const response = await api.get('/v1/hello')

// POST request
const response = await api.post('/v1/users', { name: 'John' })
```

**Why:**
- Single configuration point for base URL, headers, interceptors
- Environment flexibility via `VITE_API_BASE_URL` env variable
- Dev: Vite proxy forwards `/api` to backend (localhost:8080)
- Prod: CloudFront routes `/api` to API Gateway

**Pattern:**
- Always import from `@/plugins`: `import { api } from '@/plugins'`
- Never import axios directly in components
- Paths are relative to base URL: `/v1/hello` → `/api/v1/hello`
