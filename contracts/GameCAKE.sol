pragma solidity ^0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./interfaces/ICakeChef.sol";

contract GameCAKE {
    // import "@openzeppelin/contracts/math/SafeMath.sol";
    // import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
    // import "@openzeppelin/contracts/token/ERC20/IBEP20.sol";

    // using SafeERC20 for IBEP20;
    using SafeBEP20 for IBEP20;

    using Address for address;
    using SafeMath for uint256;
    using Math for uint256;
    // The CAKE TOKEN!
    IBEP20 public cake;
    address public cakeChef;

    //TODO add verification with this constant
    uint256 private constant ROLL_IN_PROGRESS = 42;

    // uint256 public pwin = 90; //probability of winning (100 = 100%)
    // uint256 public edge = 1.9; //edge percentage (100 = 100%)
    // uint256 public maxWin = 1; //max win (before edge is taken) as percentage of bankroll (100 = 100%)
    // uint256 public minBet = 1; // 0,1 BNB - https://eth-converter.com/
    // // uint256 constant minBet = 1 ether; // 1 BNB - https://eth-converter.com/
    // uint256 public maxInvestors = 10; //maximum number of investors
    // uint256 public houseEdge = 0.9; //edge percentage (100 = 100%)
    // uint256 public divestFee = 0.5; //divest fee percentage (100 = 100%)
    // uint256 public emergencyWithdrawalRatio = 0.1; //ratio percentage (100 = 100%)

    uint256 public pwin = 9000; //probability of winning (10000 = 100%)
    uint256 public edge = 190; //edge percentage (10000 = 100%)
    uint256 public maxWin = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
    uint256 public minBet = 1; // 0,1 BNB - https://eth-converter.com/
    // uint256 constant minBet = 1 ether; // 1 BNB - https://eth-converter.com/
    uint256 public maxInvestors = 10; //maximum number of investors
    uint256 public houseEdge = 90; //edge percentage (10000 = 100%)
    uint256 public divestFee = 50; //divest fee percentage (10000 = 100%)
    uint256 public emergencyWithdrawalRatio = 10; //ratio percentage (100 = 100%)
    uint256 public startedBankroll = 10 ether; //10

    uint256 private safeGas = 25000;
    uint256 private constant INVALID_BET_MARKER = 99999;
    uint256 public constant EMERGENCY_TIMEOUT = 7 days;

    struct WithdrawalProposal {
        address payable toAddress;
        uint256 atTime;
    }

    uint256 public invested = 0;
    // uint256 public startedBankroll = 10 ether; //10 Ethers
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
        uint256 winAmount;
        bool isWinned;
        bool isClaimed;
        // uint256 timelock;
    }

    //Starting at 1
    mapping(uint256 => Investor) public investors;
    mapping(address => uint256) public investorIDs;
    uint256 public numInvestors = 0;

    mapping(uint256 => Bet) bets;
    mapping(address => uint256) public betsIDs;

    uint256 public amountWagered = 0;
    uint256 public investorsProfit = 0;
    uint256 public investorsLoses = 0;
    bool profitDistributed;

    ///EVENTS
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
     * @dev Constructor
     * @notice TODO
     */
    constructor(address _cake, address _cakeChef) public {
        owner = msg.sender;
        cake = IBEP20(_cake);
        cakeChef = _cakeChef;
    }

    function numerator(uint256 amount) public view returns (uint256) {
        // return ((amount * ((10000 - edge) - pwin)) / pwin);
        return ((amount * ((10000 - edge) - pwin)) / pwin);
        // uint256 sales = 100;
        // uint256 commissionNumerator = 75;
        // uint256 commissionDenominator = 10000;
        // uint256 afterCommission = (sales * commissionNumerator) /
        //     commissionDenominator; // 7.5%
        // return afterCommission;
        // return (amount.mul((10000 - edge) - pwin).div(pwin)) * 10**2;
    }

    function denominator() public view returns (uint256) {
        // return (maxWin * getBankroll()) / 10000;
        return ((maxWin * getBankroll()) / 10000);
        // return (maxWin.mul(getBankroll()).div(10000)) * 10**2;
    }

    ///
    /// Main Functions
    ///

    function bet(uint256 _amount) public {
        require(!paused, "Contract is stopped"); // onlyIfNotStopped
        require(_amount > 0, "Only more than zero"); // onlyMoreThanZero
        require(_amount >= getMinInvestment(), "Only more than min investment"); // onlyMoreThanMinInvestment
        require(_amount >= minBet, "Only more than min bet"); // onlyMoreThanMinBet
        require(investorIDs[msg.sender] == 0, "Only for not investors"); // onlyNotInvestors

        uint256 allowance = cake.allowance(msg.sender, address(this));
        // uint256 allowance = cake.increaseAllowance(msg.sender, address(this));

        require(allowance >= _amount, "Check the token allowance");
        uint256 balance = cake.balanceOf(address(msg.sender));
        require(balance >= _amount, "not enought"); // onlyMoreThanZero
        // TODO
        // profitDistribution();

        // if (numInvestors == maxInvestors) {
        //     uint256 smallestInvestorID = searchSmallestInvestor();
        //     divest(investors[smallestInvestorID].investorAddress);
        // }

        numInvestors += 1;

        investorIDs[msg.sender] = numInvestors;

        investors[numInvestors].investorAddress = msg.sender;
        investors[numInvestors].amountInvested = _amount;
        invested += _amount;

        if (
            (((_amount * ((10000 - edge) - pwin)) / pwin) <=
                (maxWin * getBankroll()) / 10000)
        ) {
            //deposit

            bool success = cake.transferFrom(
                msg.sender,
                address(this),
                _amount
            );
            require(success, "Error during transfert"); // onlyMoreThanMinBet

            _stakeCake();

            uint256 _want = cake.balanceOf(address(this));

            if (_want > 0) {
                // _payFees(_want);
                _stakeCake();
            }

            //pick random number
            uint256 numberRolled = _rand();
            uint256 myid = _rand();
            // uint256 myid = _randBytes(numberRolled);

            // bets[numInvestors] = Bet({
            bets[myid] = Bet({
                playerAddress: msg.sender,
                amountBetted: _amount,
                numberRolled: 0,
                winAmount: 0,
                isClaimed: false,
                isWinned: false
            });

            betsIDs[msg.sender] = myid;
            bets[myid].numberRolled = numberRolled;

            emit DiceRolled(numberRolled, msg.sender);

            //pick winner
            if (numberRolled - 1 < pwin) {
                //winning
                bets[myid].isWinned = true;

                uint256 winAmount = (bets[myid].amountBetted * (10000 - edge)) /
                    pwin;

                // bets[myid].winAmount = bets[myid].amountBetted - winAmount;
                bets[myid].winAmount = winAmount - bets[myid].amountBetted;

                emit BetWon(
                    bets[myid].playerAddress,
                    bets[myid].numberRolled,
                    bets[myid].winAmount
                );
            } else {
                //Loosing
                bets[myid].isClaimed = true;
                emit BetLost(bets[myid].playerAddress, bets[myid].numberRolled);
                //TODO do not sent but update data to allow user to claim
                //safeSend(thisBet.playerAddress, 1);
                investorsProfit +=
                    ((bets[myid].amountBetted - 1) * (10000 - houseEdge)) /
                    10000;
                // uint256 houseProfit = ((bets[myid].amountBetted - 1) *
                //     (houseEdge)) / 10000;
                //TODO remuburse initial Bankroll
                //safeSend(payable(owner), houseProfit);
            }

            // TODO
            // delete profitDistributed;
        } else {
            require(false, "You cannot enter in party");
        }
    }

    function getLastBet()
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        require(investorIDs[msg.sender] != 0, "Only for investors"); // onlyInvestors

        uint256 betKey = betsIDs[msg.sender];

        return (
            bets[betKey].playerAddress,
            bets[betKey].amountBetted,
            bets[betKey].numberRolled,
            bets[betKey].winAmount,
            bets[betKey].isClaimed,
            bets[betKey].isWinned
        );
    }

    function _stakeCake() internal {
        if (paused) return;
        uint256 _want = cake.balanceOf(address(this));
        cake.safeApprove(cakeChef, 0);
        cake.safeApprove(cakeChef, _want);
        CakeChef(cakeChef).enterStaking(_want);
    }

    function claim() public {
        require(investorIDs[msg.sender] != 0, "Only for investors"); // onlyInvestors

        uint256 betKey = betsIDs[msg.sender];

        require(bets[betKey].isWinned, "Not winned.");
        require(!bets[betKey].isClaimed, "Already claimed.");

        // unstacking
        CakeChef(cakeChef).leaveStaking(bets[betKey].winAmount);
        // send
        cake.safeTransfer(msg.sender, bets[betKey].winAmount);

        // safeSend(payable(bets[betKey].playerAddress), bets[betKey].winAmount);

        investorsLoses += (bets[betKey].winAmount - bets[betKey].amountBetted);

        //TODO Clean User Bet Data
        // delete bets[betKey];
        // delete betsIDs[msg.sender];
    }

    ///
    /// HELPERS FUNCTIONS
    ///

    function balanceOfStakedWant() public view returns (uint256) {
        (uint256 _amount, ) = CakeChef(cakeChef).userInfo(
            uint256(0),
            address(this)
        );
        return _amount;
    }

    function balanceOfPendingWant() public view returns (uint256) {
        return CakeChef(cakeChef).pendingCake(uint256(0), address(this));
    }

    function getTotalBalance() public view returns (uint256) {
        return
            getContractBalance()
                .add(balanceOfStakedWant()) //will not be correct if we sold syrup
                .add(balanceOfPendingWant());
    }

    function getContractBalance() public view returns (uint256) {
        return cake.balanceOf(address(this));
    }

    function getBalanceFor(address currentInvestor)
        public
        view
        returns (uint256)
    {
        require(investorIDs[msg.sender] != 0, "Only for investors"); // onlyInvestors

        return
            investors[investorIDs[currentInvestor]].amountInvested +
            getProfitShare(currentInvestor) -
            getLosesShare(currentInvestor);
    }

    function getMinInvestment() public view returns (uint256) {
        if (numInvestors == maxInvestors) {
            uint256 investorID = searchSmallestInvestor();
            return getBalanceFor(investors[investorID].investorAddress);
        } else {
            return 0;
        }
    }

    function searchSmallestInvestor() public view returns (uint256) {
        uint256 investorID = 1;
        for (uint256 i = 1; i <= numInvestors; i++) {
            if (
                getBalanceFor(investors[i].investorAddress) <
                getBalanceFor(investors[investorID].investorAddress)
            ) {
                investorID = i;
            }
        }

        return investorID;
    }

    function getBankroll() public view returns (uint256) {
        return startedBankroll + invested + investorsProfit - investorsLoses;
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

    ///
    /// RANDOM FUNCTIONS
    ///

    /**
     * @dev Generate array of random bytes
     * @return _ret bytes32 a random string
     * @notice Actually cause a out of Gas exception
     */
    function _randBytes() internal view returns (bytes32 _ret) {
        uint256 num = _rand();
        assembly {
            _ret := mload(0x10)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), num)
        }
    }

    /**
     * @dev Generate array of random bytes
     * @param _rand number to transform to bytes
     * @return _ret bytes32 the transformed string
     * @notice Actually cause a out of Gas exception
     */
    function _randBytes(uint256 _rand) internal pure returns (bytes32 _ret) {
        assembly {
            _ret := mload(0x10)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), _rand)
        }
    }

    /**
     * @dev Generate array of random bytes
     * @notice This function will generate a random numbre beetween 0 and 10000
     * @return uint256
     */
    function _rand() internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(now, block.difficulty, msg.sender))
            ) % 10000;
    }
}
