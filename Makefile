.PHONY: build
build:
	@pip install --target ./lambdas/dynamodb_stream/site-packages -r ./lambdas/dynamodb_stream/requirements.txt

.PHONY: deploy
deploy:
	@make build
	@terraform apply -auto-approve