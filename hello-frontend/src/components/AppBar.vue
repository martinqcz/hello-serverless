<template>
  <v-app-bar flat>
    <v-app-bar-title>
      <v-icon icon="mdi-circle-slice-6" />
      Hello App
    </v-app-bar-title>
    <v-spacer />

    <toggle-theme-button />

    <!-- User Menu -->
    <v-menu>
      <template #activator="{ props }">
        <v-btn v-bind="props" class="text-none" variant="text">
          <v-avatar class="mr-2" color="primary" size="32">
            <v-icon>mdi-account</v-icon>
          </v-avatar>
          <span class="d-none d-sm-inline">
            {{ authStore.isLoggedIn ? (authStore.user?.name || authStore.user?.email) : t('menu.anonymous') }}
          </span>
          <v-icon end>mdi-chevron-down</v-icon>
        </v-btn>
      </template>
      <v-list density="compact" min-width="200">
        <!-- Language selection -->
        <language-menu-item />
        <v-divider />

        <!-- Authenticated user section -->
        <template v-if="authStore.isLoggedIn">
          <v-list-item class="text-caption text-medium-emphasis">
            {{ authStore.user?.email }}
          </v-list-item>
          <v-divider />
          <v-list-item prepend-icon="mdi-account-circle" to="/profile">
            <v-list-item-title>{{ t('menu.profile') }}</v-list-item-title>
          </v-list-item>
          <v-divider />
        </template>

        <!-- Sign in / Sign out -->
        <auth-menu-item />
      </v-list>
    </v-menu>
  </v-app-bar>
</template>

<script setup lang="ts">
  import { useI18n } from 'vue-i18n'
  import { useAuthStore } from '@/stores/auth'

  const { t } = useI18n()
  const authStore = useAuthStore()
</script>
