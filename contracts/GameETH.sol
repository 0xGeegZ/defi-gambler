pragma solidity ^0.6.12;

contract GameETH {
    //TODO add verification with this constant
    uint256 private constant ROLL_IN_PROGRESS = 42;

    uint256 public pwin = 9000; //probability of winning (10000 = 100%)
    uint256 public edge = 190; //edge percentage (10000 = 100%)
    uint256 public maxWin = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
    uint256 public minBet = 100000000000000000 wei; // 0,1 BNB - https://eth-converter.com/
    // uint256 constant minBet = 1 ether; // 1 BNB - https://eth-converter.com/
    uint256 public maxInvestors = 10; //maximum number of investors
    uint256 public houseEdge = 90; //edge percentage (10000 = 100%)
    uint256 public divestFee = 50; //divest fee percentage (10000 = 100%)

    uint256 public emergencyWithdrawalRatio = 10; //ratio percentage (100 = 100%)

    uint256 private safeGas = 25000;
    uint256 private constant INVALID_BET_MARKER = 99999;
    uint256 public constant EMERGENCY_TIMEOUT = 7 days;

    struct WithdrawalProposal {
        address payable toAddress;
        uint256 atTime;
    }

    uint256 public invested = 0;
    uint256 public startedBankroll = 10 ether; //10 Ethers
    // uint256 public startedBankroll = 500000000000000000 wei;

    address public controller;
    address public owner;
    bool public paused;

    WithdrawalProposal public proposedWithdrawal;

    struct Investor {
        address investorAddress;
        uint256 amountInvested;
        bool votedForEmergencyWithdrawal;
    }

    struct Bet {
        address playerAddress;
        uint256 amountBetted;
        uint256 numberRolled;
        bool isWinned;
        bool isClaimed;
        // uint256 timelock;
    }

    //Starting at 1
    mapping(uint256 => Investor) public investors;
    mapping(address => uint256) public investorIDs;
    uint256 public numInvestors = 0;

    // mapping(bytes32 => Bet) bets;
    // bytes32[] betsKeys;
    mapping(uint256 => Bet) bets;
    mapping(address => uint256) public betsIDs;
    uint256[] betsKeys;

    uint256 public amountWagered = 0;
    uint256 public investorsProfit = 0;
    uint256 public investorsLoses = 0;
    bool profitDistributed;

    event BetWon(
        address playerAddress,
        uint256 numberRolled,
        uint256 amountWon
    );
    event BetLost(address playerAddress, uint256 numberRolled);
    event EmergencyWithdrawalProposed();
    event EmergencyWithdrawalFailed(address withdrawalAddress);
    event EmergencyWithdrawalSucceeded(
        address withdrawalAddress,
        uint256 amountWithdrawn
    );
    event FailedSend(address receiver, uint256 amount);
    event ValueIsTooBig();

    event DiceRolled(uint256 indexed requestId, address indexed roller);
    event DiceLanded(uint256 indexed requestId, uint256 indexed result);

    /**
        CONSTRUCTOR
    */
    // constructor(address _controller, address _owner) public {
    // constructor(address _owner) public {
    constructor(uint256 _startedBankroll) public {
        owner = msg.sender;
        startedBankroll = _startedBankroll;
    }

    //SECTION I: MODIFIERS AND HELPER FUNCTIONS

    //MODIFIERS

    modifier onlyIfNotStopped {
        if (paused) require(false, "Contract is stopped");
        _;
    }

    modifier onlyIfStopped {
        if (!paused) require(false, "Contract is not stopped");
        _;
    }

    modifier onlyInvestors {
        if (investorIDs[msg.sender] == 0) require(false, "Only for investors");
        _;
    }

    modifier onlyNotInvestors {
        if (investorIDs[msg.sender] != 0)
            require(false, "Only for not investors");
        _;
    }

    modifier onlyOwner {
        require(
            msg.sender == controller || msg.sender == owner,
            "Only for owner"
        );
        _;
    }

    modifier onlyMoreThanMinInvestment {
        if (msg.value <= getMinInvestment())
            require(false, "Only more than min investment");
        _;
    }

    modifier onlyMoreThanZero {
        if (msg.value == 0) require(false, "Only more than zero");
        _;
    }

    modifier onlyIfBetSizeIsStillCorrect(uint256 myid) {
        Bet memory thisBet = bets[myid];
        if (
            (((thisBet.amountBetted * ((10000 - edge) - pwin)) / pwin) <=
                (maxWin * getBankroll()) / 10000)
        ) {
            _;
        } else {
            bets[myid].numberRolled = INVALID_BET_MARKER;
            safeSend(payable(thisBet.playerAddress), thisBet.amountBetted);
            return;
        }
    }

    modifier onlyIfValidRoll(uint256 myid, uint256 result) {
        Bet memory thisBet = bets[myid];
        //uint256 numberRolled = parseInt(result);
        uint256 numberRolled = result;

        if (
            (numberRolled < 1 || numberRolled > 10000) &&
            thisBet.numberRolled == 0
        ) {
            bets[myid].numberRolled = INVALID_BET_MARKER;
            safeSend(payable(thisBet.playerAddress), thisBet.amountBetted);
            return;
        }
        _;
    }

    modifier onlyIfInvestorBalanceIsPositive(address currentInvestor) {
        if (getBalance(currentInvestor) >= 0) {
            _;
        }
    }

    modifier onlyWinningBets(uint256 numberRolled) {
        if (numberRolled - 1 < pwin) {
            _;
        }
    }

    modifier onlyLosingBets(uint256 numberRolled) {
        if (numberRolled - 1 >= pwin) {
            _;
        }
    }

    modifier onlyAfterProposed {
        require(
            proposedWithdrawal.toAddress ==
                address(proposedWithdrawal.toAddress),
            "Invalid address"
        );
        //if (proposedWithdrawal.toAddress == 0) require(false, 'Only after proposed');
        _;
    }

    modifier rejectValue {
        if (msg.value != 0) require(false, "reject value");
        _;
    }

    modifier onlyIfProfitNotDistributed {
        if (!profitDistributed) {
            _;
        }
    }

    modifier onlyIfValidGas(uint256 newGasLimit) {
        if (newGasLimit < 25000) require(false, "Gas is less than gas limit");
        _;
    }

    modifier onlyIfNotProcessed(uint256 myid) {
        Bet memory thisBet = bets[myid];
        if (thisBet.numberRolled > 0) require(false, "Already processed");
        _;
    }

    modifier onlyIfEmergencyTimeOutHasPassed {
        if (proposedWithdrawal.atTime + EMERGENCY_TIMEOUT > now)
            require(false, "Only if emergency timeout has passed");
        _;
    }

    //CONSTANT HELPER FUNCTIONS

    function getBankroll() public view returns (uint256) {
        return startedBankroll + invested + investorsProfit - investorsLoses;
    }

    function getMinInvestment() public view returns (uint256) {
        if (numInvestors == maxInvestors) {
            uint256 investorID = searchSmallestInvestor();
            return getBalance(investors[investorID].investorAddress);
        } else {
            return 0;
        }
    }

    function getStatus()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 bankroll = getBankroll();

        uint256 minInvestment = getMinInvestment();

        return (
            bankroll,
            pwin,
            edge,
            maxWin,
            minBet,
            amountWagered,
            (investorsProfit - investorsLoses),
            minInvestment,
            betsKeys.length
        );
    }

    function getBet(uint256 id)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        if (id < betsKeys.length) {
            uint256 betKey = betsKeys[id];
            return (
                bets[betKey].playerAddress,
                bets[betKey].amountBetted,
                bets[betKey].numberRolled,
                bets[betKey].isClaimed,
                bets[betKey].isWinned
            );
        }
    }

    //TODO only current investor
    function getLastBet()
        public
        view
        onlyInvestors
        returns (
            address,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        // uint256 id = investorIDs[currentInvestor];
        // uint256 betKey = betsKeys[id];

        uint256 betKey = betsIDs[msg.sender];

        return (
            bets[betKey].playerAddress,
            bets[betKey].amountBetted,
            bets[betKey].numberRolled,
            bets[betKey].isClaimed,
            bets[betKey].isWinned
        );
    }

    //TODO only if win current investor
    function claim() public onlyInvestors {
        //TODO create modifiers
        uint256 betKey = betsIDs[msg.sender];

        require(bets[betKey].isWinned, "Not winned.");
        require(!bets[betKey].isClaimed, "Already claimed.");

        bets[betKey].isClaimed = true;
        uint256 winAmount = (bets[betKey].amountBetted * (10000 - edge)) / pwin;
        emit BetWon(
            bets[betKey].playerAddress,
            bets[betKey].numberRolled,
            winAmount
        );

        // TODO do not sent but update data to allow user to claim
        safeSend(payable(bets[betKey].playerAddress), winAmount);

        //returning all value to user
        // safeSend(
        //     bets[betKey].playerAddress,
        //     bets[betKey].amountBetted + winAmount
        // );

        investorsLoses += (winAmount - bets[betKey].amountBetted);

        //TODO Clean User Bet Data
        // delete bets[betKey];
        // delete betsIDs[msg.sender];
    }

    function numBets() public view returns (uint256) {
        return betsKeys.length;
    }

    function getMinBetAmount() public view returns (uint256) {
        //TODO update this line by converting LINK fees to ETH fees
        uint256 oraclizeFee = 2 finney;

        //return oraclizeFee + minBet;
        return minBet;
    }

    function getMaxBetAmount() public view returns (uint256) {
        //TODO update this line by converting LINK fees to ETH fees
        uint256 oraclizeFee = 2 finney;

        uint256 betValue = ((maxWin * getBankroll()) * pwin) /
            (10000 * (10000 - edge - pwin));

        //return betValue + oraclizeFee;
        return betValue;
    }

    function getLosesShare(address currentInvestor)
        public
        view
        returns (uint256)
    {
        return
            (investors[investorIDs[currentInvestor]].amountInvested *
                (investorsLoses)) / invested;
    }

    function getProfitShare(address currentInvestor)
        public
        view
        returns (uint256)
    {
        return
            (investors[investorIDs[currentInvestor]].amountInvested *
                (investorsProfit)) / invested;
    }

    function getBalance(address currentInvestor)
        public
        view
        onlyInvestors
        returns (uint256)
    {
        return
            investors[investorIDs[currentInvestor]].amountInvested +
            getProfitShare(currentInvestor) -
            getLosesShare(currentInvestor);
    }

    function searchSmallestInvestor() public view returns (uint256) {
        uint256 investorID = 1;
        for (uint256 i = 1; i <= numInvestors; i++) {
            if (
                getBalance(investors[i].investorAddress) <
                getBalance(investors[investorID].investorAddress)
            ) {
                investorID = i;
            }
        }

        return investorID;
    }

    // PRIVATE HELPERS FUNCTION
    function safeSend(address payable _to, uint256 _value) public payable {
        if (address(this).balance < _value) {
            emit ValueIsTooBig();
            return;
        }

        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        // (bool sent, bytes memory data) = _to.call{value: _value}("");
        (bool sent, ) = _to.call{value: _value}("");

        if (!sent) {
            FailedSend(_to, _value);
            if (_to != owner) {
                //Forward to house address all change
                (bool success, ) = owner.call{value: _value}("");

                if (!success) {
                    FailedSend(owner, _value);
                    require(success, "Failed to send Ether to owner");
                } else {
                    require(sent, "Failed to send Ether to user");
                }
            }
        }
    }

    // function safeSend(address addr, uint256 value) private {
    //     if (address(this).balance < value) {
    //         emit ValueIsTooBig();
    //         return;
    //     }

    //     //TODO keep a litle to send transactions

    //     (bool success, ) = addr.call{value: value}("");
    //     // (bool success, ) = addr.call{value: value, gas: safeGas}("");
    //     require(success, "Transfer failed.");
    //     if (!success) {
    //         //if (!(addr.call{value: value, gas: safeGas}(""))) {
    //         FailedSend(addr, value);
    //         if (addr != owner) {
    //             //Forward to house address all change
    //             (bool success, ) = owner.call{value: value, gas: safeGas}("");
    //             if (!success) {
    //                 //if (!(owner.call{value: value, gas: safeGas}()))
    //                 FailedSend(owner, value);
    //                 //require(success, "Transfer to House failed.");
    //             }
    //         }
    //     }
    // }

    function addInvestorAtID(uint256 id) private {
        investorIDs[msg.sender] = id;
        investors[id].investorAddress = msg.sender;
        investors[id].amountInvested = msg.value;
        invested += msg.value;
    }

    function profitDistribution() private onlyIfProfitNotDistributed {
        uint256 copyInvested;

        for (uint256 i = 1; i <= numInvestors; i++) {
            address currentInvestor = investors[i].investorAddress;
            uint256 profitOfInvestor = getProfitShare(currentInvestor);
            uint256 losesOfInvestor = getLosesShare(currentInvestor);
            investors[i].amountInvested += profitOfInvestor - losesOfInvestor;
            copyInvested += investors[i].amountInvested;
        }

        delete investorsProfit;
        delete investorsLoses;
        invested = copyInvested;

        profitDistributed = true;
    }

    // SECTION II: BET & BET PROCESSING
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function bet()
        public
        payable
        onlyIfNotStopped
        onlyMoreThanZero
        onlyMoreThanMinInvestment
        onlyNotInvestors
    {
        // END NEWINVESTOR

        profitDistribution();

        if (numInvestors == maxInvestors) {
            uint256 smallestInvestorID = searchSmallestInvestor();
            divest(investors[smallestInvestorID].investorAddress);
        }

        numInvestors += 1;
        addInvestorAtID(numInvestors);
        // END NEWINVESTOR

        uint256 betValue = msg.value;

        // if (
        //     (((betValue * ((10000 - edge) - pwin)) / pwin) <=
        //         (maxWin * getBankroll()) / 10000)
        // ) {
        // uint256 numerator = ((betValue * ((10000 - edge) - pwin)) / pwin);
        // uint256 denominator = (maxWin * getBankroll()) / 10000;
        // if (numerator <= denominator) {
        if (
            (((betValue * ((10000 - edge) - pwin)) / pwin) <=
                (maxWin * getBankroll()) / 10000) && (betValue >= minBet)
        ) {
            amountWagered += betValue;

            // byte[] memory myid = randbytes(10);
            uint256 numberRolled = _rand();
            uint256 myid = _rand();

            // uint256 myid = _randBytes(numberRolled);

            // bets[numInvestors] = Bet({
            bets[myid] = Bet({
                playerAddress: msg.sender,
                amountBetted: betValue,
                numberRolled: 0,
                isClaimed: false,
                isWinned: false
            });
            // betsKeys.push(numInvestors);
            betsKeys.push(myid);
            betsIDs[msg.sender] = myid;

            emit DiceRolled(myid, msg.sender);

            // uint256 numberRolled = _rand();
            bets[myid].numberRolled = numberRolled;
            isWinningBet(bets[myid], numberRolled);
            isLosingBet(bets[myid], numberRolled);
            delete profitDistributed;
        } else {
            require(false, "You cannot enter in party");
        }
    }

    function numerator(uint256 amount) public view returns (uint256) {
        // return ((amount * ((10000 - edge) - pwin)) / pwin);
        return ((amount * ((10000 - edge) - pwin)) / pwin);
    }

    function denominator() public view returns (uint256) {
        // return (maxWin * getBankroll()) / 10000;
        return ((maxWin * getBankroll()) / 10000);
    }

    function isWinningBet(Bet storage thisBet, uint256 numberRolled)
        private
        onlyWinningBets(numberRolled)
    {
        // require(false, "isWinningBet");

        thisBet.isWinned = true;
        // uint256 winAmount = (thisBet.amountBetted * (10000 - edge)) / pwin;
        // BetWon(thisBet.playerAddress, numberRolled, winAmount);

        //TODO do not sent but update data to allow user to claim
        //safeSend(thisBet.playerAddress, winAmount);
        // investorsLoses += (winAmount - thisBet.amountBetted);
    }

    function isLosingBet(Bet storage thisBet, uint256 numberRolled)
        private
        onlyLosingBets(numberRolled)
    {
        // require(false, "isLosingBet");

        thisBet.isClaimed = true;
        emit BetLost(thisBet.playerAddress, numberRolled);
        //TODO do not sent but update data to allow user to claim
        //safeSend(thisBet.playerAddress, 1);
        investorsProfit +=
            ((thisBet.amountBetted - 1) * (10000 - houseEdge)) /
            10000;
        uint256 houseProfit = ((thisBet.amountBetted - 1) * (houseEdge)) /
            10000;

        //TODO remuburse initial Bankroll
        safeSend(payable(owner), houseProfit);
    }

    //SECTION III: INVEST & DIVEST

    function increaseInvestment()
        public
        payable
        onlyIfNotStopped
        onlyMoreThanZero
        onlyInvestors
    {
        profitDistribution();
        investors[investorIDs[msg.sender]].amountInvested += msg.value;
        invested += msg.value;
    }

    function divest() public payable onlyInvestors rejectValue {
        divest(msg.sender);
    }

    function divest(address currentInvestor)
        private
        onlyIfInvestorBalanceIsPositive(currentInvestor)
    {
        profitDistribution();
        uint256 currentID = investorIDs[currentInvestor];
        uint256 amountToReturn = getBalance(currentInvestor);
        invested -= investors[currentID].amountInvested;
        uint256 divestFeeAmount = (amountToReturn * divestFee) / 10000;
        amountToReturn -= divestFeeAmount;

        delete investors[currentID];
        delete investorIDs[currentInvestor];
        //Reorder investors
        if (currentID != numInvestors) {
            // Get last investor
            Investor memory lastInvestor = investors[numInvestors];
            //Set last investor ID to investorID of divesting account
            investorIDs[lastInvestor.investorAddress] = currentID;
            //Copy investor at the new position in the mapping
            investors[currentID] = lastInvestor;
            //Delete old position in the mappping
            delete investors[numInvestors];
        }

        numInvestors--;
        safeSend(payable(currentInvestor), amountToReturn);
        safeSend(payable(owner), divestFeeAmount);
    }

    function forceDivestOfAllInvestors() public payable onlyOwner rejectValue {
        uint256 copyNumInvestors = numInvestors;
        for (uint256 i = 1; i <= copyNumInvestors; i++) {
            divest(investors[1].investorAddress);
        }
    }

    /*
    The controller can use this function to force the exit of an investor from the
    contract during an emergency withdrawal in the following situations:
        - Unresponsive investor
        - Investor demanding to be paid in other to vote, the facto-blackmailing
        other investors
    */
    function forceDivestOfOneInvestor(address currentInvestor)
        public
        payable
        onlyOwner
        onlyIfStopped
        rejectValue
    {
        divest(currentInvestor);
        //Resets emergency withdrawal proposal. Investors must vote again
        delete proposedWithdrawal;
    }

    //SECTION IV: CONTRACT MANAGEMENT

    function pause() public payable onlyOwner rejectValue {
        paused = true;
    }

    function unpause() public payable onlyOwner rejectValue {
        paused = false;
    }

    function changeControllerAddress(address newController)
        public
        payable
        onlyOwner
        rejectValue
    {
        controller = newController;
    }

    function changeOwnerAddress(address newOwner)
        public
        payable
        onlyOwner
        rejectValue
    {
        owner = newOwner;
    }

    function changeGasLimitOfSafeSend(uint256 newGasLimit)
        public
        payable
        onlyOwner
        onlyIfValidGas(newGasLimit)
        rejectValue
    {
        safeGas = newGasLimit;
    }

    //SECTION V: EMERGENCY WITHDRAWAL

    function voteEmergencyWithdrawal(bool vote)
        public
        payable
        onlyInvestors
        onlyAfterProposed
        onlyIfStopped
        rejectValue
    {
        investors[investorIDs[msg.sender]].votedForEmergencyWithdrawal = vote;
    }

    function proposeEmergencyWithdrawal(address payable withdrawalAddress)
        public
        payable
        onlyIfStopped
        onlyOwner
        rejectValue
    {
        //Resets previous votes
        for (uint256 i = 1; i <= numInvestors; i++) {
            delete investors[i].votedForEmergencyWithdrawal;
        }

        proposedWithdrawal = WithdrawalProposal(withdrawalAddress, now);
        emit EmergencyWithdrawalProposed();
    }

    function executeEmergencyWithdrawal()
        public
        payable
        onlyOwner
        onlyAfterProposed
        onlyIfStopped
        onlyIfEmergencyTimeOutHasPassed
        rejectValue
    {
        uint256 numOfVotesInFavour;
        uint256 amountToWithdrawal = address(this).balance;

        for (uint256 i = 1; i <= numInvestors; i++) {
            if (investors[i].votedForEmergencyWithdrawal == true) {
                numOfVotesInFavour++;
                delete investors[i].votedForEmergencyWithdrawal;
            }
        }

        if (
            numOfVotesInFavour >=
            (emergencyWithdrawalRatio * numInvestors) / 100
        ) {
            if (!proposedWithdrawal.toAddress.send(address(this).balance)) {
                EmergencyWithdrawalFailed(proposedWithdrawal.toAddress);
            } else {
                EmergencyWithdrawalSucceeded(
                    proposedWithdrawal.toAddress,
                    amountToWithdrawal
                );
            }
        } else {
            require(false, "Error occured during emergency withdrawal");
        }
    }

    // /**
    //  * @dev Generate random uint <= 256^2
    //  * @param seed
    //  * @return uint
    //  */
    // function rand(uint256 seed) internal pure returns (uint256) {
    //     bytes32 data;
    //     if (seed % 2 == 0) {
    //         data = keccak256(abi.encodePacked(seed));
    //     } else {
    //         data = keccak256(keccak256(abi.encodePacked(seed)));
    //     }
    //     uint256 sum;
    //     for (uint256 i; i < 32; i++) {
    //         sum += uint256(data[i]);
    //     }
    //     return
    //         uint256(data[sum % data.length]) *
    //         uint256(data[(sum + 2) % data.length]);
    // }

    // /**
    //  * @dev Generate random uint <= 256^2 with seed = block.timestamp
    //  * @return uint
    //  */
    // function randint() internal view returns (uint256) {
    //     return rand(now);
    // }

    // /**
    //  * @dev Generate random uint in range [a, b]
    //  * @return uint
    //  */
    // function randrange(uint256 a, uint256 b) internal view returns (uint256) {
    //     return a + (randint() % b);
    // }

    // /**
    //  * @dev Generate array of random bytes
    //  * @param size seed
    //  * @return byte[size]
    //  */
    // function randbytes(uint256 size, uint256 seed)
    //     internal
    //     pure
    //     returns (byte[] memory)
    // {
    //     byte[] memory data = new byte[](size);
    //     uint256 x = seed;
    //     for (uint256 i; i < size; i++) {
    //         x = rand(x);
    //         data[i] = byte(x % 256);
    //     }
    //     return data;
    // }

    // /**
    //  * @dev Generate array of random bytes
    //  * @param size seed
    //  * @return byte[size]
    //  */
    // function randbytes(uint256 size) internal pure returns (byte[] memory) {
    //     return randbytes(size, now);
    // }

    // /**
    //  * @dev Generate array of random bytes
    //  * @param size seed
    //  * @return byte[size]
    //  * https://ethereum.stackexchange.com/questions/4170/how-to-convert-a-uint-to-bytes-in-solidity
    //  */
    // function randbytes() internal pure returns (bytes32 b) {
    //     //b = new bytes(32);
    //     uint256 c = randint();
    //     assembly {
    //         mstore(add(b, 32), c)
    //     }
    // }

    function _randBytes() internal view returns (bytes32 _ret) {
        uint256 num = _rand();
        assembly {
            _ret := mload(0x10)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), num)
        }
    }

    function _randBytes(uint256 _rand) internal pure returns (bytes32 _ret) {
        assembly {
            _ret := mload(0x10)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), _rand)
        }
    }

    function _rand() internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(now, block.difficulty, msg.sender))
            ) % 1000;
    }

    function _randModulus(uint256 mod) internal returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(now, block.difficulty, msg.sender))
            ) % mod;
        //nonce++;
        // return rand;
    }
}
