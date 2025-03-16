// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "../lib/openzepplin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzepplin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "../lib/openzepplin-contracts/contracts/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @author Aditya
 * @dev Implementation of the RebaseToken
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    error INTEREST_RATE_CAN_NOT_BE_INCREASED();

    event InterestRateChanged(uint256 newInterestRate);

    uint256 private s_interestRate = 5e10;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    uint256 private constant PRECISON_FACTOR = 1e18;

    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastTimestamp;

    constructor() ERC20("Rebasetoken", "RBT") Ownable() {}

    /*
        * @dev function to calculate the interest rate
        * @param _amount the amount to calculate the interest rate
        * @notice interest rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        if (_newInterestRate > s_interestRate) {
            revert INTEREST_RATE_CAN_NOT_BE_INCREASED();
        }
        s_interestRate = _newInterestRate;
        emit InterestRateChanged(_newInterestRate);
    }

    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    function mint(address _to, uint256 _amount, uint256 _userInterestRate) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = _userInterestRate;
        _mint(_to, _amount);
    }

    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }

    /*
    * @dev function to calculate the interest rate of the user
    */
    function balanceOf(address _user) public view override returns (uint256) {
        return (super.balanceOf(_user) * _calculateUserIntrestSinceLastUpdate(_user)) / PRECISON_FACTOR;
    }

    function _calculateUserIntrestSinceLastUpdate(address _user) internal view returns (uint256 linearIntrest) {
        //linear intrest = (priciple amount)+ principle amount * interest rate * timeelapsed
        //taking common otside the bracket priciple amount and multiplying with balance of in balance of
        uint256 timeElapsed = block.timestamp - s_userLastTimestamp[_user];
        linearIntrest = (PRECISON_FACTOR + (s_userInterestRate[_user] * timeElapsed));
    }

    /*
    * @dev function to determine the interest of  the user
    */
    function _mintAccruedInterest(address _user) internal {
        //balance of the user
        uint256 previousPrincipleBalance = super.balanceOf(_user);
        //balance with interest
        uint256 balanceWithInterest = balanceOf(_user);
        //2-1 = interest
        uint256 interest = balanceWithInterest - previousPrincipleBalance;

        //mint the interest
        _mint(_user, interest);

        //updated time stamp
        s_userLastTimestamp[_user] = block.timestamp;
    }

    /*
    * @dev function to burn the token
    * @param type(uint256).max represents total balance of the user (to burn all the tokens of the user)
    */
    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }

        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(_recipient);
        _mintAccruedInterest(msg.sender);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(_recipient);
        _mintAccruedInterest(_sender);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    function principlebalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    function getinterestrate() external view returns (uint256) {
        return s_interestRate;
    }
}
