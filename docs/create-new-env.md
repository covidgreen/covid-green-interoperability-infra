#How to create new interop environment


## Create an AWS profile
Add a interop-ENV profile to `~/.aws/credentials`,
where ENV stands for the name of your environment, e.g. `dev`, `qa` or `prod`

## Create the Terraform state backend
Assuming covid-tracker-infrastructure repo is cloned in the same directory as current project:

See [../../covid-tracker-infrastructure/scripts/create-tf-state-backend.sh] script

```
# Set your AWS_PROFILE
export AWS_PROFILE=interop-dev
export AWS_REGION=eu-west-1

# Create
./../../covid-tracker-infrastructure/scripts/create-tf-state-backend.sh eu-west-1 interop-dev-terraform-store interop-dev-terraform-lock
```


## Create the AWS SecretsManager secrets


### header-x-secret Secret
The `header-x-secret` secret is used to secure communication between the APIGateway and ALB for the API traffic.

The secret value should be a random alphanumeric string 96 characters in length.

The format of the secret is as follows:
```json
{
  "header-secret":"Some random 96 alpanumeric characters"
}
```

### jwt Secret
The `jwt` secret is used for signing the JSON Web Tokens with the HMAC algorithm. These are issued to users for API authentication,
and the signature is checked by the service to ensure their legitimacy.

The secret value should be a random string 32 characters in length.

The format of the secret is as follows:
```json
{
  "key": "32 random characters"
}
```

### RDS Secrets
The `rds` secret contains the master RDS credentials.

The format of the secret is as follows:
```json
{
  "password":"A strong password",
  "username":"rds_admin_user"
}
```

The `rds-read-only`, `rds-read-write`, `rds-read-write-create` secrets contains the application RDS credentials.
The format of the secret is as follows:
```json
{
  "password":"A strong password",
  "username":"user_name"
}
```

## Create the env-vars files

| File                    | Content                                                      |
| ------------------------| -----------------------------------------------------------  |
| env-vars/ENV.tfvars     | Contains the Interop values that are specific to the dev env |

