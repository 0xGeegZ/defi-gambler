pragma solidity ^0.6.12;

import "./Game.sol";

//TODO
// Manage list of games.
// Each game need to have an associated Vault to manage users funds.
// Vault will be created by the Controller and will be given to Game
contract GameFactory {
    // struct GameConfig {
    //     address vaultAdress;
    //     address gameAdress;
    //     //TODO add Game parameters
    //     // uint256 amountInvested;
    //     // bool votedForEmergencyWithdrawal;
    // }
    // GameConfig[] public deployedGamesConfig;
    mapping(address => Game) public deployedGamesConfig;

    address[] public deployedGamesAddresses;

    Game[] public deployedGames;

    //uint256 public pwin = 5000; //probability of winning (10000 = 100%)
    //uint256 public edge = 200; //edge percentage (10000 = 100%)
    //uint256 public maxWin = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
    //uint256 public minBet = 10 finney; //https://www.cryps.info/en/Finney_to_ETH/1/ - https://eth-converter.com/
    //uint256 public maxInvestors = 5; //maximum number of investors
    //uint256 public houseEdge = 50; //edge percentage (10000 = 100%)
    //uint256 public divestFee = 50; //divest fee percentage (10000 = 100%)
    //uint256 public emergencyWithdrawalRatio = 90; //ratio percentage (100 = 100%)
    // function createGame(
    //     uint256 pwinInitial,
    //     uint256 edgeInitial,
    //     uint256 maxWinInitial,
    //     uint256 minBetInitial,
    //     uint256 maxInvestorsInitial,
    //     uint256 houseEdgeInitial,
    //     uint256 divestFeeInitial,
    //     uint256 emergencyWithdrawalRatioInitial
    // ) public {
    function createGame() public {
        // Game newGame = new Game(address(this), msg.sender);
        Game newGame = new Game(msg.sender);

        //  address newGame = new Game(
        //     address(this),
        //     msg.sender,
        //     pwinInitial,
        //     edgeInitial,
        //     maxWinInitial,
        //     minBetInitial,
        //     maxInvestorsInitial,
        //     houseEdgeInitial,
        //     divestFeeInitial,
        //     emergencyWithdrawalRatioInitial
        // );

        //TODO get Vault adress
        // address vault = newGame.

        // GameConfig memory newGameConfig = GameConfig({
        //     vaultAdress: "",
        //     gameAdress: newGame,
        //     pwin: pwinInitial,
        //     edge: edgeInitial,
        //     maxWin: maxWinInitial,
        //     minBet: minBetInitial,
        //     maxInvestors: maxInvestorsInitial,
        //     houseEdge: houseEdgeInitial,
        //     divestFee: divestFeeInitial,
        //     emergencyWithdrawalRatio: emergencyWithdrawalRatioInitial
        // });
        // deployedGamesConfig(newGameConfig) = newGameConfig;
        // deployedGamesAddresses.push(newGame);
        deployedGames.push(newGame);
        deployedGamesAddresses.push(address(newGame));
        // deployedGamesConfig(address(newGame)) = newGame;
    }

    function getDeployedGamesAdresses() public view returns (address[] memory) {
        return deployedGamesAddresses;
    }

    function getDeployedGames() public view returns (Game[] memory) {
        return deployedGames;
    }

    // function getDeployedGamesConfig(address deployedGamesAddress)
    //     public
    //     view
    //     returns (GameConfig memory)
    // {
    //     return deployedGamesConfig(deployedGamesAddress);
    // }
}
