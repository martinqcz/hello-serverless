package com.qapil.hello.api

import io.github.oshai.kotlinlogging.KotlinLogging
import io.micronaut.http.annotation.Controller
import io.micronaut.http.annotation.Get
import io.micronaut.http.annotation.QueryValue

@Controller("/api/v1")
open class HomeController {

    @Get("/hello")
    fun index(@QueryValue(defaultValue = "World") name: String): Map<String, String> {
        logger.info { "Hello $name" }
        return mapOf("message" to "Hello $name")
    }

    companion object {
        private val logger = KotlinLogging.logger {}
    }
}