// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC20Burner.sol";
import "./NativeBurner.sol";

contract Deployer is Ownable {
    // Attributes
    string public appName;

    // logo

    constructor(
        string memory _appName,
        address initialOwner
    ) Ownable(initialOwner) {
        /** Manage through Ownable
         * constructor which is called by FoD
         * @dev called at time of creation of a specific deployer instance
         * @param _appName is the name of the app/company/dao which is creating this deployer
         * @param _owner of this instance of deployer
         * Todo: limit on length of appName etc - handled offchain
         */
        appName = _appName;
        // transferOwnership(initialOwner);
    }

    bool public isPaused = true;

    function pauseContract() public onlyOwner {
        isPaused = !isPaused;
    }

    function predictAddress(
        string memory _salt,
        address _tokenAddress,
        uint256 _amount,
        address _merchantAddress,
        address _paymentProcessorAddress
    ) public view returns (address) {
        /**
         * @title predictAddress
         * @dev Creates the burner contract address
         * @param _salt is the unique identifier for a given order | orderId
         * @param _tokenAddress is the address of the ERC20 token
         * @param _amount is the order amount that merchant has requested
         * @param _merchantAddress is merchant's onchain address to which order has to be made
         * @param _paymentProcessor address to settle paymentProcessor's share of the transaction
         * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
         */

        if (isPaused) revert PausedContract();

        // Generating bytecode for native burner
        bytes memory nativeContractByteCode = abi.encodePacked(
            type(NativeBurner).creationCode,
            abi.encode(_amount),
            abi.encode(_merchantAddress),
            abi.encode(_paymentProcessorAddress)
        );

        // Generating the same ERC20 burner address
        bytes memory erc20ContractByteCode = abi.encodePacked(
            type(ERC20Burner).creationCode,
            abi.encode(_tokenAddress),
            abi.encode(_amount),
            abi.encode(_merchantAddress),
            abi.encode(_paymentProcessorAddress)
        );

        bytes memory contractByteCode = _tokenAddress == address(0)
            ? nativeContractByteCode
            : erc20ContractByteCode;

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                bytes32(keccak256(abi.encodePacked(_salt))),
                keccak256(contractByteCode)
            )
        );
        return (address(uint160(uint(hash))));
    }

    function deploy(
        // Todo: emit events on successful deployment of the burneraddress - explore
        // Add params on custom splitting logic
        string memory _salt,
        address _tokenAddress,
        uint256 _amount,
        address _merchantAddress,
        address _paymentProcessorAddress
    ) public onlyOwner returns (address) {
        if (isPaused) revert PausedContract();

        if (_tokenAddress == address(0)) {
            NativeBurner nativeBurner = new NativeBurner{
                salt: bytes32(keccak256(abi.encodePacked(_salt)))
            }(_amount, _merchantAddress, _paymentProcessorAddress);

            return address(nativeBurner);
        }

        ERC20Burner erc20Burner = new ERC20Burner{
            salt: bytes32(keccak256(abi.encodePacked(_salt)))
        }(_tokenAddress, _amount, _merchantAddress, _paymentProcessorAddress);

        return address(erc20Burner);
    }
}
