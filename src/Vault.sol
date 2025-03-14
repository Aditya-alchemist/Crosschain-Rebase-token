// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";


contract Vault{

    event Deposit(address indexed user,uint256 amount);
    event Redeem(address indexed user,uint256 amount);

    error Vault__RedeemFailed();

    IRebaseToken private immutable i_rebaseToken;

    constructor(IRebaseToken _RebaseToken)  {
        i_rebaseToken = _RebaseToken;
    }


    function getRebaseToken() external view returns(address){
        return address(i_rebaseToken);
    }

    receive() external payable{}

    function deposit()  external payable {
      i_rebaseToken.mint(msg.sender,msg.value);
      emit Deposit(msg.sender,msg.value);
    }
    

     function redeem(uint256 _amount) external {


        i_rebaseToken.burn(msg.sender,_amount);
        (bool success, ) = payable(msg.sender).call{value:_amount}("");
        if(!success){
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender,_amount);


    }
}
