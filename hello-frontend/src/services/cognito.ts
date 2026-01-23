import type { AuthTokens, CognitoConfig, UserProfile } from '@/types/auth'

const config: CognitoConfig = {
  userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID || '',
  clientId: import.meta.env.VITE_COGNITO_CLIENT_ID || '',
  region: import.meta.env.VITE_COGNITO_REGION || 'us-east-1',
  domain: import.meta.env.VITE_COGNITO_DOMAIN || '',
}

const REDIRECT_URI = `${window.location.origin}/auth/callback`
const LOGOUT_URI = `${window.location.origin}/auth/logout`
const CODE_VERIFIER_KEY = 'cognito_code_verifier'

// Generate random string for PKCE
function generateRandomString (length: number): string {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~'
  const array = new Uint8Array(length)
  crypto.getRandomValues(array)
  return Array.from(array, byte => charset[byte % charset.length]).join('')
}

// Generate code challenge from verifier (SHA-256)
async function generateCodeChallenge (verifier: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(verifier)
  const digest = await crypto.subtle.digest('SHA-256', data)
  return btoa(String.fromCodePoint(...new Uint8Array(digest)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
}

// Decode JWT payload (for display only, not validation)
export function decodeToken (token: string): Record<string, unknown> {
  try {
    const parts = token.split('.')
    if (parts.length !== 3 || !parts[1]) {
      return {}
    }
    const decoded = atob(parts[1].replace(/-/g, '+').replace(/_/g, '/'))
    return JSON.parse(decoded)
  } catch {
    return {}
  }
}

// Extract user profile from ID token
export function extractUserProfile (idToken: string): UserProfile | null {
  const payload = decodeToken(idToken)
  if (!payload.sub) {
    return null
  }
  return {
    sub: payload.sub as string,
    email: (payload.email as string) || '',
    name: payload.name as string | undefined,
  }
}

// Initiate login with Google via Cognito Hosted UI with PKCE
export async function loginWithGoogle (): Promise<void> {
  const codeVerifier = generateRandomString(128)
  const codeChallenge = await generateCodeChallenge(codeVerifier)

  // Store verifier for later use in callback
  sessionStorage.setItem(CODE_VERIFIER_KEY, codeVerifier)

  const params = new URLSearchParams({
    response_type: 'code',
    client_id: config.clientId,
    redirect_uri: REDIRECT_URI,
    scope: 'email openid profile',
    identity_provider: 'Google',
    code_challenge_method: 'S256',
    code_challenge: codeChallenge,
  })

  window.location.href = `${config.domain}/oauth2/authorize?${params.toString()}`
}

// Exchange authorization code for tokens
export async function handleCallback (code: string): Promise<AuthTokens> {
  const codeVerifier = sessionStorage.getItem(CODE_VERIFIER_KEY)
  if (!codeVerifier) {
    throw new Error('Code verifier not found. Please try logging in again.')
  }

  // Clear verifier after retrieval
  sessionStorage.removeItem(CODE_VERIFIER_KEY)

  const params = new URLSearchParams({
    grant_type: 'authorization_code',
    client_id: config.clientId,
    code,
    redirect_uri: REDIRECT_URI,
    code_verifier: codeVerifier,
  })

  const response = await fetch(`${config.domain}/oauth2/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: params.toString(),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Token exchange failed: ${error}`)
  }

  const data = await response.json()
  return {
    accessToken: data.access_token,
    idToken: data.id_token,
    refreshToken: data.refresh_token,
    expiresIn: data.expires_in,
  }
}

// Refresh access token using refresh token
export async function refreshToken (refreshTokenValue: string): Promise<AuthTokens> {
  const params = new URLSearchParams({
    grant_type: 'refresh_token',
    client_id: config.clientId,
    refresh_token: refreshTokenValue,
  })

  const response = await fetch(`${config.domain}/oauth2/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: params.toString(),
  })

  if (!response.ok) {
    throw new Error('Token refresh failed')
  }

  const data = await response.json()
  return {
    accessToken: data.access_token,
    idToken: data.id_token,
    refreshToken: refreshTokenValue, // Cognito doesn't return new refresh token
    expiresIn: data.expires_in,
  }
}

// Logout - redirect to Cognito logout endpoint
export function logout (): void {
  const params = new URLSearchParams({
    client_id: config.clientId,
    logout_uri: LOGOUT_URI,
  })

  window.location.href = `${config.domain}/logout?${params.toString()}`
}

// Get Cognito configuration
export function getCognitoConfig (): CognitoConfig {
  return config
}
