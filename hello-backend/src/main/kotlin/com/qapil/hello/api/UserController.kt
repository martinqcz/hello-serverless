package com.qapil.hello.api

import io.github.oshai.kotlinlogging.KotlinLogging
import io.micronaut.http.annotation.Controller
import io.micronaut.http.annotation.Get
import io.micronaut.security.annotation.Secured
import io.micronaut.security.authentication.Authentication
import io.micronaut.security.rules.SecurityRule

@Controller("/api/v1")
open class UserController {

    @Get("/profile")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    fun getProfile(authentication: Authentication): Map<String, Any?> {
        logger.info { "Profile requested for user: ${authentication.name}" }
        return mapOf(
            "sub" to authentication.name,
            "email" to authentication.attributes["email"],
            "name" to authentication.attributes["name"],
            "claims" to authentication.attributes
        )
    }

    companion object {
        private val logger = KotlinLogging.logger {}
    }
}
