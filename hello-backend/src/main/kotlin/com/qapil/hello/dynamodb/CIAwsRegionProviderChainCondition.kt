package com.qapil.hello.dynamodb

import io.github.oshai.kotlinlogging.KotlinLogging
import io.micronaut.context.condition.Condition
import io.micronaut.context.condition.ConditionContext
import java.io.File

/**
 * @see <a href="https://docs.aws.amazon.com/sdk-for-java/latest/developer-guide/region-selection.html">Default region provider chain</a>
 */
class CIAwsRegionProviderChainCondition : Condition {

    override fun matches(context: ConditionContext<*>?): Boolean {
        if (System.getenv("CI") == null) {
            logger.info { "CI environment variable not present - Condition fulfilled" }
            return true
        }
        if (System.getProperty("aws.region") != null) {
            logger.info { "aws.region system property present - Condition fulfilled" }
            return true
        }
        if (System.getenv("AWS_REGION") != null) {
            logger.info { "AWS_REGION environment variable present - Condition fulfilled" };
            return true
        }
        val result = System.getenv("HOME") != null && File(System.getenv("HOME") + "/.aws/config").exists();
        if (result) {
            logger.info { "~/.aws/config file exists - Condition fulfilled" };
        }
        return result
    }

    companion object {
        private val logger = KotlinLogging.logger {}
    }
}
