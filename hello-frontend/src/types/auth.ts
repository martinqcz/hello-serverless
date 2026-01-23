export interface UserProfile {
  sub: string
  email: string
  name?: string
}

export interface AuthTokens {
  accessToken: string
  idToken: string
  refreshToken: string
  expiresIn: number
}

export interface AuthState {
  isAuthenticated: boolean
  user: UserProfile | null
  tokens: {
    accessToken: string | null
    idToken: string | null
    refreshToken: string | null
  }
  loading: boolean
  error: string | null
}

export interface CognitoConfig {
  userPoolId: string
  clientId: string
  region: string
  domain: string
}
