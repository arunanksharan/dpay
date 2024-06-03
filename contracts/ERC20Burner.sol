// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./errors.sol";

/**
 * @title NativeBurner
 * @dev Handle payments made in native token |
 * _tokenAddress is the erc20 token |
 * _amount is the order amount that merchant has requested
 * _merchantAddress is merchant's onchain address to which order has to be made
 * _paymentProcessor address to settle paymentProcessor's share of the transaction
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

contract ERC20Burner {
    // Todo: Add a custom share to paymentProcessor
    // Todo: Handle the case where there is no paymentProcessor
    // Todo: Handle the case of multiparty split instead of paymentProcessor -
    // generalise the splitting mechanism

    constructor(
        address _tokenAddress,
        uint256 _amount,
        address _merchantAddress,
        address _paymentProcessorAddress
    ) {
        IERC20 token = IERC20(_tokenAddress);

        if (token.balanceOf(address(this)) < _amount) {
            revert InsufficientBalance(token.balanceOf(address(this)), _amount);
        }

        uint256 paymentProcessorFee = _amount / 100;
        uint256 merchantShare = _amount - paymentProcessorFee;

        token.transfer(_paymentProcessorAddress, paymentProcessorFee);
        token.transfer(_merchantAddress, merchantShare);
    }
}
