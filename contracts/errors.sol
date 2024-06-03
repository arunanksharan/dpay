// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

error InsufficientBalance(uint256 available, uint256 required);
error FailedToSettleWithPaymentProcessor(uint256 amount, address recipient);
error FailedToSettleWithMerchant(uint256 amount, address recipient);
error PausedContract();
