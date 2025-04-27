pragma solidity ^0.8.20;

// Import OpenZeppelin's ERC20 contract for standard token functionality
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("StakingToken", "STK") Ownable(initialOwner) {
        _mint(initialOwner, 1_000_000 * 10 ** decimals()); // Mint initial supply to owner
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}