<template>
  <v-menu location="start" open-on-hover>
    <template #activator="{ props }">
      <v-list-item v-bind="props" append-icon="mdi-chevron-right" prepend-icon="mdi-translate">
        <v-list-item-title>{{ t(`locale.${appStore.locale}`) }}</v-list-item-title>
      </v-list-item>
    </template>
    <v-list density="compact">
      <v-list-item
        v-for="lang in appStore.supportedLocales"
        :key="`lang-${lang}`"
        :active="appStore.locale === lang"
        @click="appStore.changeLocale(lang)"
      >
        <v-list-item-title>{{ t(`locale.${lang}`) }}</v-list-item-title>
      </v-list-item>
    </v-list>
  </v-menu>
</template>

<script setup lang="ts">
  import { useI18n } from 'vue-i18n'
  import { useAppStore } from '@/stores/app'

  const { t } = useI18n()
  const appStore = useAppStore()
</script>
