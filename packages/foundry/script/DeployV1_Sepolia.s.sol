// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/factories/BondFactory.sol";
import "../contracts/factories/UserFactory.sol";
import "../contracts/settings/UserFactorySettings.sol";
import "../contracts/settings/UserSettings.sol";

import "../contracts/Registry.sol";
import "../contracts/IdentityRegistry.sol";
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

contract DeployV1_Sepolia is ScaffoldETHDeploy {
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
        require(getChain().chainId == 11155111, "Only Base supported");

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
                    0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951,
                    0x16dA4541aD1807f4443d92D26044C1147406EB80,
                    0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8
                )
            )
        );

        YieldProviderService yps = YieldProviderService(address(ypsProxy));

        console.logString(string.concat("YieldProviderService deployed at: ", vm.toString(address(yps))));

        UserFactorySettings settingsImpl = new UserFactorySettings();
        ERC1967Proxy settingsProxy = new ERC1967Proxy(address(settingsImpl),abi.encodeCall(UserFactorySettings.initialize, ()));
        UserFactorySettings settings = UserFactorySettings(address(settingsProxy));

        console.logString(string.concat("UserFactorySettings deployed at: ", vm.toString(address(settings))));

        UserSettings userSettingsImpl = new UserSettings();
        ERC1967Proxy userSettingsProxy = new ERC1967Proxy(address(userSettingsImpl),abi.encodeCall(UserSettings.initialize, ()));
        UserSettings userSettings = UserSettings(address(userSettingsProxy));

        console.logString(string.concat("UserSettings deployed at: ", vm.toString(address(userSettings))));

        Registry registryImpl = new Registry();
        ERC1967Proxy registryProxy = new ERC1967Proxy(address(registryImpl),abi.encodeCall(Registry.initialize, ("1.0")));
        Registry registry = Registry(address(registryProxy));

        console.logString(string.concat("Registry deployed at: ", vm.toString(address(registry))));
        
        IdentityRegistry identityRegistryImpl = new IdentityRegistry();
        ERC1967Proxy identityRegistryProxy = new ERC1967Proxy(address(identityRegistryImpl),abi.encodeCall(IdentityRegistry.initialize, ()));
        IdentityRegistry identityRegistry = IdentityRegistry(address(identityRegistryProxy));

        console.logString(string.concat("IdentityRegistry deployed at: ", vm.toString(address(identityRegistry))));

        UserFactory userFactoryImpl = new UserFactory();
        ERC1967Proxy userFactoryProxy =
            new ERC1967Proxy(address(userFactoryImpl), abi.encodeCall(UserFactory.initialize, (address(settings), address(registry), address(userSettings), address(identityRegistry))));
        UserFactory userFactory = UserFactory(address(userFactoryProxy));
        
        console.logString(string.concat("UserFactory deployed at: ", vm.toString(address(userFactory))));

        // registry.addTrustedUpdater(address(userFactory));
    }
}
