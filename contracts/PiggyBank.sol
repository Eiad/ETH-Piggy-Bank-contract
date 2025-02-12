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

    function deposit(uint256 _lockTime) external payable {
        if (msg.value == 0) revert MustSendETH();
        if (deposits[msg.sender].amount > 0) revert AlreadyDeposited();

        uint256 unlockTime = block.timestamp + _lockTime;
        deposits[msg.sender] = Deposit(msg.value, unlockTime);

        emit Deposited(msg.sender, msg.value, unlockTime);
    }

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

    function getDeposit(address _user) external view returns (uint256 amount, uint256 unlockTime) {
        Deposit memory userDeposit = deposits[_user];
        return (userDeposit.amount, userDeposit.unlockTime);
    }
}