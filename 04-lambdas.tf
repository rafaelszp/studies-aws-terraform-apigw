data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_lambda_role" {
  name = "iam_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_role_policy" {
  name = "iam_lambda_role_policy"
  policy = data.aws_iam_policy_document.cloudwatch.json
  role = aws_iam_role.iam_lambda_role.id
}

## LAMBDA IP CHECKER
data "archive_file" "lambda_api_checker_archive" {
  type = "zip"
  source_file = "${path.module}/lambda-ip-checker/index.mjs"
  output_path = "${path.module}/out/lambda_ip_checker_payload.zip"
}

resource "aws_lambda_function" "lambda_ip_checker" {
  filename = "out/lambda_ip_checker_payload.zip"
  function_name = "lambda_ip_checker"
  role = aws_iam_role.iam_lambda_role.arn
  handler = "index.handler"

  source_code_hash = data.archive_file.lambda_api_checker_archive.output_base64sha256
  
  runtime = "nodejs20.x"

  environment {
    variables = {
      IPIFY_URL = aws_api_gateway_stage.ipify_stage_json.invoke_url
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_api_checker_log_group" {
  name = "/aws/lambda/${aws_lambda_function.lambda_ip_checker.function_name}"
  retention_in_days = 1
}


## LAMBDA country finder

data "archive_file" "lambda_country_finder_archive" {
  type = "zip"
  source_file = "${path.module}/lambda-country-finder/index.mjs"
  output_path = "${path.module}/out/lambda_country_finder.zip"
}

resource "aws_lambda_function" "lambda_country_finder" {
  filename = "out/lambda_country_finder.zip"
  function_name = "lambda_country_finder"
  role = aws_iam_role.iam_lambda_role.arn
  handler = "index.handler"

  source_code_hash = data.archive_file.lambda_country_finder_archive.output_base64sha256


  runtime = "nodejs20.x"

  environment {
    variables = {
      COUNTRY_FINDER_URL = aws_apigatewayv2_stage.ipapi_country_stage.invoke_url
    }
  }
  
}

resource "aws_cloudwatch_log_group" "lambda_country_finder_log_group" {
  name = "/aws/lambda/${aws_lambda_function.lambda_country_finder.function_name}"
  retention_in_days = 1
}
