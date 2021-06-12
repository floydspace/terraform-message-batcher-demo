.PHONY: prepare_config
prepare_config:
	@aws s3 cp s3://bgen-terraform-backend/message-batcher-dev/terraform.tfstate - | jq -r "{apiUrl: .outputs.api_url.value, wsUrl: .outputs.ws_url.value, apiKey: .outputs[\"x-api-key\"].value}" > ./src/config.json

.PHONY: build
build:
	@make prepare_config
	@npm run build

.PHONY: deploy
deploy:
	@make build
	@terraform apply -auto-approve
