pragma solidity ^0.6.6;

//TODO
// Manage list of games.
// Each game need to have an associated Vault to manage users funds.
// Vault will be created by the Controller and will be given to Game
contract Controller {
    struct GameConfig {
        address vaultAdress;
        address gameAdress;
        //TODO add Game parameters
        // uint256 amountInvested;
        // bool votedForEmergencyWithdrawal;
    }
    GameConfig[] public deployedGamesConfig;
    address[] public deployedGamesAddresses;

    function createGame(uint256 minimum) public {
        // address newCampaign = new Campaign(minimum, msg.sender);
        GameConfig memory newGameConfig = GameConfig({
            vaultAdress: "",
            gameAdress: ""
        });
        deployedGamesConfig.push(newGameConfig);
        // deployedGamesAddresses.push(newGameConfig);
    }

    function getDeployedGamesAdresses() public view returns (address[] memory) {
        return deployedGamesAddresses;
    }
}
