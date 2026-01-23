/**
 * Axios Plugin
 * Centralized axios instance with base URL configuration and auth interceptors
 */
import axios, { type AxiosError, type InternalAxiosRequestConfig } from 'axios'
import { useAuthStore } from '@/stores/auth'

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor - add Authorization header
// Use ID token for API calls (contains user claims validated against Cognito JWKS)
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const authStore = useAuthStore()
    const idToken = authStore.tokens.idToken
    if (idToken) {
      config.headers.Authorization = `Bearer ${idToken}`
    }
    return config
  },
  error => Promise.reject(error),
)

// Response interceptor - handle 401 and refresh token
api.interceptors.response.use(
  response => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean }

    // If 401 and not already retried
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true

      const authStore = useAuthStore()
      const refreshed = await authStore.refreshAccessToken()

      if (refreshed) {
        // Retry with new ID token
        originalRequest.headers.Authorization = `Bearer ${authStore.tokens.idToken}`
        return api(originalRequest)
      }
    }

    throw error
  },
)
