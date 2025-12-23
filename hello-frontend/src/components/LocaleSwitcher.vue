<template>
  <v-btn id="language-switcher">
    {{ t(`locale.${store.locale}`) }}
  </v-btn>
  <v-menu activator="#language-switcher" offset-y>
    <v-list>
      <v-list-item
        v-for="lang in store.supportedLocales"
        :key="`lang-${lang}`"
        :value="lang"
        @click="changeLocale(lang)"
      >
        {{ t(`locale.${lang}`) }}
      </v-list-item>
    </v-list>
  </v-menu>
</template>

<script setup lang="ts">
  import { useI18n } from 'vue-i18n'
  import { useAppStore } from '@/stores/app'

  const { t } = useI18n()
  const store = useAppStore()

  function changeLocale (lang: string) {
    store.changeLocale(lang)
  }
</script>
