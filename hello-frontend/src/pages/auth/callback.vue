<template>
  <v-container class="fill-height">
    <v-row align="center" justify="center">
      <v-col class="text-center" cols="12" md="6" sm="8">
        <template v-if="loading">
          <v-progress-circular
            color="primary"
            indeterminate
            size="64"
          />
          <p class="mt-4 text-body-1">Completing sign in...</p>
        </template>

        <template v-else-if="error">
          <v-icon color="error" size="64">mdi-alert-circle</v-icon>
          <p class="mt-4 text-h6">Authentication Failed</p>
          <p class="text-body-2 text-medium-emphasis">{{ error }}</p>
          <v-btn class="mt-4" color="primary" to="/">
            Return to Home
          </v-btn>
        </template>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup lang="ts">
  import { ref, onMounted } from 'vue'
  import { useRouter, useRoute } from 'vue-router'
  import { useAuthStore } from '@/stores/auth'

  const router = useRouter()
  const route = useRoute()
  const authStore = useAuthStore()

  const loading = ref(true)
  const error = ref<string | null>(null)

  onMounted(async () => {
    const code = route.query.code as string
    const errorParam = route.query.error as string

    if (errorParam) {
      error.value = `Authentication was cancelled or failed: ${errorParam}`
      loading.value = false
      return
    }

    if (!code) {
      error.value = 'No authorization code received'
      loading.value = false
      return
    }

    try {
      await authStore.handleOAuthCallback(code)
      router.push('/profile')
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to complete authentication'
      loading.value = false
    }
  })
</script>
