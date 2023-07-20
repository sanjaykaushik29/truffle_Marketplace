// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Interface
interface INFTLaunchPad {
    function getBrokerage(address currency) external view returns (int256);

    function brokerAddress() external view returns (address);

    function getPublicKey() external view returns (address);
}

contract NFTCollection is ERC721A, ERC2981, Ownable {
    uint256 public maxSupply; //Set the maximum supply
    string baseURI; //Set the Base URI
    string baseURISuffix = ".json"; //Set the base URI Suffix
    string public contractURI; //Set the contract URI
    address public creator; //Address of Creator
    mapping(uint256 => bool) public proceedNonce; //set nonce
    uint256 public constant DECIMAL_PRECISION = 100; //Set the Decimal Precision
    uint256 public tokenCounter; //Set the tokenCounter
    INFTLaunchPad public launchpad; //Set the address of launchpad
    mapping(address => uint256) public nftMinted;

    //Structs
    struct UintArgs {
        uint256 maxSupply;
        uint96 royalty;
    }
    struct StringArgs {
        string name;
        string symbol;
        string baseURI;
        string contractURI;
    }
    struct Phase {
        mapping(address => uint256) currenciesPrice;
        mapping(address => uint256) whitelistCurrencyPrice;
        mapping(address => bool) currencies;
        mapping(address => bool) whiteListCurrencies;
        bool isWhitelisted;
        uint256 startTime;
        uint256 endTime;
        uint256 WhiteListStartTime;
        uint256 WhiteListEndTime;
        uint256 maxNFTPerUser;
        uint256 maxQuantity;
    }

    struct PhaseArgs {
        address[] currencies;
        uint256[] currenciesPrice;
        address[] whiteListCurrencies;
        uint256[] whiteListCurrenciesPrice;
        bool isWhiteListed;
        uint256 WhiteListStartTime;
        uint256 WhiteListEndTime;
        uint256 maxNFTPerUser;
        uint256 maxQuantity;
    }

    mapping(uint256 => Phase) phases;

    event MintRange(address currencys, uint256 startRange, uint256 endRange);

    event CollecctionPhase(
        uint256 phaseId,
        address[] Currencies,
        uint256[] currenciesPrice,
        address[] whiteListCurrencies,
        uint256[] whiteListCurrenciesPrice,
        bool isWhitelisted,
        uint256 WhiteListStartTime,
        uint256 WhiteListEndTime,
        uint256 maxNFTPerUser,
        uint256 maxQuantity
    );

    constructor(
        UintArgs memory _uints,
        address _creator,
        StringArgs memory _strings,
        PhaseArgs[] memory _phaseArgs
    ) ERC721A(_strings.name, _strings.symbol) {
         toyota = Cars(CarType.Toyota, _toyotaCount);
        maxSupply = _uints.maxSupply;
        creator = _creator;
        baseURI = _strings.baseURI;
        contractURI = _strings.contractURI;
        launchpad = INFTLaunchPad(msg.sender);
        _setDefaultRoyalty(creator, _uints.royalty);
        _transferOwnership(creator);
        _phases(_phaseArgs);
    }

    function _phases(PhaseArgs[] memory _phaseArgs) public {
        for (uint256 i = 0; i < _phaseArgs.length; i++) {
            require(
                _phaseArgs[i].currencies.length ==
                    _phaseArgs[i].currenciesPrice.length
            );
            require(
                _phaseArgs[i].whiteListCurrencies.length ==
                    _phaseArgs[i].whiteListCurrenciesPrice.length
            );
            for (uint256 j = 0; j < _phaseArgs[i].currencies.length; j++) {
                phases[i].currenciesPrice[
                    _phaseArgs[i].currencies[j]
                ] = _phaseArgs[i].currenciesPrice[j];

                if (_phaseArgs[i].currenciesPrice[j] == 0) {
                    phases[i].currencies[_phaseArgs[i].currencies[j]] = true;
                }
            }
            for (
                uint256 j = 0;
                j < _phaseArgs[i].whiteListCurrencies.length;
                j++
            ) {
                phases[i].whitelistCurrencyPrice[
                    _phaseArgs[i].whiteListCurrencies[j]
                ] = _phaseArgs[i].whiteListCurrenciesPrice[j];
                if (_phaseArgs[i].whiteListCurrenciesPrice[j] == 0) {
                    phases[i].whiteListCurrencies[
                        _phaseArgs[i].whiteListCurrencies[j]
                    ] = true;
                }
            }

            emit CollecctionPhase(
                i,
                _phaseArgs[i].currencies,
                _phaseArgs[i].currenciesPrice,
                _phaseArgs[i].whiteListCurrencies,
                _phaseArgs[i].whiteListCurrenciesPrice,
                _phaseArgs[i].isWhiteListed,
                _phaseArgs[i].WhiteListStartTime,
                _phaseArgs[i].WhiteListEndTime,
                _phaseArgs[i].maxNFTPerUser,
                _phaseArgs[i].maxQuantity
            );
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setMaxNFTPerUser(uint256 _amount, uint256 _phaseId)
        external
        onlyOwner
    {
        phases[_phaseId].maxNFTPerUser = _amount;
    }

    function setMaxQuantity(uint256 _amount, uint256 _phaseId)
        external
        onlyOwner
    {
        phases[_phaseId].maxQuantity = _amount;
    }

    function setMaxSupply(uint256 _newSupply) external onlyOwner {
        require(
            _newSupply < maxSupply && _newSupply >= tokenCounter,
            "NFTCollection: Supply Should be less than Max Supply"
        );
        maxSupply = _newSupply;
    }

    /**
     *@dev Method to generate signer.
     *@notice This method is used to provide signer.
     *@param hash: Name of hash is used to generate the signer.
     *@param _signature: Name of _signature is used to generate the signer.
     @return Signer address.
    */
    function getSigner(bytes32 hash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                v,
                r,
                s
            );
    }

    /**
     *@dev Method to get Brokerage.
     *@notice This method is used to get Brokerage.
     *@param _currency: address of Currency.
     */
    function _getBrokerage(address _currency) private view returns (uint256) {
        int256 _brokerage = launchpad.getBrokerage(_currency);
        require(_brokerage != 0, "NFTCollection: Currency doesn't supported.");
        if (_brokerage < 0) {
            _brokerage = 0;
        }
        return uint256(_brokerage);
    }

    /**
     *@dev Method to get PublicKey
     *@return It will return PublicKey
     */
    function _getPublicKey() private view returns (address) {
        return launchpad.getPublicKey();
    }

    /**
     *@dev Method to get Broker address
     *@return Return the address of broker
     */
    function _getBrokerAddress() private view returns (address) {
        return launchpad.brokerAddress();
    }

    /**
     *@dev Method to verify WhiteList user.
     *@notice This method is used to verify whitelist user.
     *@param whitelistUser: Address of whitelistUser.
     
     *@param nonce: nonce to be generated while minting.
     *@param _isWhiteListed: User is whitelisted or not.
     *@param _signature: _signature is used to generate the signer.
     *@return bool value if user is verified.
     */
    function verifyWhiteListUser(
        address whitelistUser,
        uint256 nonce,
        bool _isWhiteListed,
        bytes memory _signature,
        uint256 phaseId
    ) private view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                address(this),
                launchpad,
                whitelistUser,
                nonce,
                _isWhiteListed,
                phaseId
            )
        );
        address verifiedUser = getSigner(hash, _signature);
        require(
            verifiedUser == _getPublicKey(),
            "NFTCollection: User is not verified!"
        );
        return _isWhiteListed;
    }

    /**
     *@dev Method to split the signature.
     *@param sig: Name of _signature is used to generate the signer.
     */
    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "NFTCollection: invalid signature length.");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function _sendNative(uint256 brokerage, uint256 _amount) private {
        if (brokerage > 0) {
            uint256 brokerageAmount = (_amount * uint256(brokerage)) /
                (100 * DECIMAL_PRECISION);
            payable(_getBrokerAddress()).transfer(brokerageAmount);
            uint256 remainingAmount = _amount - brokerageAmount;
            payable(creator).transfer(remainingAmount);
        } else {
            payable(creator).transfer(_amount);
        }
    }

    function _sendERC20(
        uint256 brokerage,
        uint256 _amount,
        address _currency
    ) private {
        require(
            IERC20(_currency).allowance(msg.sender, address(this)) >= _amount,
            "NFTCollection: Insufficient fund allowance"
        );
        if (brokerage > 0) {
            uint256 brokerageAmount = (_amount * uint256(brokerage)) /
                (100 * DECIMAL_PRECISION);
            IERC20(_currency).transferFrom(
                msg.sender,
                _getBrokerAddress(),
                brokerageAmount
            );
            uint256 remainingAmount = _amount - brokerageAmount;
            IERC20(_currency).transferFrom(msg.sender, address(this), remainingAmount);
        } else {
            IERC20(_currency).transferFrom(msg.sender, address(this), _amount);
        }
    }

    /**
     *@dev Method to mint the NFT.
     *@notice This method is used to mint the NFT.
     *@param _quantity: NFT quantity to be minted.
     *@param nonce: nonce to be generated while minting.
     *@param _signature: _signature is used to generate the signer.
     *@param _isWhiteListed: User is whitelisted or not.
     */
    function mint(
        uint256 _quantity,
        uint256 nonce,
        bytes calldata _signature,
        bool _isWhiteListed,
        address _currency,
        uint256 _phaseId
    ) external payable {
        uint256 startRange = tokenCounter + 1;
        uint256 endRange = tokenCounter + _quantity;

        require(
            phases[_phaseId].startTime < block.timestamp &&
                phases[_phaseId].endTime > block.timestamp,
            "NFTCollection: Phase not ended yet."
        );

        require(
            tokenCounter + _quantity <= maxSupply,
            "NFTCollection: Max supply must be greater!"
        );
        tokenCounter += _quantity;
        require(
            nftMinted[msg.sender] + _quantity <= phases[_phaseId].maxNFTPerUser,
            "NFTCollection: Max limit reached"
        );
        require(!proceedNonce[nonce], "NFTCollection: Nonce already proceed!");

        require(
            _quantity > 0 && _quantity <= phases[_phaseId].maxQuantity,
            "NFTCollection: Max quantity reached"
        );
        bool WhiteListed = verifyWhiteListUser(
            msg.sender,
            nonce,
            _isWhiteListed,
            _signature,
            _phaseId
        );

        if (
            WhiteListed &&
            block.timestamp >= phases[_phaseId].WhiteListStartTime &&
            block.timestamp <= phases[_phaseId].WhiteListEndTime
        ) {
            // Phase storage _phase = phases[_phaseId];
            require(
                phases[_phaseId].currenciesPrice[_currency] > 0 ||
                    phases[_phaseId].currencies[_currency],
                "NFTCollection: Currency not Supported for whiteList minting"
            );
            uint256 whitelistedFee = phases[_phaseId].whitelistCurrencyPrice[
                _currency
            ];
            if (whitelistedFee > 0) {
                uint256 brokerage = _getBrokerage(address(_currency));
                if (address(_currency) == address(0)) {
                    require(
                        msg.value >= whitelistedFee * _quantity,
                        "NFTCollection: Whitelisted amount is insufficient."
                    );
                    _sendNative(brokerage, msg.value);
                } else {
                    _sendERC20(
                        brokerage,
                        whitelistedFee * _quantity,
                        _currency
                    );
                }
            }
        } else {
            require(
                phases[_phaseId].currenciesPrice[_currency] > 0 ||
                    phases[_phaseId].currencies[_currency],
                "NFTCollection: Currency not Supported for public minting"
            );

            uint256 mintFee = phases[_phaseId].currenciesPrice[_currency];

            if (mintFee > 0) {
                uint256 brokerage = _getBrokerage(address(_currency));
                require(
                    block.timestamp > phases[_phaseId].WhiteListEndTime,
                    "NFTCollection: Whitelist sale not ended yet."
                );
                if (address(_currency) == address(0)) {
                    require(
                        msg.value >= mintFee * _quantity,
                        "NFTCollection: amount is insufficient."
                    );
                    _sendNative(brokerage, msg.value);
                } else {
                    _sendERC20(brokerage, mintFee * _quantity, _currency);
                }
            }
        }
        _mint(msg.sender, _quantity);
        nftMinted[msg.sender] += _quantity;
        proceedNonce[nonce] = true;
        emit MintRange(_currency, startRange, endRange);
    }

    /**
     *@dev Method to burn NFT.
     *@param tokenId: tokenId to be burned.
     */
    function burn(uint256 tokenId) external {
        require(
            ownerOf(tokenId) == msg.sender,
            "NFTCollection: Caller is not the token owner"
        );
        _burn(tokenId, false);
    }

    /**
     *@dev Method to mint by only owner.
     *@notice This method will allow onlyOwner to mint.
     *@param _quantity: NFT quantity to be minted.
     */
    function mintByOwner(uint256 _quantity) external onlyOwner {
        require(
            tokenCounter + _quantity <= maxSupply,
            "NFTCollection: Max supply must be greater!"
        );
        tokenCounter += _quantity;
        _mint(msg.sender, _quantity);
    }

    /**
     *@dev Method to withdraw ERC20 token.
     *@notice This method will allow only owner to withdraw ERC20 token.
     *@param _receiver: address of receiver
     */
    function withdrawERC20Token(address _receiver, address _currency)
        external
        onlyOwner
    {
        IERC20 currency = IERC20(_currency);
        require(
            currency.balanceOf(address(this)) > 0,
            "NFTCollection: Insufficient fund"
        );
        currency.transfer(_receiver, currency.balanceOf(address(this)));
    }

    /**
     *@dev Method to withdraw native currency.
     *@notice This method will allow only owner to withdraw currency.
     *@param _receiver: address of receiver
     */
    function withdrawBNB(address _receiver) external onlyOwner {
        payable(_receiver).transfer(balanceOf(address(this)));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _baseURISuffix() internal view virtual returns (string memory) {
        return baseURISuffix;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _toString(tokenId), baseURISuffix)
                )
                : "";
    }
}
