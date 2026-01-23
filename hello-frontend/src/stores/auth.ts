import { defineStore } from 'pinia'
import type { AuthState } from '@/types/auth'
import {
  loginWithGoogle as cognitoLogin,
  handleCallback as cognitoHandleCallback,
  refreshToken as cognitoRefreshToken,
  logout as cognitoLogout,
  extractUserProfile,
} from '@/services/cognito'

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({
    isAuthenticated: false,
    user: null,
    tokens: {
      accessToken: null,
      idToken: null,
      refreshToken: null,
    },
    loading: false,
    error: null,
  }),

  persist: {
    pick: ['tokens.accessToken', 'tokens.idToken', 'tokens.refreshToken'],
  },

  getters: {
    isLoggedIn: state => state.isAuthenticated && !!state.tokens.accessToken,
    currentUser: state => state.user,
    accessToken: state => state.tokens.accessToken,
  },

  actions: {
    // Start login flow with Google
    loginWithGoogle () {
      this.loading = true
      this.error = null
      cognitoLogin()
    },

    // Handle OAuth callback with authorization code
    async handleOAuthCallback (code: string) {
      this.loading = true
      this.error = null

      try {
        const tokens = await cognitoHandleCallback(code)
        this.setTokens(tokens.accessToken, tokens.idToken, tokens.refreshToken)
        this.scheduleTokenRefresh(tokens.expiresIn)
      } catch (err) {
        this.error = err instanceof Error ? err.message : 'Authentication failed'
        throw err
      } finally {
        this.loading = false
      }
    },

    // Set tokens and extract user info
    setTokens (accessToken: string, idToken: string, refreshToken: string) {
      this.tokens.accessToken = accessToken
      this.tokens.idToken = idToken
      this.tokens.refreshToken = refreshToken
      this.user = extractUserProfile(idToken)
      this.isAuthenticated = true
    },

    // Refresh access token
    async refreshAccessToken (): Promise<boolean> {
      if (!this.tokens.refreshToken) {
        return false
      }

      try {
        const tokens = await cognitoRefreshToken(this.tokens.refreshToken)
        this.tokens.accessToken = tokens.accessToken
        this.tokens.idToken = tokens.idToken
        this.user = extractUserProfile(tokens.idToken)
        this.scheduleTokenRefresh(tokens.expiresIn)
        return true
      } catch {
        this.logout()
        return false
      }
    },

    // Schedule token refresh before expiration
    scheduleTokenRefresh (expiresIn: number) {
      // Refresh 5 minutes before expiration
      const refreshTime = (expiresIn - 300) * 1000
      if (refreshTime > 0) {
        setTimeout(() => {
          this.refreshAccessToken()
        }, refreshTime)
      }
    },

    // Initialize auth state from persisted tokens
    async initAuth () {
      // Restore user profile from persisted idToken
      if (this.tokens.idToken && this.tokens.accessToken) {
        this.user = extractUserProfile(this.tokens.idToken)
        this.isAuthenticated = true
      } else if (this.tokens.refreshToken) {
        // No access token but have refresh token - try to refresh
        this.loading = true
        try {
          await this.refreshAccessToken()
        } catch {
          // Silent fail - user will need to login again
          this.clearState()
        } finally {
          this.loading = false
        }
      }
    },

    // Logout and clear state
    logout () {
      this.clearState()
      cognitoLogout()
    },

    // Clear local state without redirect
    clearState () {
      this.isAuthenticated = false
      this.user = null
      this.tokens = {
        accessToken: null,
        idToken: null,
        refreshToken: null,
      }
      this.error = null
    },
  },
})
