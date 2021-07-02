pragma solidity ^0.6.6;

//Use this for visual sutdio code IDE
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

//TODO add https://docs.openzeppelin.com/contracts/2.x/api/lifecycle#pausable

//Use this for remix IDE
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/token/ERC20/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/math/SafeMath.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/math/Math.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/math/Math.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/ICakeChef.sol";

//https://bscscan.com/address/0x4bBfc7eFCd146E3dd1916Da99Fd72D4e5b3A55F1#code
contract StackingV2 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Math for uint256;

    // TODO add it as constructor parameter to implement tests
    address public constant want =
        address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    //   address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    // testnet 0xF9f93cF501BFaDB6494589Cb4b4C15dE49E85D0e

    //TODO Use WBNB to store benefices
    // TODO add it as constructor parameter to implement tests
    address public constant wbnb =
        address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    // address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    // testnet 0x094616F0BdFB0b526bD735Bf66Eca0Ad254ca81F

    // TODO add it as constructor parameter to implement tests
    address public constant cakeChef =
        address(0x73feaa1eE314F8c655E354234017bE2193C9E24E);

    address public governance;
    address public controller;
    address public strategist;

    uint256 public performanceFee = 450;
    uint256 public strategistReward = 50;
    uint256 public withdrawalFee = 50;
    uint256 public harvesterReward = 30;
    uint256 public constant FEE_DENOMINATOR = 10000;

    bool public paused;

    // constructor() public {
    constructor(address _controller) public {
        governance = msg.sender;

        strategist = msg.sender;

        controller = _controller;
        // controller = msg.sender;
    }

    function getName() external pure returns (string memory) {
        return "Vault";
    }

    function deposit() public {
        uint256 _want = IERC20(want).balanceOf(address(this));

        if (_want > 0) {
            _stakeCake();

            _want = IERC20(want).balanceOf(address(this));

            if (_want > 0) {
                _payFees(_want);
                _stakeCake();
            }
        }
    }

    function _stakeCake() internal {
        if (paused) return;
        uint256 _want = IERC20(want).balanceOf(address(this));
        IERC20(want).safeApprove(cakeChef, 0);
        IERC20(want).safeApprove(cakeChef, _want);
        CakeChef(cakeChef).enterStaking(_want);
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        require(controller != address(0), "!controller"); // additional protection so we don't burn the funds

        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _fee = _amount.mul(withdrawalFee).div(FEE_DENOMINATOR);

        IERC20(want).safeTransfer(controller, _fee);
        require(controller != address(0), "!controller"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(controller, _amount.sub(_fee));

        // Old code
        // IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
        // address _vault = IController(controller).vaults(address(want));
        // require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        // IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        uint256 _want = IERC20(want).balanceOf(address(this));
        CakeChef(cakeChef).leaveStaking(_amount);
        _want = IERC20(want).balanceOf(address(this)).sub(_want).sub(_amount);
        if (_want > 0) {
            _payFees(_want);
        }

        return _amount;
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(
            msg.sender == controller ||
                msg.sender == strategist ||
                msg.sender == governance,
            "!authorized"
        );
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        require(controller != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(controller, balance);

        // Old code
        // address _vault = IController(controller).vaults(address(want));
        // require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        // IERC20(want).safeTransfer(_vault, balance);
    }

    function _withdrawAll() internal {
        CakeChef(cakeChef).emergencyWithdraw(0);
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

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

    function harvest() public returns (uint256 harvesterRewarded) {
        // require(msg.sender == strategist || msg.sender == governance, "!authorized");
        require(msg.sender == tx.origin, "not eoa");

        _stakeCake();

        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            _payFees(_want);
            uint256 _harvesterReward = _want.mul(harvesterReward).div(
                FEE_DENOMINATOR
            );
            IERC20(want).safeTransfer(msg.sender, _harvesterReward);
            _stakeCake();
            return _harvesterReward;
        }
    }

    function _payFees(uint256 _want) internal {
        uint256 _fee = _want.mul(performanceFee).div(FEE_DENOMINATOR);
        uint256 _reward = _want.mul(strategistReward).div(FEE_DENOMINATOR);
        IERC20(want).safeTransfer(controller, _fee);
        // IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
        IERC20(want).safeTransfer(strategist, _reward);
    }

    function balanceOf() public view returns (uint256) {
        return
            balanceOfWant()
                .add(balanceOfStakedWant()) //will not be correct if we sold syrup
                .add(balanceOfPendingWant());
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setPerformanceFee(uint256 _performanceFee) external {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!authorized"
        );
        performanceFee = _performanceFee;
    }

    function setStrategistReward(uint256 _strategistReward) external {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!authorized"
        );
        strategistReward = _strategistReward;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function setHarvesterReward(uint256 _harvesterReward) external {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!authorized"
        );
        harvesterReward = _harvesterReward;
    }

    function pause() external {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!authorized"
        );
        _withdrawAll();
        paused = true;
    }

    function unpause() external {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!authorized"
        );
        paused = false;
        _stakeCake();
    }

    //In case anything goes wrong - MasterChef has migrator function and we have no guarantees how it might be used.
    //This does not increase user risk. Governance already controls funds via strategy upgrade, and is behind timelock and/or multisig.
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public payable returns (bytes memory) {
        require(msg.sender == governance, "!governance");

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(
            callData
        );
        require(
            success,
            "Timelock::executeTransaction: Transaction execution reverted."
        );

        return returnData;
    }
}
