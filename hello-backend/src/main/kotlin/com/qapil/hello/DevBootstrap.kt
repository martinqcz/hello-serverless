package com.qapil.hello

import com.qapil.hello.dynamodb.DynamoRepository
import io.micronaut.context.annotation.Requires
import io.micronaut.context.env.Environment
import io.micronaut.context.event.ApplicationEventListener
import io.micronaut.context.event.StartupEvent
import jakarta.inject.Singleton

@Requires(property = "dynamodb-local.host")
@Requires(property = "dynamodb-local.port")
@Requires(env = [Environment.DEVELOPMENT])
@Singleton
class DevBootstrap(
    private val dynamoRepository: DynamoRepository
) : ApplicationEventListener<StartupEvent> {

    override fun onApplicationEvent(event: StartupEvent) {
        // if (!dynamoRepository.existsTable()) {
        //     dynamoRepository.createTable()
        // }
    }
}