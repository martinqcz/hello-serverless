# Controller Structure

Controllers are `open` classes with Micronaut annotations and logging.

```kotlin
package com.qapil.hello.api

import io.github.oshai.kotlinlogging.KotlinLogging
import io.micronaut.http.annotation.Controller
import io.micronaut.http.annotation.Get

@Controller("/api/v1")
open class HomeController {

    @Get("/hello")
    fun index(): Map<String, String> {
        logger.info { "Processing request" }
        return mapOf("message" to "Hello")
    }

    companion object {
        private val logger = KotlinLogging.logger {}
    }
}
```

**Why:**
- `open` modifier required by Micronaut for AOP proxy creation
- Companion object holds logger (see logging-pattern.md)

**Pattern:**
- Declare class as `open`
- Apply `@Controller` with base path
- Logger in companion object
- Currently organized under `api/` package (pattern may evolve)
