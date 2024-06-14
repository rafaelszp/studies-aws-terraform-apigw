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

```
