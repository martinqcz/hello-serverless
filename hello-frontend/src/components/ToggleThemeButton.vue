<template>
  <v-btn
    :prepend-icon="store.appTheme === LIGHT_THEME ? 'mdi-weather-sunny' : 'mdi-weather-night'"
    @click="onToggleTheme"
  />
</template>

<script setup lang="ts">
  import { LIGHT_THEME, useAppStore } from '@/stores/app'

  const store = useAppStore()

  function onToggleTheme () {
    store.toggleTheme()
  }
</script>
