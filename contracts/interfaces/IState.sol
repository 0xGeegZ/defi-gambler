pragma solidity 0.6.6;

abstract contract IState {
    function setPosition(
        address _address,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
    ) public virtual;

    function getPosition(address _address, bytes32 _marketId)
        public
        view
        virtual
        returns (
            uint256 _longShares,
            uint256 _shortShares,
            uint256 _meanEntryPrice,
            uint256 _meanEntrySpread,
            uint256 _meanEntryLeverage,
            uint256 _liquidationPrice
        );

    function getLastUpdated(address _address, bytes32 _marketId)
        public
        view
        virtual
        returns (uint256 _lastUpdated);

    function transfer(
        address _from,
        address _to,
        uint256 _token
    ) public virtual;

    function balanceOf(address _tokenOwner)
        public
        view
        virtual
        returns (uint256 balance);

    function mint(address _address, uint256 _token) public virtual;

    function burn(address _address, uint256 _token) public virtual;

    function getSideChainOperator()
        public
        view
        virtual
        returns (address _address);

    function inactivityPeriod() public view virtual returns (uint256);

    function getSideChainMerkleRootWrittenAtTime()
        public
        view
        virtual
        returns (uint256 _sideChainMerkleRoot);

    function fastTransfersEnabled() public view virtual returns (bool);

    function mainChain() public view virtual returns (bool);

    function setInactivityPeriod(uint256 _periodLength) public virtual;

    function disableFastWithdraws() public virtual;

    function setSideChainMerkleRoot(bytes32 _sideChainMerkleRoot)
        public
        virtual;

    function resetLast24HoursAmountWithdrawn() public virtual;

    function set24HourWithdrawLimit(uint256 _limit) public virtual;

    function getTokenSentToLinkedChain(address _address)
        public
        view
        virtual
        returns (uint256 _token);

    function getTokenClaimedOnThisChain(address _address)
        public
        view
        virtual
        returns (uint256 _token);

    function getTokenSentToLinkedChainTime(address _address)
        public
        view
        virtual
        returns (uint256 _timeStamp);

    function lastWithdrawLimitReductionTime()
        public
        view
        virtual
        returns (uint256);

    function withdrawLimit24Hours() public view virtual returns (uint256);

    function update24HoursWithdrawLimit(uint256 _amount) public virtual;

    function last24HoursAmountWithdrawn() public view virtual returns (uint256);

    function setTokenSentToLinkedChain(address _address, uint256 _token)
        public
        virtual;

    function setTokenClaimedOnThisChain(address _address, uint256 _token)
        public
        virtual;

    function add24HoursWithdrawn(uint256 _amount) public virtual;

    function getPositionHash(
        address _address,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
    ) public pure virtual returns (bytes32 _hash);

    function getPositionClaimedOnMainChain(bytes32 _positionHash)
        public
        view
        virtual
        returns (bool _alreadyClaimed);

    function setPositionClaimedOnMainChain(bytes32 _positionHash)
        public
        virtual;

    function getBalanceHash(address _address, uint256 _balance)
        public
        pure
        virtual
        returns (bytes32 _hash);

    function getSideChainMerkleRoot()
        public
        view
        virtual
        returns (bytes32 _sideChainMerkleRoot);

    function getBridgeNonce() public virtual returns (uint256 _nonce);
}
