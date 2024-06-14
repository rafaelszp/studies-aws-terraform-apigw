## REST API
resource "aws_api_gateway_rest_api" "httpbin" {
  name        = "HTTP Bin"
  description = "HTTPBin example"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

## Resources
resource "aws_api_gateway_resource" "httpbin_get" {
  rest_api_id = aws_api_gateway_rest_api.httpbin.id
  parent_id   = aws_api_gateway_rest_api.httpbin.root_resource_id
  path_part   = "get"
}

resource "aws_api_gateway_resource" "httpbin_post" {
  rest_api_id = aws_api_gateway_rest_api.httpbin.id
  parent_id   = aws_api_gateway_rest_api.httpbin.root_resource_id
  path_part   = "post"
}

## HTTPBIN GET METHOD and Integration
resource "aws_api_gateway_method" "proxy_get" {
  rest_api_id   = aws_api_gateway_rest_api.httpbin.id
  resource_id   = aws_api_gateway_resource.httpbin_get.id
  http_method   = "GET"
  authorization = "NONE"
  # request_parameters = {
  #   "method.request.querystring.nome" = true
  # }
}

resource "aws_api_gateway_integration" "httpbin_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.httpbin.id
  resource_id             = aws_api_gateway_resource.httpbin_get.id
  http_method             = aws_api_gateway_method.proxy_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "https://httpbin.org/get"

  # request_parameters = {
  #   "integration.request.querystring.nome" = "method.request.querystring.nome"
  # }


}

resource "aws_api_gateway_method_response" "proxy_get_response" {
  rest_api_id = aws_api_gateway_rest_api.httpbin.id
  resource_id = aws_api_gateway_resource.httpbin_get.id
  http_method = aws_api_gateway_method.proxy_get.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "httpbin_get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.httpbin.id
  resource_id = aws_api_gateway_resource.httpbin_get.id
  http_method = aws_api_gateway_method.proxy_get.http_method
  status_code = aws_api_gateway_method_response.proxy_get_response.status_code

  depends_on = [
    aws_api_gateway_method.proxy_get,
    aws_api_gateway_integration.httpbin_get_integration
  ]
}

## HTTPBIN POST Method and Integration
resource "aws_api_gateway_method" "proxy_post" {
  rest_api_id   = aws_api_gateway_rest_api.httpbin.id
  resource_id   = aws_api_gateway_resource.httpbin_post.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "httpbin_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.httpbin.id
  resource_id             = aws_api_gateway_resource.httpbin_post.id
  http_method             = aws_api_gateway_method.proxy_post.http_method
  integration_http_method = "POST"
  type                    = "HTTP"
  uri                     = "https://httpbin.org/post"
}

resource "aws_api_gateway_method_response" "proxy_post_response" {
  rest_api_id = aws_api_gateway_rest_api.httpbin.id
  resource_id = aws_api_gateway_resource.httpbin_post.id
  http_method = aws_api_gateway_method.proxy_post.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "httpbin_post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.httpbin.id
  resource_id = aws_api_gateway_resource.httpbin_post.id
  http_method = aws_api_gateway_method.proxy_post.http_method
  status_code = aws_api_gateway_method_response.proxy_post_response.status_code

  depends_on = [
    aws_api_gateway_method.proxy_post,
    aws_api_gateway_integration.httpbin_post_integration
  ]
}

# Deployments and stages

## OBTENCAO deployment and stage

resource "aws_api_gateway_deployment" "httpbin_deployment" {
  rest_api_id = aws_api_gateway_rest_api.httpbin.id

  lifecycle {
    create_before_destroy = true
  }

  triggers = {

    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.httpbin,
      aws_api_gateway_method.proxy_get,
      aws_api_gateway_method.proxy_post,
      aws_api_gateway_integration.httpbin_get_integration,
      aws_api_gateway_integration.httpbin_post_integration
    ]))
  }
}

resource "aws_api_gateway_stage" "get_stage" {
  rest_api_id   = aws_api_gateway_rest_api.httpbin.id
  deployment_id = aws_api_gateway_deployment.httpbin_deployment.id
  stage_name    = "api"
}


output "httpbin-url" {
  value = aws_api_gateway_stage.get_stage.invoke_url
}