pragma solidity 0.6.6;

abstract contract IStaking {
    function lastReward() public view virtual returns (uint256);

    function totalShares() public view virtual returns (uint256);

    function interestRate() public view virtual returns (uint256);

    function lockupPeriod() public view virtual returns (uint256);

    function minimumStake() public view virtual returns (uint256);

    function stakingAdmin() public view virtual returns (address);

    function updatePoolShareValue()
        public
        virtual
        returns (uint256 _newPoolShareValue);

    function stake(uint256 _amount)
        public
        virtual
        returns (uint256 _poolShares);

    function unStake(uint256 _numOfShares)
        public
        virtual
        returns (uint256 _amount);
}
