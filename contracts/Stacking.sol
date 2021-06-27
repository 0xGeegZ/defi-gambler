pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface CakeChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function poolLength() external view returns (uint256);

    function withdraw(uint256 _pid, uint256 _amount) external;

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);
}

contract Stacking {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Math for uint256;

    address public admin;
    address private houseAddress;
    bool public isStopped;
    // uint256 public investorsCount;
    uint256 public totalInvested;
    uint256 public bankValue;

    IERC20 public cake = IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    CakeChef public cakeChef =
        CakeChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);

    // Info of each user.
    //TODO manage array of Stacks and array of Bet
    struct Investor {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 minTimeToWithdraw; // 604800 = 1 week
        uint8 flag;
        uint256 startBlockNumber;
        uint256 stopBlockNumber;
        uint256 rewards;
        bool isWin;
        //TODO add multiplier
    }

    // mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => Investor) public investors;

    constructor() public {
        admin = msg.sender;
        houseAddress = msg.sender;
        isStopped = false;
        totalInvested = 0;
        bankValue = 0;
    }

    // ----------------------------------------------------------------------------
    // MODIFIERS
    // ----------------------------------------------------------------------------

    modifier onlyIfNotStopped {
        if (isStopped) require(false, "Contract is stopped");
        _;
    }

    modifier onlyIfStopped {
        if (!isStopped) require(false, "Contract is not stopped");
        _;
    }

    modifier onlyInvestors {
        // if (investors[msg.sender] == msg.sender)
        if (investors[msg.sender].flag != 1)
            require(false, "Only for investors");
        _;
    }

    modifier onlyNotInvestors {
        if (investors[msg.sender].flag == 1)
            require(false, "Only for not investors");
        _;
    }

    modifier onlyAdmin {
        if (admin != msg.sender) require(false, "Only for admin");
        _;
    }

    modifier onlyTimelockDone {
        require(
            (investors[msg.sender].minTimeToWithdraw) < block.timestamp,
            "too early!"
        );
        _;
    }

    modifier onlyTotalAmount {
        require((investors[msg.sender].amount) > msg.value, "too big amount!");
        require(
            (investors[msg.sender].amount) < msg.value,
            "too small amount!"
        );
        _;
    }

    // ----------------------------------------------------------------------------
    // CONTRACT MANAGEMENT
    // ----------------------------------------------------------------------------

    function stopContract() public onlyAdmin {
        isStopped = true;
    }

    function resumeContract() public onlyAdmin {
        isStopped = false;
    }

    function changeHouseAddress(address newHouse) public onlyAdmin {
        houseAddress = newHouse;
    }

    function changeAdminAddress(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }

    function pending() external view onlyAdmin returns (uint256) {
        return cakeChef.pendingCake(0, address(this));
    }

    function harvest() external onlyAdmin {
        cakeChef.leaveStaking(0);
        _harvest();
    }

    function unstakeBank() external onlyAdmin {
        cakeChef.leaveStaking(bankValue);
    }

    function unstakeAll() external onlyAdmin {
        uint256 total = totalInvested + bankValue;
        cakeChef.leaveStaking(total);
    }

    // ----------------------------------------------------------------------------
    // EXTERNALS FUNCTIONS
    // ----------------------------------------------------------------------------
    function stake() external payable onlyNotInvestors {
        _stake(msg.value);
    }

    function unstake()
        external
        payable
        onlyInvestors
        onlyTimelockDone
        onlyTotalAmount
    {
        _unstake(msg.value);
    }

    function balance() external view onlyInvestors returns (uint256) {
        return investors[msg.sender].amount;
    }

    //TODO add spend function for benefices for admin
    // function spend(uint256 amount, address recipient) external onlyAdmin{
    //     require(msg.sender == admin, "only admin");
    //     uint256 balanceShares = cakeChef.balanceOf(address(this));
    //     cakeChef.leaveStaking(balanceShares);
    //     cake.transfer(recipient, amount);
    //     uint256 balanceDai = cake.balanceOf(address(this));
    //     if (balanceDai > 0) {
    //         _save(balanceDai);
    //     }
    // }

    // ----------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    // ----------------------------------------------------------------------------
    function _addInvestor(uint256 amount)
        internal
        view
        returns (Investor memory)
    {
        // inverstorsCount++;
        //TODO update rewards with betted value
        return Investor(amount, 604800, 1, block.number, 0, 0, false); //604800 = 1 week
    }

    function _stake(uint256 amount) internal {
        cake.transferFrom(msg.sender, address(this), amount);
        cake.approve(address(cakeChef), amount);
        cakeChef.enterStaking(amount);

        investors[msg.sender] = _addInvestor(amount);

        totalInvested += amount;
        //TODO emit event
    }

    function _unstake(uint256 amount) internal {
        investors[msg.sender].stopBlockNumber = block.number;

        //auto harverst
        cakeChef.leaveStaking(amount);

        //updating bank value with rewards
        uint256 rewards = cakeChef.getMultiplier(
            investors[msg.sender].startBlockNumber,
            investors[msg.sender].stopBlockNumber
        );

        //TODO check if bank rewards are negative and pause it if it's true;
        if (investors[msg.sender].rewards > rewards) {
            stopContract();
            require(false, "Contract is stopped");
        }

        uint256 bankRewards = investors[msg.sender].isWin
            ? rewards - investors[msg.sender].rewards
            : rewards;

        bankValue += bankRewards;

        //remove amount from investors for investor

        // TODO allow to remove less than investor amount ??
        // uint256 newAmount = investors[msg.sender].amount;
        // investors[msg.sender].amount = newAmount.sub(amount);

        //TODO keep investor in investrors ??
        // investors[msg.sender].amount = 0;
        // investors[msg.sender].flag = 0;

        delete investors[msg.sender];
        totalInvested += amount;

        //transfert amount to user
        cake.transfer(msg.sender, amount);

        _harvest();

        //TODO emit event
    }

    function _harvest() internal {
        //if cakes in contract balance (fees & stacking rewards), stack it
        uint256 balanceCake = cake.balanceOf(address(this));
        if (balanceCake > 0) {
            bankValue += balanceCake;
            cakeChef.enterStaking(balanceCake);
        }
    }

    // *********  START StrategyACryptoSCakeV2b  *********
    // function _stakeCake() internal {
    //     uint256 _want = IERC20(cake).balanceOf(address(this));
    //     IERC20(cake).safeApprove(cakeChef, 0);
    //     IERC20(cake).safeApprove(cakeChef, _want);
    //     CakeChef(cakeChef).enterStaking(_want);
    // }
    // function _payFees(uint256 _want) internal {
    //     uint256 _fee = _want.mul(performanceFee).div(FEE_DENOMINATOR);
    //     uint256 _reward = _want.mul(strategistReward).div(FEE_DENOMINATOR);
    //     IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
    //     IERC20(want).safeTransfer(strategist, _reward);
    // }
    // *********  END StrategyACryptoSCakeV2b  *********

    // ----------------------------------------------------------------------------
    // DEFAULT FUNCTIONS
    // ----------------------------------------------------------------------------

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    // fallback() external payable — when no other function matches (not even the receive function). Optionally payable.
    fallback() external payable {
        _stake(msg.value);
    }

    /**
     * @dev receive function ***DO NOT OVERRIDE***
     */
    // receive() external payable — for empty calldata (and any value)
    receive() external payable {
        _stake(msg.value);
    }
}
