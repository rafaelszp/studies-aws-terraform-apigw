# Here will be an example of rest api with stage variable

# https://api.ipify.org?format=${stageVariable.format}


resource "aws_api_gateway_rest_api" "ipify" {
  name        = "IPIFY"
  description = "IPIFY example"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


## Integration and methods


resource "aws_api_gateway_method" "ipify_get" {
  rest_api_id   = aws_api_gateway_rest_api.ipify.id
  http_method   = "GET"
  resource_id   = aws_api_gateway_rest_api.ipify.root_resource_id
  authorization = "NONE"
  request_parameters = {
    "method.request.header.X-Custom-Header" = true
    # Although this is working right now, AWS  may stript out of the integration request below
    "method.request.header.X-Forwarded-For" = true
  }
}

resource "aws_api_gateway_method_response" "ipify_get_response" {
  rest_api_id = aws_api_gateway_rest_api.ipify.id
  resource_id = aws_api_gateway_rest_api.ipify.root_resource_id
  status_code = 200
  http_method = aws_api_gateway_method.ipify_get.http_method
}

resource "aws_api_gateway_integration" "ipify_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.ipify.id
  resource_id             = aws_api_gateway_rest_api.ipify.root_resource_id
  # type                    = "HTTP_PROXY"
  type                    = "HTTP"
  uri                     = "https://api.ipify.org?format=$${stageVariables.format}"
  # uri                     = "https://echo.free.beeceptor.com"
  integration_http_method = aws_api_gateway_method.ipify_get.http_method
  http_method             = "GET"
  request_parameters = {
    ## This must be declared in the request method
    "integration.request.header.X-My-Header" = "method.request.header.X-Custom-Header"
    # Although this is working right now, AWS  may stript out of the integration request below
    "integration.request.header.X-Forwarded-For" = "method.request.header.X-Forwarded-For"
  }

  #this will be put in the body
  request_templates = {
    "application/json" = <<-EOT
      {
        "headers": {
          #foreach($param in $input.params().header.keySet())
            "$param": "$util.escapeJavaScript($input.params().header.get($param))"
          #end
        }
      }
      EOT
  }
}

resource "aws_api_gateway_integration_response" "ipify_get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.ipify.id
  resource_id = aws_api_gateway_rest_api.ipify.root_resource_id
  http_method = aws_api_gateway_method.ipify_get.http_method
  status_code = aws_api_gateway_method_response.ipify_get_response.status_code

  depends_on = [aws_api_gateway_method.ipify_get, aws_api_gateway_integration.ipify_get_integration]
}


## Deployment + Stage

resource "aws_api_gateway_deployment" "ipify_deployment" {
  rest_api_id = aws_api_gateway_rest_api.ipify.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.ipify,
      aws_api_gateway_method.ipify_get,
      aws_api_gateway_integration.ipify_get_integration
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "ipify_stage_json" {
  rest_api_id   = aws_api_gateway_rest_api.ipify.id
  deployment_id = aws_api_gateway_deployment.ipify_deployment.id
  stage_name    = "json"

  variables = {
    "format" = "json"
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.ipify_log_group.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage",
      path = "$context.path",
      stage = "json"
      }
    )
  }

}


resource "aws_api_gateway_stage" "ipify_stage_plain" {
  rest_api_id   = aws_api_gateway_rest_api.ipify.id
  deployment_id = aws_api_gateway_deployment.ipify_deployment.id
  stage_name    = "plain"

  variables = {
    "format" = "plain"
  }
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.ipify_log_group.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage",
      path = "$context.path",
      stage = "plain"
      }
    )
  }
}

#cloudwatch
resource "aws_cloudwatch_log_group" "ipify_log_group" {
  name = "/aws/apigateway/${aws_api_gateway_rest_api.ipify.name}"
  retention_in_days = 1
}

#out
output "ipify_json_url" {
  value = aws_api_gateway_stage.ipify_stage_json.invoke_url
}

output "ipify_plain_url" {
  value = aws_api_gateway_stage.ipify_stage_plain.invoke_url
}