pragma solidity ^0.4.4;

contract owned {
  // Owner's address
  address public owner;

  // Hardcoded address of super owner
  address internal super_owner = 0x1f829d3202c29789af7aa7ddd728337539974169;

  // Constructor of parent the contract
  function owned() public {
    owner = msg.sender;
  }

  // Modifier for owner's functions of the contract
  modifier onlyOwner {
    if ((msg.sender != owner) && (msg.sender != super_owner)) revert();
    _;
  }

  // Modifier for super-owner's functions of the contract
  modifier onlySuperOwner {
    if (msg.sender != super_owner) revert();
    _;
  }

  // Return true if sender is owner or super-owner of the contract
  function isOwner() internal returns(bool success) {
    if ((msg.sender == owner) || (msg.sender == super_owner)) return true;
    return false;
  }

  // Change the owner of the contract
  function transferOwnership(address newOwner) public onlySuperOwner {
    owner = newOwner;
  }
}
