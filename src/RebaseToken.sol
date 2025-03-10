// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "../lib/openzepplin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title RebaseToken
 * @author Aditya
 * @dev Implementation of the RebaseToken
 */
contract RebaseToken is ERC20{

    error INTEREST_RATE_CAN_NOT_BE_INCREASED();

    event InterestRateChanged(uint256 newInterestRate);

    uint256 private s_interestRate=5e10;
    uint256 private constant PRECISON_FACTOR = 1e18;

    mapping (address => uint256) private s_userInterestRate;
    mapping (address => uint256) private s_userLastTimestamp;  


    constructor() ERC20("Rebasetoken","RBT"){}
     
     /*
        * @dev function to calculate the interest rate
        * @param _amount the amount to calculate the interest rate
        * @notice interest rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate ) external{
        if(_newInterestRate>s_interestRate){
            revert INTEREST_RATE_CAN_NOT_BE_INCREASED();
        }
        s_interestRate = _newInterestRate;
        emit InterestRateChanged(_newInterestRate);
    }

    function mint(address _to, uint256 _amount) external{
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to,_amount);
    }

    function getUserInterestRate(address _user) external view returns(uint256){
        return s_userInterestRate[_user];
    }

    function balanceOf(address _user) public view override returns(uint256){
       return  (super.balanceOf(_user)*_calculateUserIntrestSinceLastUpdate(_user))/PRECISON_FACTOR;
    }

    function _calculateUserIntrestSinceLastUpdate(address _user) internal view returns(uint256 linearIntrest){
        //linear intrest = (priciple amount)+ principle amount * interest rate * timeelapsed
        //taking common otside the bracket priciple amount and multiplying with balance of 
        uint256 timeElapsed = block.timestamp - s_userLastTimestamp[_user];
         linearIntrest = (PRECISON_FACTOR+(s_userInterestRate[_user]*timeElapsed));
    }

    function _mintAccruedInterest(address _user) internal {
        //balance of the user
        //balance with interest
        //2-1 = interest
        //updated time stamp
        s_userLastTimestamp[_user] = block.timestamp;
    }
}