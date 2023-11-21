// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedLottery {
    address public admin;
    uint256 public ticketPrice;
    uint256 public lotteryEndTime;
    bool public lotteryClosed;
    address[] public participants;
    mapping(address => bool) public hasParticipated;

    event LotteryWinner(address winner, uint256 prize);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    modifier onlyDuringLottery() {
        require(block.timestamp < lotteryEndTime, "Lottery has ended");
        _;
    }

    modifier onlyAfterLottery() {
        require(block.timestamp >= lotteryEndTime, "Lottery has not ended");
        _;
    }

    constructor(uint256 _ticketPrice, uint256 _lotteryDuration) {
        admin = msg.sender;
        ticketPrice = _ticketPrice;
        lotteryEndTime = block.timestamp + _lotteryDuration;
    }

    function participate() external payable onlyDuringLottery {
        require(msg.value == ticketPrice, "Incorrect ticket price");
        require(!hasParticipated[msg.sender], "Already participated");

        participants.push(msg.sender);
        hasParticipated[msg.sender] = true;
    }

    function closeLottery() external onlyAdmin onlyDuringLottery {
        lotteryClosed = true;
    }

    function conductLottery() external onlyAdmin onlyAfterLottery {
        require(lotteryClosed, "Lottery is still open");

        uint256 participantCount = participants.length;

        // Ensure there are participants
        require(participantCount > 0, "No participants");

        // Select a random winner
        uint256 randomIndex = generateRandomNumber(participantCount);
        address winner = participants[randomIndex];

        // Calculate prize (assuming all funds are distributed)
        uint256 prize = address(this).balance;

        // Transfer prize to the winner
        payable(winner).transfer(prize);

        // Emit winner event
        emit LotteryWinner(winner, prize);
    }
// Simple pseudo-random number generation based on block variables
    function generateRandomNumber(uint256 _modulus) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants))) % _modulus;
    }
// Allow participants to withdraw their funds if the lottery is closed and they didn't win
    function withdrawFunds() external onlyAfterLottery {
        require(lotteryClosed, "Lottery is still open");
        require(!hasParticipated[msg.sender], "Cannot withdraw if you participated and didn't win");

        payable(msg.sender).transfer(ticketPrice);
    }
    // Admin function to retrieve any remaining funds
    function withdrawRemainingFunds() external onlyAdmin onlyAfterLottery {
        require(lotteryClosed, "Lottery is still open");
        payable(admin).transfer(address(this).balance);
    }
}
