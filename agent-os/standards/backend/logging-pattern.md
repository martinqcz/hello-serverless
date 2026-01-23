# Logging Pattern

Use KotlinLogging in companion object with lambda-based logging.

```kotlin
import io.github.oshai.kotlinlogging.KotlinLogging

open class HomeController {
    fun index() {
        logger.info { "Hello ${name} from backend!" }
    }

    companion object {
        private val logger = KotlinLogging.logger {}
    }
}
```

**Why:**
- KotlinLogging provides idiomatic Kotlin API
- Lambda blocks enable lazy evaluation—string interpolation only executes if log level is enabled

**Pattern:**
- Logger in `companion object` as `private val`
- Use `KotlinLogging.logger {}` factory
- Always use lambda syntax: `logger.info { "message" }` not `logger.info("message")`
- String templates inside lambdas: `logger.info { "User ${userId} logged in" }`
