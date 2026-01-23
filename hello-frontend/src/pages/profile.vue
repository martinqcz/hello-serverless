<route lang="yaml">
meta:
  requiresAuth: true
</route>

<template>
  <v-container>
    <v-row>
      <v-col cols="12" md="8" offset-md="2">
        <v-card>
          <v-card-title class="d-flex align-center">
            <v-avatar class="mr-4" color="primary" size="64">
              <v-icon size="40">mdi-account</v-icon>
            </v-avatar>
            <div>
              <div class="text-h5">{{ authStore.user?.name || 'User' }}</div>
              <div class="text-body-2 text-medium-emphasis">{{ authStore.user?.email }}</div>
            </div>
          </v-card-title>

          <v-divider />

          <v-card-text>
            <v-list>
              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-email</v-icon>
                </template>
                <v-list-item-title>Email</v-list-item-title>
                <v-list-item-subtitle>{{ authStore.user?.email }}</v-list-item-subtitle>
              </v-list-item>

              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-identifier</v-icon>
                </template>
                <v-list-item-title>User ID</v-list-item-title>
                <v-list-item-subtitle class="text-truncate">{{ authStore.user?.sub }}</v-list-item-subtitle>
              </v-list-item>
            </v-list>

            <v-divider class="my-4" />

            <div class="text-subtitle-2 mb-2">Backend Profile Data</div>
            <v-alert
              v-if="profileError"
              class="mb-4"
              type="error"
              variant="tonal"
            >
              {{ profileError }}
            </v-alert>

            <v-skeleton-loader
              v-if="loadingProfile"
              type="list-item-two-line, list-item-two-line"
            />

            <v-list v-else-if="backendProfile" density="compact">
              <v-list-item v-for="(value, key) in backendProfile" :key="key">
                <v-list-item-title class="text-caption font-weight-medium">{{ key }}</v-list-item-title>
                <v-list-item-subtitle class="text-truncate">
                  {{ typeof value === 'object' ? JSON.stringify(value) : value }}
                </v-list-item-subtitle>
              </v-list-item>
            </v-list>
          </v-card-text>

        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup lang="ts">
  import { ref, onMounted } from 'vue'
  import { useAuthStore } from '@/stores/auth'
  import { api } from '@/plugins'

  const authStore = useAuthStore()
  const loadingProfile = ref(true)
  const profileError = ref<string | null>(null)
  const backendProfile = ref<Record<string, unknown> | null>(null)

  onMounted(async () => {
    try {
      const response = await api.get('/v1/profile')
      backendProfile.value = response.data
    } catch (err) {
      profileError.value = 'Failed to load profile from backend'
      console.error('Profile fetch error:', err)
    } finally {
      loadingProfile.value = false
    }
  })
</script>
