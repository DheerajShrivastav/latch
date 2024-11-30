// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { IGameToken } from "../interfaces/iGameToken.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
contract TokenMarket is ReentrancyGuard, AccessControl {

    bytes32 constant MANAGER = 0xaf290d8680820aad922855f39b306097b20e28774d6c1ad35a20325630c3a02c;

    // immutable
    IGameToken public immutable SALE_TOKEN;

    // error
    error insufficientAmount();
    error transactionFailed();

    uint256 pricePerToken = 0.001 ether;

    constructor(IGameToken _saleToken) {
        SALE_TOKEN =  _saleToken;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER, address(_saleToken));
    }

    function buyToken(uint256 _amount) nonReentrant external payable {
        // Calculate the required ETH for the requested token amount
        uint256 requiredETH = _amount * pricePerToken;
        if(msg.value < requiredETH) revert insufficientAmount();

        // Mint the requested amount of tokens to the sender
        SALE_TOKEN.mint(msg.sender, _amount);

        // Calculate any refund (if the user sent more than required)
        uint256 refund = msg.value - requiredETH;
        if (refund > 0) {
            transferETH(requiredETH);
        }
    }

    function sellToken(uint256 _amount) nonReentrant external {
        // Calculate the required ETH for the requested token amount
        uint256 requiredETH = _amount * pricePerToken;

        // Transfer the requested amount of tokens from the user to this 
        SALE_TOKEN.transferFrom(msg.sender, address(this), _amount);

        // Burn the requested amount of tokens to the sender
        SALE_TOKEN.burn(_amount);

        // transfer the required amount of ETH
        transferETH(requiredETH);
    }

    function transferETH(uint256 _amount) private {
        (bool _isOk,) = msg.sender.call{value:_amount}(""); 
        if(!_isOk) revert transactionFailed();   
    }
}