<template>
  <v-list-item
    v-if="authStore.isLoggedIn"
    prepend-icon="mdi-logout"
    @click="authStore.logout()"
  >
    <v-list-item-title>{{ t('menu.signOut') }}</v-list-item-title>
  </v-list-item>
  <v-list-item
    v-else
    :disabled="authStore.loading"
    prepend-icon="mdi-google"
    @click="authStore.loginWithGoogle()"
  >
    <v-list-item-title>{{ t('menu.signIn') }}</v-list-item-title>
  </v-list-item>
</template>

<script setup lang="ts">
  import { useI18n } from 'vue-i18n'
  import { useAuthStore } from '@/stores/auth'

  const { t } = useI18n()
  const authStore = useAuthStore()
</script>
