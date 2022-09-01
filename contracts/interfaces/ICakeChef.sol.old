pragma solidity ^0.6.12;

interface CakeChef {
    function BONUS_MULTIPLIER() external view returns (uint256);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external;

    function cake() external view returns (address);

    function cakePerBlock() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function dev(address _devaddr) external;

    function devaddr() external view returns (address);

    function emergencyWithdraw(uint256 _pid) external;

    function enterStaking(uint256 _amount) external;

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    function leaveStaking(uint256 _amount) external;

    function massUpdatePools() external;

    function migrate(uint256 _pid) external;

    function migrator() external view returns (address);

    function owner() external view returns (address);

    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accCakePerShare
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setMigrator(address _migrator) external;

    function startBlock() external view returns (uint256);

    function syrup() external view returns (address);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updateMultiplier(uint256 multiplierNumber) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
}
