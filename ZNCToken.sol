// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZNCToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("ZenCoin", "ZNC") Ownable(0x32C9894449c6D720e7aBe483d296061C6c203661) {
        transferOwnership(initialOwner); // Transfer ownership to the initialOwner
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}
