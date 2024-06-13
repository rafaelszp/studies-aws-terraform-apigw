terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
    region = "us-east-1" # Para este laboratório é necessário estar na região de N.Virginia (us-east-1)
}
    
### CRIACAO DA API GATEWAY ###
resource "aws_api_gateway_rest_api" "minha-api-gw" {
  name        = "minha-api-gw"
  description = "minha-api-gw"
}

### CRIACAO DO METODO GET MOCKADO ###
resource "aws_api_gateway_method" "MOCK_GET" {
  rest_api_id          = aws_api_gateway_rest_api.minha-api-gw.id
  resource_id          = aws_api_gateway_rest_api.minha-api-gw.root_resource_id
  http_method          = "GET"
  authorization = "NONE"
}

### CRIACAO DO INTEGRADOR MOCKADO ###
resource "aws_api_gateway_integration" "MOCK_INTEGRATION" {
  rest_api_id          = aws_api_gateway_rest_api.minha-api-gw.id
  resource_id          = aws_api_gateway_rest_api.minha-api-gw.root_resource_id
  http_method          = aws_api_gateway_method.MOCK_GET.http_method
  type                 = "MOCK"
  request_templates = {
    "application/json" = "{statusCode : 200}"
  }
  
}

### CRIACAO DA RESPOSTA DO METODO GET MOCKADO ###
resource "aws_api_gateway_method_response" "MOCK_RESPONSE_200" {
  rest_api_id          = aws_api_gateway_rest_api.minha-api-gw.id
  resource_id          = aws_api_gateway_rest_api.minha-api-gw.root_resource_id
  http_method          = aws_api_gateway_method.MOCK_GET.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }

}

### CRIACAO DA RESPOSTA DO INTEGRADOR MOCKADO ###
resource "aws_api_gateway_integration_response" "MOCK_INTEGRATION_RESPONSE" {
  rest_api_id          = aws_api_gateway_rest_api.minha-api-gw.id
  resource_id          = aws_api_gateway_rest_api.minha-api-gw.root_resource_id
  http_method          = aws_api_gateway_method.MOCK_GET.http_method
  status_code          = aws_api_gateway_method_response.MOCK_RESPONSE_200.status_code
}

#### Alteracao RAFAEL
resource "aws_api_gateway_deployment" "MY_DEPLOYMENT" {
  rest_api_id = aws_api_gateway_rest_api.minha-api-gw.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.MOCK_GET.id,
      aws_api_gateway_integration.MOCK_INTEGRATION.id
    ]))
  }
}

resource "aws_api_gateway_stage" "MY_STAGE" {
  deployment_id = aws_api_gateway_deployment.MY_DEPLOYMENT.id
  stage_name = "api"
  rest_api_id = aws_api_gateway_rest_api.minha-api-gw.id
}

resource "aws_api_gateway_stage" "DEV_STAGE" {
  deployment_id = aws_api_gateway_deployment.MY_DEPLOYMENT.id
  stage_name = "dev-api"
  rest_api_id = aws_api_gateway_rest_api.minha-api-gw.id
}


output "minha-api-url" {
  value = aws_api_gateway_stage.MY_STAGE.invoke_url
}
output "minha-dev-api-url" {
  value = aws_api_gateway_stage.DEV_STAGE.invoke_url
}