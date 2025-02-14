// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PiggyBank {
    struct Deposit {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Deposit) private deposits;

    event Deposited(address indexed user, uint256 amount, uint256 unlockTime);
    event Withdrawn(address indexed user, uint256 amount);

    error NoDepositFound();
    error FundsLocked(uint256 unlockTime);
    error WithdrawFailed();
    error AlreadyDeposited();
    error MustSendETH();

    uint256 constant DEFAULT_LOCK_TIME = 2 minutes;

    /**
     * @dev Allows users to deposit ETH into the PiggyBank with a specified lock time.
     * @param _lockTime The duration (in seconds) for which the funds will be locked.
     * Requirements:
     * - The deposit amount must be greater than zero.
     * - The user must not have an existing deposit.
     */
    function deposit(uint256 _lockTime) external payable {
        if (msg.value == 0) revert MustSendETH();
        if (deposits[msg.sender].amount > 0) revert AlreadyDeposited();

        uint256 unlockTime = block.timestamp + _lockTime;
        deposits[msg.sender] = Deposit(msg.value, unlockTime);

        emit Deposited(msg.sender, msg.value, unlockTime);
    }

    /**
     * @dev Handles direct ETH transfers to the contract
     * Creates a deposit with default lock time of 2 minutes
     */
    receive() external payable {
        if (msg.value == 0) revert MustSendETH();
        if (deposits[msg.sender].amount > 0) revert AlreadyDeposited();

        uint256 unlockTime = block.timestamp + DEFAULT_LOCK_TIME;
        deposits[msg.sender] = Deposit(msg.value, unlockTime);

        emit Deposited(msg.sender, msg.value, unlockTime);
    }

    /**
     * @dev Allows users to withdraw their deposited ETH after the unlock time.
     * Requirements:
     * - The user must have a deposit.
     * - The funds must be unlocked (current time must be greater than or equal to unlock time).
     * Reverts if the withdrawal fails.
     */
    function withdraw() external {
        Deposit memory userDeposit = deposits[msg.sender];
        if (userDeposit.amount == 0) revert NoDepositFound();
        if (block.timestamp < userDeposit.unlockTime) revert FundsLocked(userDeposit.unlockTime);

        uint256 amount = userDeposit.amount;
        deposits[msg.sender] = Deposit(0, 0); // Reset deposit before sending funds

        emit Withdrawn(msg.sender, amount); // Emit event before transfer

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert WithdrawFailed();
    }

    /**
     * @dev Retrieves the deposit details for a specified user.
     * @param _user The address of the user whose deposit details are being requested.
     * @return amount The amount of ETH deposited by the user.
     * @return unlockTime The time at which the funds will be unlocked.
     */
    function getDeposit(address _user) external view returns (uint256 amount, uint256 unlockTime) {
        Deposit memory userDeposit = deposits[_user];
        return (userDeposit.amount, userDeposit.unlockTime);
    }
}