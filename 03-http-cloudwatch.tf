# Mission: Create a HTTP API with the following features
# 1. HTTP mapping template
# 2. HTTP transform output
# 3. Log with cloudwatch

# https://docs.freeipapi.com/request.html#endpoint

variable "ipify_url" {
  default = "https://ipapi.co/{ip}/country/"
}

resource "aws_apigatewayv2_api" "ipapi_gw" {
  name = "ipapi-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "ipapi_country_integration" {
  api_id = aws_apigatewayv2_api.ipapi_gw.id
  integration_type = "HTTP_PROXY"

  integration_method = "GET"
  integration_uri = "${var.ipify_url}"
}

resource "aws_apigatewayv2_route" "ipapi_country_route" {
 api_id = aws_apigatewayv2_api.ipapi_gw.id
 route_key = "GET /{ip}"
 target = "integrations/${aws_apigatewayv2_integration.ipapi_country_integration.id}"
}

resource "aws_apigatewayv2_stage" "ipapi_country_stage" {
  api_id = aws_apigatewayv2_api.ipapi_gw.id
  name = "country"
  auto_deploy = true
  stage_variables = {
    "format" = "country"
  }
}


output "country_test_cmd" {
  value = "http --verify=false ${aws_apigatewayv2_stage.ipapi_country_stage.invoke_url}"
}
