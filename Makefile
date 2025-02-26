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