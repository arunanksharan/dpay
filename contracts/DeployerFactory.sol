// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Deployer.sol";

contract DeployerFactory is Ownable {
    event DeployerCreated(
        address indexed deployerAddress,
        string _appName,
        address indexed deployedBy
    );

    // isPaused Check
    bool isPaused = true;

    function pauseContract() public onlyOwner {
        isPaused = !isPaused;
    }

    // Owner of DeployerFactory - record/administrative purposes
    // address public deployerFactoryOwner;

    constructor(address initialOwner) Ownable(initialOwner) {
        // deployerFactoryOwner = msg.sender;
    }

    function renounceDeployerFactoryOwnership() public {
        renounceOwnership();
    }

    // Registry: Which address created a particular deployer instance & its appName
    // Creating Deployer Instance
    struct DeployerInfo {
        string appName;
        address deployedBy;
    }

    // Mapping for storing deployer information
    mapping(address => DeployerInfo) public deployers;

    // Call Deployer & its constructor with parameters
    // Create a new deployer instance
    // Todo: parametrise _oownership - allow people to make others owner instead of the creator
    // Validations required
    function createDeployer(string memory _appName) public {
        Deployer newDeployer = new Deployer(_appName, msg.sender);

        // Update deployer mapping
        deployers[address(newDeployer)] = DeployerInfo({
            appName: _appName,
            deployedBy: msg.sender
        });

        // Emit an event that a deployer instance ahs been created
        emit DeployerCreated(address(newDeployer), _appName, msg.sender);
    }
}
