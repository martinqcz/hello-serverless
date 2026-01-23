package com.qapil.hello.config

import io.github.oshai.kotlinlogging.KotlinLogging
import io.micronaut.context.annotation.Requires
import io.micronaut.context.event.ApplicationEventListener
import io.micronaut.context.event.StartupEvent
import jakarta.inject.Singleton

/**
 * Fails application startup if COGNITO_JWKS_URL is not configured.
 * Only active in non-test environments (tests use secret-based JWT signing).
 */
@Singleton
@Requires(
    property = "micronaut.security.token.jwt.signatures.jwks.cognito.url",
    value = ""
)
@Requires(notEnv = ["test", "function"])
class SecurityConfigValidator : ApplicationEventListener<StartupEvent> {

    override fun onApplicationEvent(event: StartupEvent) {
        logger.error { "COGNITO_JWKS_URL environment variable is not set or empty" }
        throw IllegalStateException(
            "Security configuration error: COGNITO_JWKS_URL must be set. " +
            "Configure the environment variable with your Cognito JWKS URL."
        )
    }

    companion object {
        private val logger = KotlinLogging.logger {}
    }
}
