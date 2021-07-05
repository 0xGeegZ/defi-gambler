pragma solidity ^0.6.12;

// import "./VaultV0.sol";
import "./Random.sol";

contract Game {
    //TODO add verification with this constant
    uint256 private constant ROLL_IN_PROGRESS = 42;

    // VaultV0 vault;
    // address vaulAdress;

    uint256 constant pwin = 9000; //probability of winning (10000 = 100%)
    uint256 constant edge = 190; //edge percentage (10000 = 100%)
    uint256 constant maxWin = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
    uint256 constant minBet = 100000000000000000 wei; // 0,1 BNB - https://eth-converter.com/
    uint256 constant maxInvestors = 10; //maximum number of investors
    uint256 constant houseEdge = 90; //edge percentage (10000 = 100%)
    uint256 constant divestFee = 50; //divest fee percentage (10000 = 100%)
    uint256 constant emergencyWithdrawalRatio = 10; //ratio percentage (100 = 100%)

    uint256 safeGas = 25000;
    uint256 constant INVALID_BET_MARKER = 99999;
    uint256 constant EMERGENCY_TIMEOUT = 7 days;

    struct Investor {
        address investorAddress;
        uint256 amountInvested;
        bool votedForEmergencyWithdrawal;
    }

    struct Bet {
        address playerAddress;
        uint256 amountBetted;
        uint256 numberRolled;
    }

    struct WithdrawalProposal {
        address payable toAddress;
        uint256 atTime;
    }

    //Starting at 1
    mapping(address => uint256) public investorIDs;
    mapping(uint256 => Investor) public investors;
    uint256 public numInvestors = 0;

    uint256 public invested = 0;

    address controller;
    address owner;
    bool public paused;

    WithdrawalProposal public proposedWithdrawal;

    mapping(bytes32 => Bet) bets;
    bytes32[] betsKeys;

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

    event DiceRolled(bytes32 indexed requestId, address indexed roller);
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);

    /**
        CONSTRUCTOR
    */
    // constructor(address _controller, address _owner) public {
    constructor(address _owner) public {
        // controller = _controller;
        owner = _owner;

        // vaulAdress = new VaultV0(controller, owner);
        // vault = new VaultV0(controller, owner);
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

    modifier onlyIfBetSizeIsStillCorrect(bytes32 myid) {
        Bet memory thisBet = bets[myid];
        if (
            (((thisBet.amountBetted * ((10000 - edge) - pwin)) / pwin) <=
                (maxWin * getBankroll()) / 10000)
        ) {
            _;
        } else {
            bets[myid].numberRolled = INVALID_BET_MARKER;
            safeSend(thisBet.playerAddress, thisBet.amountBetted);
            return;
        }
    }

    modifier onlyIfValidRoll(bytes32 myid, uint256 result) {
        Bet memory thisBet = bets[myid];
        //uint256 numberRolled = parseInt(result);
        uint256 numberRolled = result;

        if (
            (numberRolled < 1 || numberRolled > 10000) &&
            thisBet.numberRolled == 0
        ) {
            bets[myid].numberRolled = INVALID_BET_MARKER;
            safeSend(thisBet.playerAddress, thisBet.amountBetted);
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

    modifier onlyIfNotProcessed(bytes32 myid) {
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
        return invested + investorsProfit - investorsLoses;
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
            uint256
        )
    {
        if (id < betsKeys.length) {
            bytes32 betKey = betsKeys[id];
            return (
                bets[betKey].playerAddress,
                bets[betKey].amountBetted,
                bets[betKey].numberRolled
            );
        }
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

    function getBalance(address currentInvestor) public view returns (uint256) {
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

    function safeSend(address addr, uint256 value) private {
        if (address(this).balance < value) {
            emit ValueIsTooBig();
            return;
        }

        //TODO keep a litle to send transactions

        (bool success, ) = addr.call.gas(safeGas).value(value)("");
        //require(success, "Transfer failed.");
        if (!success) {
            //if (!(addr.call.gas(safeGas).value(value)(""))) {
            FailedSend(addr, value);
            if (addr != owner) {
                //Forward to house address all change
                (bool success, ) = owner.call.gas(safeGas).value(value)("");
                if (!success) {
                    //if (!(owner.call.gas(safeGas).value(value)()))
                    FailedSend(owner, value);
                    //require(success, "Transfer to House failed.");
                }
            }
        }
    }

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
    //function() {
    receive() external payable {
        // bet(0);
        bet();
    }

    function bet()
        public
        payable
        onlyIfNotStopped
        onlyMoreThanZero
        onlyMoreThanMinInvestment
    {
        uint256 betValue = msg.value;

        if (
            (((betValue * ((10000 - edge) - pwin)) / pwin) <=
                (maxWin * getBankroll()) / 10000)
        ) {
            bytes32 myid = randbytes(10, msg.sender);

            bets[myid] = Bet(msg.sender, betValue, 0);
            betsKeys.push(myid);

            emit DiceRolled(myid, msg.sender);

            uint256 numberRolled = randrange(1, 10000);
            bets[myid].numberRolled = numberRolled;
            isWinningBet(bets[myid], numberRolled);
            isLosingBet(bets[myid], numberRolled);
            delete profitDistributed;
        } else {
            require(false, "Transaction must more than one Ether");
        }
    }

    function isWinningBet(Bet memory thisBet, uint256 numberRolled)
        private
        onlyWinningBets(numberRolled)
    {
        uint256 winAmount = (thisBet.amountBetted * (10000 - edge)) / pwin;
        BetWon(thisBet.playerAddress, numberRolled, winAmount);
        safeSend(thisBet.playerAddress, winAmount);
        investorsLoses += (winAmount - thisBet.amountBetted);
    }

    function isLosingBet(Bet memory thisBet, uint256 numberRolled)
        private
        onlyLosingBets(numberRolled)
    {
        BetLost(thisBet.playerAddress, numberRolled);
        safeSend(thisBet.playerAddress, 1);
        investorsProfit +=
            ((thisBet.amountBetted - 1) * (10000 - houseEdge)) /
            10000;
        uint256 houseProfit = ((thisBet.amountBetted - 1) * (houseEdge)) /
            10000;
        safeSend(owner, houseProfit);
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

    function newInvestor()
        public
        payable
        onlyIfNotStopped
        onlyMoreThanZero
        onlyNotInvestors
        onlyMoreThanMinInvestment
    {
        profitDistribution();

        if (numInvestors == maxInvestors) {
            uint256 smallestInvestorID = searchSmallestInvestor();
            divest(investors[smallestInvestorID].investorAddress);
        }

        numInvestors++;
        addInvestorAtID(numInvestors);
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
        safeSend(currentInvestor, amountToReturn);
        safeSend(owner, divestFeeAmount);
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
}
