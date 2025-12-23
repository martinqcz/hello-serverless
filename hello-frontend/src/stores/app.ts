// Utilities
import { defineStore } from 'pinia'

const LIGHT_THEME = 'light'
const DARK_THEME = 'dark'

const useAppStore = defineStore('app', {
  state: () => ({
    appTheme: LIGHT_THEME,
    locale: 'detect',
  }),
  persist: true,
  actions: {
    toggleTheme () {
      this.appTheme = this.appTheme === LIGHT_THEME ? DARK_THEME : LIGHT_THEME
    },
    changeLocale (locale: string) {
      this.locale = locale
    },
    initLocale (): string {
      if (this.locale === 'detect') {
        let locale = this.browserLanguage
        if (!this.supportedLocales.includes(locale)) {
          locale = import.meta.env.VITE_APP_I18N_LOCALE || 'en'
        }
        this.locale = locale
      }
      return this.locale
    },
  },
  getters: {
    browserLanguage () {
      let lang = navigator.language
      const i = lang.indexOf('-')
      if (i > 0) {
        lang = lang.slice(0, Math.max(0, i))
      }
      return lang
    },
    supportedLocales (): string[] {
      return import.meta.env.VITE_SUPPORTED_LOCALES.split(',')
    },
  },
})

export { DARK_THEME, LIGHT_THEME, useAppStore }
