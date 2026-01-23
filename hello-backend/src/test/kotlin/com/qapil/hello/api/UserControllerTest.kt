package com.qapil.hello.api

import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent
import io.micronaut.function.aws.proxy.MockLambdaContext
import io.micronaut.function.aws.proxy.payload1.ApiGatewayProxyRequestEventFunction
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class UserControllerTest {

    @Test
    fun `Should return 401 for profile without authentication`() {
        val handler = ApiGatewayProxyRequestEventFunction()
        val request = APIGatewayProxyRequestEvent().apply {
            httpMethod = "GET"
            path = "/api/v1/profile"
            requestContext = APIGatewayProxyRequestEvent.ProxyRequestContext()
        }
        val response = handler.handleRequest(request, MockLambdaContext())

        assertThat(response.statusCode).isEqualTo(401)
        handler.applicationContext.close()
    }

    @Test
    fun `Should allow public access to hello endpoint`() {
        val handler = ApiGatewayProxyRequestEventFunction()
        val request = APIGatewayProxyRequestEvent().apply {
            httpMethod = "GET"
            path = "/api/v1/hello"
            requestContext = APIGatewayProxyRequestEvent.ProxyRequestContext()
        }
        val response = handler.handleRequest(request, MockLambdaContext())

        assertThat(response.statusCode).isEqualTo(200)
        assertThat(response.body).contains("Hello World")
        handler.applicationContext.close()
    }
}
