pragma solidity ^0.8.5;

//import {getRandomNumber} from "filename";
//import "./RandomNumberConsumer.sol";

contract Dice {
    //contract Dice {
    //uint256 public pwin = 5000; //probability of winning (10000 = 100%)
    //uint256 public edge = 200; //edge percentage (10000 = 100%)
    //uint256 public maxWin = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
    //uint256 public minBet = 10 finney; //https://www.cryps.info/en/Finney_to_ETH/1/ - https://eth-converter.com/
    //uint256 public maxInvestors = 5; //maximum number of investors
    //uint256 public houseEdge = 50; //edge percentage (10000 = 100%)
    //uint256 public divestFee = 50; //divest fee percentage (10000 = 100%)
    //uint256 public emergencyWithdrawalRatio = 90; //ratio percentage (100 = 100%)

    uint256 constant pwin = 9000; //probability of winning (10000 = 100%)
    uint256 constant edge = 190; //edge percentage (10000 = 100%)
    uint256 constant maxWin = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
    uint256 constant minBet = 10000000 gwei;
    uint256 constant maxInvestors = 10; //maximum number of investors
    uint256 constant houseEdge = 90; //edge percentage (10000 = 100%)
    uint256 constant divestFee = 50; //divest fee percentage (10000 = 100%)
    uint256 constant emergencyWithdrawalRatio = 10; //ratio percentage (100 = 100%)

    uint256 safeGas = 25000;
    uint256 constant ORACLIZE_GAS_LIMIT = 125000;
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

    address owner;
    address houseAddress;
    bool public isStopped;

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

    constructor() public {
        owner = msg.sender;
        houseAddress = msg.sender;
    }

    // function Dice(
    //   uint256 pwinInitial,
    //   uint256 edgeInitial,
    //   uint256 maxWinInitial,
    //   uint256 minBetInitial,
    //   uint256 maxInvestorsInitial,
    //   uint256 houseEdgeInitial,
    //   uint256 divestFeeInitial,
    //   uint256 emergencyWithdrawalRatioInitial
    // ) {
    //   // OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
    //   // oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);

    //   pwin = pwinInitial;
    //   edge = edgeInitial;
    //   maxWin = maxWinInitial;
    //   minBet = minBetInitial;
    //   maxInvestors = maxInvestorsInitial;
    //   houseEdge = houseEdgeInitial;
    //   divestFee = divestFeeInitial;
    //   emergencyWithdrawalRatio = emergencyWithdrawalRatioInitial;
    //   owner = msg.sender;
    //   houseAddress = msg.sender;
    // }

    //SECTION I: MODIFIERS AND HELPER FUNCTIONS

    //MODIFIERS

    modifier onlyIfNotStopped {
        if (isStopped) require(false, "Contract is stopped");
        _;
    }

    modifier onlyIfStopped {
        if (!isStopped) require(false, "Contract is not stopped");
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
        if (owner != msg.sender) require(false, "Only for owner");
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

    function toUint256(bytes memory _bytes)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes memory result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return "0x0";
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    modifier onlyIfValidRoll(bytes32 myid, string memory result) {
        Bet memory thisBet = bets[myid];
        //uint256 numberRolled = parseInt(result);
        uint256 numberRolled = toUint256(stringToBytes32(result));

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
        if (proposedWithdrawal.atTime + EMERGENCY_TIMEOUT > block.timestamp)
            require(false, "Only if emergency timeout has passed");
        _;
    }

    // https://ethereum.stackexchange.com/questions/10932/how-to-convert-string-to-int
    //function parseInt(string memory s) private view returns (uint) {
    //  bytes memory b = bytes(s);
    //uint result = 0;
    //for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
    //  if (b[i] >= 48 && b[i] <= 57) {
    //    result = result * 10 + (uint(b[i]) - 48); // bytes and int are not compatible with the operator -.
    //}
    //}
    //return result; // this was missing
    //}

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
        //TODO TO UPDATE
        uint256 oraclizeFee = 2000000 gwei;
        //OraclizeI(OAR.getAddress()).getPrice(
        //  "URL",
        //ORACLIZE_GAS_LIMIT + safeGas
        //);
        //return oraclizeFee + minBet;
        return minBet;
    }

    function getMaxBetAmount() public view returns (uint256) {
        //TODO TO UPDATE
        uint256 oraclizeFee = 2000000 gwei;
        //OraclizeI(OAR.getAddress()).getPrice(
        //  "URL",
        //ORACLIZE_GAS_LIMIT + safeGas
        //);
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

        (bool success, ) = addr.call{gas: safeGas, value: value}("");
        //require(success, "Transfer failed.");
        if (!success) {
            //if (!(addr.call.gas(safeGas).value(value)(""))) {
            emit FailedSend(addr, value);
            if (addr != houseAddress) {
                //Forward to house address all change
                (bool success, ) = houseAddress.call{
                    gas: safeGas,
                    value: value
                }("");
                if (!success) {
                    //if (!(houseAddress.call.gas(safeGas).value(value)()))
                    emit FailedSend(houseAddress, value);
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

    //function random() private view returns (uint) {
    //  return uint(keccak256(block.difficulty, now));
    //}

    //function random() private view returns (uint8) {
    //  return uint8(uint256(keccak256(block.timestamp, block.difficulty))%251);
    //}

    // SECTION II: BET & BET PROCESSING
    //function() {
    receive() external payable {
        bet();
    }

    function bet()
        public
        payable
        onlyIfNotStopped
        onlyMoreThanZero
        onlyMoreThanMinInvestment
    {
        //TODO TO UPDATE
        uint256 oraclizeFee = 2000000 gwei;
        //OraclizeI(OAR.getAddress()).getPrice(
        //  "URL",
        //ORACLIZE_GAS_LIMIT + safeGas
        //);
        //uint256 betValue = msg.value - oraclizeFee;
        uint256 betValue = msg.value;
        if (
            (((betValue * ((10000 - edge) - pwin)) / pwin) <=
                (maxWin * getBankroll()) / 10000)
        ) {
            //require(false, 'PROUT');

            bytes32 myid = "getrandom number";
            // bytes32 myid = investorIDs[msg.sender];

            //TODO : Call __callback method after generating random number

            // encrypted arg: '\n{"jsonrpc":2.0,"method":"generateSignedIntegers","params":{"apiKey":"YOUR_API_KEY","n":1,"min":1,"max":10000},"id":1}'
            // oraclize_query(
            //   "URL",
            // "json(https://api.random.org/json-rpc/1/invoke).result.random.data.0",
            //"BBX1PCQ9134839wTz10OWxXCaZaGk92yF6TES8xA+8IC7xNBlJq5AL0uW3rev7IoApA5DMFmCfKGikjnNbNglKKvwjENYPB8TBJN9tDgdcYNxdWnsYARKMqmjrJKYbBAiws+UU6HrJXUWirO+dBSSJbmjIg+9vmBjSq8KveiBzSGmuQhu7/hSg5rSsSP/r+MhR/Q5ECrOHi+CkP/qdSUTA/QhCCjdzFu+7t3Hs7NU34a+l7JdvDlvD8hoNxyKooMDYNbUA8/eFmPv2d538FN6KJQp+RKr4w4VtAMHdejrLM=",
            //ORACLIZE_GAS_LIMIT + safeGas
            //);

            bets[myid] = Bet(msg.sender, betValue, 0);
            betsKeys.push(myid);
        } else {
            require(false, "Transaction must more than one Ether");
        }
    }

    function __callback(
        bytes32 myid,
        string memory result,
        bytes memory proof
    )
        public
        // onlyOraclize
        onlyIfNotProcessed(myid)
        onlyIfValidRoll(myid, result)
        onlyIfBetSizeIsStillCorrect(myid)
    {
        Bet memory thisBet = bets[myid];
        //uint256 numberRolled = parseInt(result);
        uint256 numberRolled = toUint256(stringToBytes32(result));
        bets[myid].numberRolled = numberRolled;
        isWinningBet(thisBet, numberRolled);
        isLosingBet(thisBet, numberRolled);
        amountWagered += thisBet.amountBetted;
        delete profitDistributed;
    }

    function isWinningBet(Bet memory thisBet, uint256 numberRolled)
        private
        onlyWinningBets(numberRolled)
    {
        uint256 winAmount = (thisBet.amountBetted * (10000 - edge)) / pwin;
        emit BetWon(thisBet.playerAddress, numberRolled, winAmount);
        safeSend(thisBet.playerAddress, winAmount);
        investorsLoses += (winAmount - thisBet.amountBetted);
    }

    function isLosingBet(Bet memory thisBet, uint256 numberRolled)
        private
        onlyLosingBets(numberRolled)
    {
        emit BetLost(thisBet.playerAddress, numberRolled);
        safeSend(thisBet.playerAddress, 1);
        investorsProfit +=
            ((thisBet.amountBetted - 1) * (10000 - houseEdge)) /
            10000;
        uint256 houseProfit = ((thisBet.amountBetted - 1) * (houseEdge)) /
            10000;
        safeSend(houseAddress, houseProfit);
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

    // function newInvestor()
    //payable
    //   onlyIfNotStopped
    //onlyMoreThanZero
    // onlyNotInvestors
    // onlyMoreThanMinInvestment
    //{
    // profitDistribution();

    //if (numInvestors == maxInvestors) {
    //  uint256 smallestInvestorID = searchSmallestInvestor();
    //    divest(investors[smallestInvestorID].investorAddress);
    //}

    //  numInvestors++;
    //addInvestorAtID(numInvestors);
    //}

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
        safeSend(houseAddress, divestFeeAmount);
    }

    function forceDivestOfAllInvestors() public payable onlyOwner rejectValue {
        uint256 copyNumInvestors = numInvestors;
        for (uint256 i = 1; i <= copyNumInvestors; i++) {
            divest(investors[1].investorAddress);
        }
    }

    /*
    The owner can use this function to force the exit of an investor from the
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

    function stopContract() public payable onlyOwner rejectValue {
        isStopped = true;
    }

    function resumeContract() public payable onlyOwner rejectValue {
        isStopped = false;
    }

    function changeHouseAddress(address newHouse)
        public
        payable
        onlyOwner
        rejectValue
    {
        houseAddress = newHouse;
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

        proposedWithdrawal = WithdrawalProposal(
            withdrawalAddress,
            block.timestamp
        );
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
                emit EmergencyWithdrawalFailed(proposedWithdrawal.toAddress);
            } else {
                emit EmergencyWithdrawalSucceeded(
                    proposedWithdrawal.toAddress,
                    amountToWithdrawal
                );
            }
        } else {
            require(false, "Error occured during emergency withdrawal");
        }
    }
}
