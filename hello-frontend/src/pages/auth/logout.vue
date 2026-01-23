<template>
  <v-container class="fill-height">
    <v-row align="center" justify="center">
      <v-col class="text-center" cols="12" md="6" sm="8">
        <v-icon color="success" size="64">mdi-check-circle</v-icon>
        <p class="mt-4 text-h6">You have been logged out</p>
        <p class="text-body-2 text-medium-emphasis">Thank you for using Hello App</p>
        <v-btn class="mt-4" color="primary" to="/">
          Return to Home
        </v-btn>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup lang="ts">
  import { onMounted } from 'vue'
  import { useAuthStore } from '@/stores/auth'

  const authStore = useAuthStore()

  onMounted(() => {
    // Clear local state without redirect
    authStore.clearState()
  })
</script>
