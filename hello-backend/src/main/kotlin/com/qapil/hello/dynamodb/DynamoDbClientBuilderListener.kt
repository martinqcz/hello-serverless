package com.qapil.hello.dynamodb

import io.micronaut.context.annotation.Requires
import io.micronaut.context.annotation.Value
import io.micronaut.context.env.Environment
import io.micronaut.context.event.BeanCreatedEvent
import io.micronaut.context.event.BeanCreatedEventListener
import io.micronaut.context.exceptions.ConfigurationException
import jakarta.inject.Singleton
import software.amazon.awssdk.auth.credentials.AwsCredentials
import software.amazon.awssdk.services.dynamodb.DynamoDbClientBuilder
import java.net.URI
import java.net.URISyntaxException

@Requires(property = "dynamodb-local.host")
@Requires(property = "dynamodb-local.port")
@Requires(env = [Environment.DEVELOPMENT, Environment.TEST])
@Singleton
class DynamoDbClientBuilderListener(
	@Value("\${dynamodb-local.host}") host: String,
	@Value("\${dynamodb-local.port}") port: String,
): BeanCreatedEventListener<DynamoDbClientBuilder> {
	private val endpoint: URI
	private val accessKeyId: String
	private val secretAccessKey: String

	init {
		try {
			this.endpoint = URI("http://$host:$port")
		} catch (e: URISyntaxException) {
			throw ConfigurationException("dynamodb.endpoint not a valid URI")
		}
		this.accessKeyId = "fakeMyKeyId"
		this.secretAccessKey = "fakeSecretAccessKey"
	}

	override fun onCreated(event: BeanCreatedEvent<DynamoDbClientBuilder>): DynamoDbClientBuilder =
		event.bean.endpointOverride(endpoint)
			.credentialsProvider {
				object: AwsCredentials {
					override fun accessKeyId(): String {
						return accessKeyId
					}
					override fun secretAccessKey(): String {
						return secretAccessKey
					}
				}
			}
}