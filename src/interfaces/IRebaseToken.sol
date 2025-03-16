// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRebaseToken {
    function mint(address _to, uint256 _amount, uint256 _userInterestRate) external;
    function burn(address _from, uint256 _amount) external;
    function getUserInterestRate(address _user) external view returns (uint256);
    function getinterestrate() external view returns (uint256);
    function grantMintAndBurnRole(address _account) external;
    
}
