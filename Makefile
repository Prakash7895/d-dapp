ifneq (,$(wildcard .env))
  include .env
  export
endif

deployToSepolia:
	forge create --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --etherscan-api-key $(ETHERSCAN_API_KEY) --broadcast --verify $(ARGS) -vvvv