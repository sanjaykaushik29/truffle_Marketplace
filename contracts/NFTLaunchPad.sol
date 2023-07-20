// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./NFTCollection.sol";
import "./RollManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract NFTLaunchPad is Initializable, RoleManager {
    address[] _allCollections; //Addresses of collections
    address platformPublicKey; //Address of Public key
    address public brokerAddress; //Address of broker
    mapping(address => address[]) _userCollections;
    mapping(address => int256) brokerage;

    function initialize(address _brokerAddress, address _platformPublicKey)
        external
        initializer
    {
        initialize1();
        brokerAddress = _brokerAddress;
        platformPublicKey = _platformPublicKey;
    }

    //Event
    event CreateLaunchpad(
        address indexed creator,
        address indexed collection,
        uint256 creationtime,
        string name,
        string symbol,
        string contractURI,
        uint256 maxSupply
    );

    /**
     *@dev Method to set brokerage.
     *@notice allow only autorized user to call this function.
     *@param _brokerage new brokerage.
     *@param currency address of currency.
     */
    function setBrokerage(int256 _brokerage, address currency)
        external
        isOperator
    {
        brokerage[currency] = _brokerage;
    }

    function getBrokerage(address currency) internal view returns (int256) {
        return brokerage[currency];
    }

    /**
     *@dev Method to set broker address.
     *@notice allow only autorized user to call this function.
     *@param newBrokerAddress address of new broker.
     */
    function setBroker(address newBrokerAddress) external isOperator {
        require(
            newBrokerAddress != address(0) && newBrokerAddress != brokerAddress,
            "NFTLaunchPad: New address should not be address 0x0 nor existing address"
        );
        brokerAddress = newBrokerAddress;
    }

    /**
     *@dev Method to set PlatformPublicKey
     *@notice allow only authorized user to call this function
     *@param _newPlatformPublicKey to be set
     */
    function updatePublicKey(address _newPlatformPublicKey)
        external
        isOperator
    {
        platformPublicKey = _newPlatformPublicKey;
    }

    /**
     *@dev Method to get PublicKey
     *@return Returns platformPublicKey
     */
    function getPublicKey() external view returns (address) {
        return platformPublicKey;
    }

    // /**
    //  *@dev Method to create new NFTLaunchPad.
    //  *@param _uints struct of integer values used to create launchPad
    //  *@param _strings struct of string used to create launchPad
    //  *@param _enableWhiteList bool value to enable or disable whiteList
    //  *@param _currencies address of the currencies
    //  *@param _whiteListCurrencies address of the whiteList Currencies
    //  *@param _currenciesPrice prices of the currencies
    //  *@param _whiteListCurrenciesPrice  prices of the whiteListed Currencies
    //  *@return _launchpad the address of new create launchPad
    //  */
    function createLaunchPad(
        uint256 _maxSupply,
        uint96 _royality,
        NFTCollection.StringArgs memory _strings,
        bool _enableWhiteList,
        NFTCollection.PhaseArgs[] memory _phaseArgs
    ) external returns (address _launchpad) {
        require(
            (_royality >= 0 && _royality <= 10000),
            "NFTLaunchPad: Royalty should be less than 10000"
        );
        for (uint256 i = 0; i < _phaseArgs.length; i++) {
            require(
                _phaseArgs[i].maxNFTPerUser >= _phaseArgs[i].maxQuantity &&
                    _phaseArgs[i].maxQuantity > 0,
                "NFTLaunchPad: Invalid quantities."
            );
        }

        for (uint256 i = 0; i < _phaseArgs.length; i++) {
            for (uint256 j = 0; j < _phaseArgs[i].currencies.length; j++) {
                require(
                    getBrokerage(_phaseArgs[i].currencies[j]) != 0,
                    "NFTLaunchpad: Currency not Supported"
                );
            }
        }

        if (_enableWhiteList) {
            for (uint256 i = 0; i < _phaseArgs.length; i++) {
                require(
                    _phaseArgs[i].WhiteListStartTime > block.timestamp,
                    "NFTLaunchPad: WhiteListStartTime should be greater than current time"
                );

                require(
                    _phaseArgs[i].WhiteListEndTime >
                        _phaseArgs[i].WhiteListStartTime,
                    "NFTLaunchPad: WhiteListEndTime should be greater than whiteListStartTime"
                );

                for (
                    uint256 j = 0;
                    j < _phaseArgs[i].whiteListCurrencies.length;
                    j++
                ) {
                    require(
                        getBrokerage(_phaseArgs[i].whiteListCurrencies[j]) != 0,
                        "NFTLaunchpad: WhiteListCurrency not Supported"
                    );
                }
            }
        }
        NFTCollection launchpadCollection = new NFTCollection(
            _uints,
            msg.sender,
            _strings,
            _phaseArgs
        );

        _allCollections.push(address(launchpadCollection));
        _userCollections[msg.sender].push(address(launchpadCollection));

        emit CreateLaunchpad(
            msg.sender,
            address(launchpadCollection),
            block.timestamp,
            _strings.name,
            _strings.symbol,
            _strings.contractURI,
            _uints.maxSupply
        );

        _launchpad = address(launchpadCollection);
        return _launchpad;
    }

    /**
     * @dev Method to get all created LaunchPad.
     * @return return array of created collections.
     */
    function getCollections() external view returns (address[] memory) {
        return _allCollections;
    }

    /**
     * @dev Method to get created LaunchPad of specific user.
     * @param user: address of user to get their collections
     * @return return array of created collections of user.
     */
    function getUserCollection(address user)
        external
        view
        returns (address[] memory)
    {
        return _userCollections[user];
    }
}
