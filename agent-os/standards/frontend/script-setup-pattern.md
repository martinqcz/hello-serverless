# Script Setup Pattern

All Vue components use `<script setup lang="ts">` with TypeScript.

```vue
<template>
  <v-btn @click="handleClick">{{ label }}</v-btn>
</template>

<script setup lang="ts">
  import { useAppStore } from '@/stores/app'

  const store = useAppStore()

  function handleClick() {
    store.toggleTheme()
  }
</script>
```

**Pattern:**
- Always use `<script setup lang="ts">` (not Options API)
- Template comes first, script second
- Empty script blocks include `//` comment for consistency

```vue
<script setup lang="ts">
  //
</script>
```
