## API GATEWAY + TERRAFORM


## PREREQS

```bash 
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```


## Runnig

```shell
terraform init
terraform plan
terraform apply -auto-approve
```

## check
```shell
aws get-rest-apis --region us-east-1

http --verify=false $(terraform output -raw ipify_plain_url)  
fish  -c  $(terraform output -raw country_test_cmd)/53.24.222.11 
fish  -c  $(terraform output -raw json_test_cmd)/177.24.222.11
fish  -c  $(terraform output -raw json_test_cmd)/192.172.222.11 
```





## References
1. https://docs.aws.amazon.com/pt_br/apigateway/latest/developerguide/api-gateway-swagger-extensions-integration-requestParameters.html
2. https://docs.aws.amazon.com/pt_br/apigateway/latest/developerguide/http-api-develop-integrations-aws-services.html
3. https://repost.aws/knowledge-center/custom-headers-api-gateway-lambda
4. https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-parameter-mapping.html#http-api-mapping-reserved-headers