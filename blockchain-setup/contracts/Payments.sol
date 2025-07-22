// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Optional: If you want to handle ERC-20 tokens instead of native BDAG
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol"; // If you need owner-specific functions

/**
 * @title Payment
 * @dev A simple smart contract for handling payments on BlockDAG's EVM chain.
 * This version focuses on native BDAG token transfers.
 * For ERC-20 token transfers, you would need to adjust deposit/transfer functions
 * to interact with an IERC20 token contract.
 */
contract Payment {
    // Mapping to store balances of native BDAG held by the contract for each user.
    // Users deposit BDAG into this contract, and then payments are made from these balances.
    mapping(address => uint256) public balances;

    // Event emitted when a payment is successfully processed on-chain.
    event PaymentProcessed(
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        uint256 transactionId // A unique ID for the payment, could come from the sound signal
    );

    // Event emitted when funds are deposited into the contract.
    event FundsDeposited(address indexed user, uint256 amount);

    // Event emitted when funds are withdrawn from the contract.
    event FundsWithdrawn(address indexed user, uint256 amount);

    /**
     * @dev Allows a user to deposit native BDAG into this contract.
     * The deposited BDAG will be stored in the 'balances' mapping.
     * This function is payable, meaning it can receive native blockchain currency.
     */
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Initiates a payment from the sender's balance within this contract
     * to a specified receiver.
     * @param _receiver The address of the recipient.
     * @param _amount The amount of native BDAG to transfer.
     * @param _transactionId A unique identifier for this specific payment,
     * which could be derived from the data transmitted via sound.
     * This helps in tracking and preventing replay attacks if not handled carefully.
     */
    function transferFunds(address payable _receiver, uint256 _amount, uint256 _transactionId) public {
        // Ensure the sender has sufficient balance in the contract
        require(balances[msg.sender] >= _amount, "Insufficient balance in contract");
        // Ensure the amount is greater than zero
        require(_amount > 0, "Transfer amount must be greater than zero");
        // Ensure the receiver is not the zero address
        require(_receiver != address(0), "Receiver cannot be the zero address");
        // Ensure sender is not receiver (optional, but good practice)
        require(msg.sender != _receiver, "Sender and receiver cannot be the same");

        // Deduct the amount from the sender's balance in the contract
        balances[msg.sender] -= _amount;

        // Transfer the native BDAG directly to the receiver's address
        (bool success, ) = _receiver.call{value: _amount}("");
        require(success, "Native BDAG transfer failed");

        // Emit an event to log the successful payment
        emit PaymentProcessed(msg.sender, _receiver, _amount, _transactionId);
    }

    /**
     * @dev Allows a user to withdraw their deposited native BDAG from this contract.
     * @param _amount The amount of native BDAG to withdraw.
     */
    function withdraw(uint256 _amount) public {
        // Ensure the user has sufficient balance to withdraw
        require(balances[msg.sender] >= _amount, "Insufficient balance to withdraw");
        // Ensure the amount is greater than zero
        require(_amount > 0, "Withdrawal amount must be greater than zero");

        // Deduct the amount from the user's balance in the contract
        balances[msg.sender] -= _amount;

        // Transfer the native BDAG to the user's address
        payable(msg.sender).transfer(_amount); // transfer() is safer for simple sends

        // Emit an event to log the successful withdrawal
        emit FundsWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Returns the native BDAG balance of a specific user held within this contract.
     * @param _user The address of the user.
     * @return The balance of the user.
     */
    function getBalance(address _user) public view returns (uint256) {
        return balances[_user];
    }
}
