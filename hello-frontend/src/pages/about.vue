<template>
  <v-container>
    <v-row>
      <v-col>
        <h1>About Page</h1>
        <v-card class="mt-4" :loading="loading">
          <v-card-text>
            <div v-if="loading">Loading...</div>
            <div v-else-if="error" class="text-error">
              Error: {{ error }}
            </div>
            <div v-else-if="message" class="text-h5">
              {{ message }}
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue'
  import { api } from '@/plugins'

  const message = ref<string>('')
  const loading = ref<boolean>(false)
  const error = ref<string>('')

  onMounted(async () => {
    loading.value = true
    try {
      const response = await api.get('/v1/hello', {
        params: { name: 'User' },
      })
      message.value = response.data.message
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch message'
      console.error('Error fetching hello message:', err)
    } finally {
      loading.value = false
    }
  })
</script>
