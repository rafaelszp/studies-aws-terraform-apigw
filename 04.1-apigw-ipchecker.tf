## API - Lambda checker 


resource "aws_apigatewayv2_api" "apigw_ip_checker_api" {
  name =  "apigw_ip_checker_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "apigw_ip_checker_integration" {
  api_id = aws_apigatewayv2_api.apigw_ip_checker_api.id

  integration_method = "GET"
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.lambda_ip_checker.arn
}

resource "aws_apigatewayv2_route" "apigw_ip_checker_route" {
  api_id = aws_apigatewayv2_api.apigw_ip_checker_api.id

  route_key = "GET /ipinfo"
  target = "integrations/${aws_apigatewayv2_integration.apigw_ip_checker_integration.id}"
}

resource "aws_cloudwatch_log_group" "apigw_ip_checker_log_group" {
  name = "/aws/apigateway/${aws_apigatewayv2_api.apigw_ip_checker_api.name}"
  retention_in_days = 1
  
}

resource "aws_apigatewayv2_stage" "apigw_ip_checker_stage_api" {
  api_id = aws_apigatewayv2_api.apigw_ip_checker_api.id
  name = "api"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_ip_checker_log_group.arn
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
      stage = "api"
      }
    )
  }
}

resource "aws_lambda_permission" "apigw_ip_checker_permission" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ip_checker.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.apigw_ip_checker_api.execution_arn}/*/*"
}

output "ipinfo_url" {
  value = aws_apigatewayv2_stage.apigw_ip_checker_stage_api.invoke_url
}
