ifneq (,$(wildcard .env))
  include .env
  export
endif

deployToSepolia:
	forge create --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --etherscan-api-key $(ETHERSCAN_API_KEY) --broadcast --verify $(ARGS) -vvvv

testSepolia:
	forge script $(PATH) --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY_ACCOUNT1) --broadcast -vvvv

testMatchMakingSepolia:
	forge test test/MatchMakingTest.t.sol --fork-url $(SEPOLIA_RPC_URL) -vvvv 

testMatchMakingMainnet:
	forge test test/MatchMakingTest.t.sol --fork-url $(MAINNET_RPC_URL) -vvvv 

deployDAppOnSepolia:
	forge script script/DeployDApp.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY_ACCOUNT0) --etherscan-api-key $(ETHERSCAN_API_KEY) --broadcast --verify -vvvv

deployToAmoy:
	forge script script/DeployDApp.s.sol --rpc-url $(AMOY_RPC_URL) --private-key $(MAIN_ACCOUNT_PRIVATE_KEY) --etherscan-api-key $(POLYSCAN_API_KEY) --broadcast --verify $(ARGS) -vvvv


# Start local anvil chain
anvil-node:
	anvil \
		--port 8545 \
		--chain-id 31337 \
		--block-time 5 \
		--accounts 10 \
		--balance 1000

# Deploy to local anvil
deploy-local:
	forge script script/DeployDApp.s.sol \
		--fork-url http://localhost:8545 \
		--private-key 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97 \
		--broadcast \
		-vvvv

# Test on local anvil
test-local:
	forge test \
		--fork-url http://localhost:8545 \
		-vvvv