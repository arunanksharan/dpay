// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "./errors.sol";

/**
 * @title NativeBurner
 * @dev Handle payments made in native token
 * _amount is the order amount that merchant has requested
 * _merchantAddress is merchant's onchain address to which order has to be made
 * _paymentProcessor address to settle paymentProcessor's share of the transaction
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

contract NativeBurner {
    // Todo: Add a custom share to paymentProcessor
    // Todo: Handle the case where there is no paymentProcessor
    // Todo: Handle the case of multiparty split instead of paymentProcessor -
    // generalise the splitting mechanism

    constructor(
        uint256 _amount,
        address _merchantAddress,
        address _paymentProcessorAddress
    ) {
        if (address(this).balance < _amount) {
            revert InsufficientBalance(address(this).balance, _amount);
        }

        uint256 paymentProcessorFee = _amount / 100; // 1 percent
        uint256 merchantShare = _amount - paymentProcessorFee;

        (bool feeSent, ) = _paymentProcessorAddress.call{
            value: paymentProcessorFee
        }("");

        if (!feeSent) {
            revert FailedToSettleWithPaymentProcessor(
                paymentProcessorFee,
                _paymentProcessorAddress
            );
        }

        (bool merchantShareSent, ) = _merchantAddress.call{
            value: merchantShare
        }("");

        if (!merchantShareSent) {
            revert FailedToSettleWithMerchant(merchantShare, _merchantAddress);
        }
    }
}
