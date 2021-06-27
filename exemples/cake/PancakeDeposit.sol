pragma solidity =0.6.6;

// import "@uniswap/v2-core/contracts/interfaces/IPancakePair.sol";
// import '@uniswap/v2-core/contracts/interfaces/IPancakeFactory.sol';

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./libraries/PancakeLibrary.sol";

// import "./libraries/SafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

// https://github.com/Morpher-io/MorpherProtocol/blob/master/contracts/MorpherStaking.sol
// https://github.com/ApeSwapFinance/apeswap-swap-periphery/blob/master/contracts/examples/ExampleSwapToPrice.sol

// https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/examples/ExampleSwapToPrice.sol

contract PancakeDeposit {
    using SafeMath for uint256;

    // IPancakeRouter01 public immutable router;
    IPancakeRouter02 public immutable router;
    address public immutable factory;

    address public owner;
    address[] public depositers;

    // constructor(address factory_, IPancakeRouter01 router_) public {
    constructor(address factory_, IPancakeRouter02 router_) public {
        factory = factory_;
        router = router_;

        owner = msg.sender;
    }

    modifier onlyOwner {
        if (owner != msg.sender) require(false, "Only for owner");
        _;
    }

    modifier onlyMoreThanMinInvestment {
        if (msg.value <= 0.1 ether)
            require(false, "Only more than min investment");
        _;
    }

    modifier onlyMoreThanZero {
        if (msg.value == 0) require(false, "Only more than zero");
        _;
    }

    // function deposit() {}

    // function claim() {}

    // function random() private view returns (uint256) {
    //     return uint256(keccak256(block.difficulty, now, depositers));
    // }

    // computes the direction and magnitude of the profit-maximizing trade
    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) public pure returns (bool aToB, uint256 amountIn) {
        aToB = reserveA.mul(truePriceTokenB) / reserveB < truePriceTokenA;

        uint256 invariant = reserveA.mul(reserveB);

        uint256 leftSide = Babylonian.sqrt(
            invariant.mul(aToB ? truePriceTokenA : truePriceTokenB).mul(1000) /
                uint256(aToB ? truePriceTokenB : truePriceTokenA).mul(997)
        );
        uint256 rightSide = (aToB ? reserveA.mul(1000) : reserveB.mul(1000)) /
            997;

        // compute the amount that must be sent to move the price to the profit-maximizing price
        amountIn = leftSide.sub(rightSide);
    }

    // swaps an amount of either token such that the trade is profit-maximizing, given an external true price
    // true price is expressed in the ratio of token A to token B
    // caller must approve this contract to spend whichever token is intended to be swapped
    function swapToPrice(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 maxSpendTokenA,
        uint256 maxSpendTokenB,
        address to,
        uint256 deadline
    ) public {
        // true price is expressed as a ratio, so both values must be non-zero
        require(
            truePriceTokenA != 0 && truePriceTokenB != 0,
            "ExampleSwapToPrice: ZERO_PRICE"
        );
        // caller can specify 0 for either if they wish to swap in only one direction, but not both
        require(
            maxSpendTokenA != 0 || maxSpendTokenB != 0,
            "ExampleSwapToPrice: ZERO_SPEND"
        );

        bool aToB;
        uint256 amountIn;
        {
            (uint256 reserveA, uint256 reserveB) = PancakeLibrary.getReserves(
                factory,
                tokenA,
                tokenB
            );
            (aToB, amountIn) = computeProfitMaximizingTrade(
                truePriceTokenA,
                truePriceTokenB,
                reserveA,
                reserveB
            );
        }

        // spend up to the allowance of the token in
        uint256 maxSpend = aToB ? maxSpendTokenA : maxSpendTokenB;
        if (amountIn > maxSpend) {
            amountIn = maxSpend;
        }

        address tokenIn = aToB ? tokenA : tokenB;
        address tokenOut = aToB ? tokenB : tokenA;
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountIn
        );
        TransferHelper.safeApprove(tokenIn, address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        router.swapExactTokensForTokens(
            amountIn,
            0, // amountOutMin: we can skip computing this number because the math is tested
            path,
            to,
            deadline
        );
    }
}
