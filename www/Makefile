.PHONY: prepare_config
prepare_config:
	@aws s3 cp s3://bgen-terraform-backend/message-batcher-dev/terraform.tfstate - | jq -r "{apiUrl: .outputs.api_url.value, apiKey: .outputs[\"x-api-key\"].value}" > ./src/config.json

.PHONY: prepare_static
prepare_static:
	@echo '{"clean_urls":true,"routes":{"/static/*":"/static/","/**":"index.html"}}' > ./build/static.json

.PHONY: build
build:
	@make prepare_config
	@npm run build
	# @make prepare_static

.PHONY: deploy
deploy:
	@make build
	@terraform apply -auto-approve
