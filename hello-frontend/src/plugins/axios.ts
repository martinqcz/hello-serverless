/**
 * Axios Plugin
 * Centralized axios instance with base URL configuration from environment variables
 */
import axios from 'axios'

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  headers: {
    'Content-Type': 'application/json',
  },
})
