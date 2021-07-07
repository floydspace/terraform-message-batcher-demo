# terraform-message-batcher-demo

*SQS Message Batcher Demo App* is built on top of AWS DynamoDB as a buffer messages storage which collects messages and in 10s delay handles messages in batch.
The stack also contains AWS AppSync Api for visual demo UI

### How to deploy

1. You have to have `terraform` installed
2. Configure state:
  - If you wish to use remote state: Create manually an S3 Bucket for state and AWS DynamoDB for lock and put their names in `versions.tf` (DyanmoDB table must have `LockID` string primary key)
  - If you keep state local: Remove `backend` from `versions.tf`
3. Run `terraform init` to initialize providers and modules
4. Run `make deploy` to deploy the stack to AWS
