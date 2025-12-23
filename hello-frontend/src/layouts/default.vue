<template>
  <v-app :theme="store.appTheme">
    <app-bar />
    <side-bar />
    <v-main>
      <router-view />
    </v-main>
    <app-footer />
  </v-app>
</template>

<script lang="ts" setup>
  import { useAppStore } from '@/stores/app.ts'

  const store = useAppStore()
</script>
