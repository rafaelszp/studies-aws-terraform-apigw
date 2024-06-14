# Mission: Create a HTTP API with the following features
# 1. HTTP mapping template
# 2. HTTP transform output
# 3. Log with cloudwatch

# https://docs.freeipapi.com/request.html#endpoint

variable "ipify_url" {
  default = "https://ipapi.co/{ip}/country/"
}

resource "aws_apigatewayv2_api" "ipapi_gw" {
  name          = "ipapi-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "ipapi_country_integration" {
  api_id           = aws_apigatewayv2_api.ipapi_gw.id
  integration_type = "HTTP_PROXY"

  integration_method = "GET"
  integration_uri    = var.ipify_url
}

resource "aws_apigatewayv2_route" "ipapi_country_route" {
  api_id    = aws_apigatewayv2_api.ipapi_gw.id
  route_key = "GET /{ip}"
  target    = "integrations/${aws_apigatewayv2_integration.ipapi_country_integration.id}"
}

resource "aws_apigatewayv2_stage" "ipapi_country_stage" {
  api_id      = aws_apigatewayv2_api.ipapi_gw.id
  name        = "country"
  auto_deploy = true
  stage_variables = {
    "format" = "country"
  }
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.ipapi_log_group.arn
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
      path = "$context.path"
      }
    )
  }
}


output "country_test_cmd" {
  value = "http --verify=false ${aws_apigatewayv2_stage.ipapi_country_stage.invoke_url}"
}


### CloudWatch log group

resource "aws_cloudwatch_log_group" "ipapi_log_group" {
  name              = "IPAPI-LOG-GROUP"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_stream" "ipapi_log_stream" {
  name           = "ipapi-log-stream"
  log_group_name = aws_cloudwatch_log_group.ipapi_log_group.name
}


###CLOUDWATCH

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudwatch" {
  name               = "api_gateway_cloudwatch_global"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


data "aws_iam_policy_document" "cloudwatch" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cloudwatch" {
  name   = "api_gw_role_cloudwatch"
  role   = aws_iam_role.cloudwatch.id
  policy = data.aws_iam_policy_document.cloudwatch.json
}

resource "aws_api_gateway_account" "api_gw_account" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}
