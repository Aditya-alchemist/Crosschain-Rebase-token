// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {CCIPLocalSimulatorFork} from "../lib/chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {Register} from "../lib/chainlink-local/src/ccip/Register.sol";
import {IERC20} from "../lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {RegistryModuleOwnerCustom} from "../lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "../lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";


contract TokenandPoolDeployer is Script{
    function run() public returns(RebaseToken rebaseToken, RebaseTokenPool rebaseTokenPool){
        CCIPLocalSimulatorFork cciplsf= new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory networkdetails = cciplsf.getNetworkDetails(block.chainid);
        vm.startBroadcast();
        rebaseToken = new RebaseToken();
        rebaseTokenPool= new RebaseTokenPool(IERC20(address(rebaseToken)),new address[](0),networkdetails.rmnProxyAddress,networkdetails.routerAddress);
        rebaseToken.grantMintAndBurnRole(address(rebaseTokenPool));
        RegistryModuleOwnerCustom(networkdetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(rebaseTokenPool));
        TokenAdminRegistry(networkdetails.tokenAdminRegistryAddress).acceptAdminRole(address(rebaseTokenPool));
        TokenAdminRegistry(networkdetails.tokenAdminRegistryAddress).setPool(address(rebaseToken),address(rebaseTokenPool));   
        vm.stopBroadcast();
    }
}

contract VaultDeployer is Script{
    function run(address _rebaseToken) public returns(Vault vault){
        vm.startBroadcast();
         vault = new Vault(IRebaseToken(_rebaseToken));
        IRebaseToken(_rebaseToken).grantMintAndBurnRole(address(vault));
        vm.stopBroadcast();
      }
}