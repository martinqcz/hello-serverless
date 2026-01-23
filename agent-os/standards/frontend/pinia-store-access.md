# Pinia Store Access

Access stores via `const store = useXxxStore()` pattern.

```typescript
import { useAppStore } from '@/stores/app'

const store = useAppStore()

// Access state
store.appTheme
store.locale

// Call actions
store.toggleTheme()
store.changeLocale('en')
```

**Why:**
- `store.method()` makes it clear where the action originates
- Avoids confusion when multiple stores are used in same component

**Pattern:**
- Use `const store = useXxxStore()` naming
- Access state/getters directly: `store.stateName`
- Call actions directly: `store.actionName()`
- For subscriptions: `store.$subscribe((_, state) => { ... })`
