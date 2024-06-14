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
  type                    = "HTTP_PROXY"
  uri                     = "https://api.ipify.org?format=$${stageVariables.format}"
  integration_http_method = aws_api_gateway_method.ipify_get.http_method
  http_method             = "GET"
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
}


resource "aws_api_gateway_stage" "ipify_stage_plain" {
  rest_api_id   = aws_api_gateway_rest_api.ipify.id
  deployment_id = aws_api_gateway_deployment.ipify_deployment.id
  stage_name    = "plain"

  variables = {
    "format" = "plain"
  }
}

output "ipify_json_url" {
  value = aws_api_gateway_stage.ipify_stage_json.invoke_url
}

output "ipify_plain_url" {
  value = aws_api_gateway_stage.ipify_stage_plain.invoke_url
}
