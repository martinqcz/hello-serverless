<template>
  <router-view />
</template>

<script lang="ts" setup>
  import { onMounted } from 'vue'
  import { useI18n } from 'vue-i18n'
  import { useAppStore } from '@/stores/app.ts'

  const store = useAppStore()
  const i18n = useI18n()

  onMounted(() => {
    store.initLocale()
    i18n.locale.value = store.locale

    store.$subscribe((_, state) => {
      i18n.locale.value = state.locale
    })
  })
</script>
