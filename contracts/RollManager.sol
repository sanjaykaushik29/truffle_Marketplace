// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RoleManager is
    Initializable,
    AccessControlEnumerableUpgradeable,
    OwnableUpgradeable
{
    bytes32 public constant operatorRole = bytes32("Operator Role");

    function initialize1() public initializer {
        __Ownable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(operatorRole, DEFAULT_ADMIN_ROLE);
    }

    modifier isOperator() {
        require(
            hasRole(operatorRole, msg.sender) || owner() == msg.sender,
            "RoleManager: For operator or admin Role only"
        );
        _;
    }

    function addOperators(address[] memory operators) external onlyOwner {
        for (uint256 index = 0; index < operators.length; index++) {
            _grantRole(operatorRole, operators[index]);
        }
    }

    function removeOperators(address[] memory operators) external onlyOwner {
        for (uint256 index = 0; index < operators.length; index++) {
            _revokeRole(operatorRole, operators[index]);
        }
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _revokeRole(operatorRole, msg.sender);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
