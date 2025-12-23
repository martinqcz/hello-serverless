package com.qapil.hello.api

import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent
import io.micronaut.function.aws.proxy.MockLambdaContext
import io.micronaut.function.aws.proxy.payload1.ApiGatewayProxyRequestEventFunction
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

class HomeControllerTest {

    @Test
    fun `Should geet the World`() {
        val handler = ApiGatewayProxyRequestEventFunction()
        val request = APIGatewayProxyRequestEvent()
        request.httpMethod = "GET"
        request.path = "/api/v1/hello"
        val response = handler.handleRequest(request, MockLambdaContext())

        Assertions.assertEquals(200, response.statusCode)
        Assertions.assertEquals("{\"message\":\"Hello World\"}", response.body)
        handler.applicationContext.close()
    }

    @Test
    fun `Should greet Micronaut`() {
        val handler = ApiGatewayProxyRequestEventFunction()
        val request = APIGatewayProxyRequestEvent()
        request.httpMethod = "GET"
        request.path = "/api/v1/hello"
        request.queryStringParameters = mapOf("name" to "Micronaut")
        val response = handler.handleRequest(request, MockLambdaContext())

        Assertions.assertEquals(200, response.statusCode)
        Assertions.assertEquals("{\"message\":\"Hello Micronaut\"}", response.body)
        handler.applicationContext.close()
    }
}