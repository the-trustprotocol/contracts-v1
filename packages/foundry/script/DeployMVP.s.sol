// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/factories/BondFactory.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { YieldProviderService } from "../contracts/YieldProviderService.sol";
/**
 *
 * @notice Deploy script for YourContract contract
 * @dev Inherits ScaffoldETHDeploy which:
 *      - Includes forge-std/Script.sol for deployment
 *      - Includes ScaffoldEthDeployerRunner modifier
 *      - Provides `deployer` variable
 * Example:
 * yarn deploy --file DeployYourContract.s.sol  # local anvil chain
 * yarn deploy --file DeployYourContract.s.sol --network optimism # live network (requires keystore)
 */

contract DeployYourContract is ScaffoldETHDeploy {
    /**
     * @dev Deployer setup based on `ETH_KEYSTORE_ACCOUNT` in `.env`:
     *      - "scaffold-eth-default": Uses Anvil's account #9 (0xa0Ee7A142d267C1f36714E4a8F75612F20a79720), no password prompt
     *      - "scaffold-eth-custom": requires password used while creating keystore
     *
     * Note: Must use ScaffoldEthDeployerRunner modifier to:
     *      - Setup correct `deployer` account and fund it
     *      - Export contract addresses & ABIs to `nextjs` packages
     */
    function run() external ScaffoldEthDeployerRunner {
        require(getChain().chainId == 8453, "Only Base supported");

        BondFactory bondFactoryImpl = new BondFactory();
        ERC1967Proxy bondFactoryProxy =
            new ERC1967Proxy(address(bondFactoryImpl), abi.encodeCall(BondFactory.initialize, ()));
        BondFactory bondFactory = BondFactory(address(bondFactoryProxy));

        console.logString(string.concat("bondFactory Token deployed at: ", vm.toString(address(bondFactory))));

        YieldProviderService ypsImp = new YieldProviderService();
        ERC1967Proxy ypsProxy = new ERC1967Proxy(
            address(ypsImp),
            abi.encodeCall(
                YieldProviderService.initialize,
                (
                    0xA238Dd80C259a72e81d7e4664a9801593F98d1c5,
                    0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB,
                    0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
                )
            )
        );

        YieldProviderService yps = YieldProviderService(address(ypsProxy));

        console.logString(string.concat("YieldProviderService deployed at: ", vm.toString(address(yps))));
    }
}
