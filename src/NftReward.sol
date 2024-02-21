// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title NFT reward contract
 * @notice Allows NFT minter to sign off-chain mint requests for target users
 * who can later claim NFTs by minter's signature
 */
contract NftReward is Initializable, ERC721Upgradeable, OwnableUpgradeable, PausableUpgradeable, EIP712Upgradeable, UUPSUpgradeable {
    /// @notice Base URI used for all of the tokens
    string public baseUri;

    /// @notice Minter address who will sign off-chain mint requests
    address public minter;

    /// @notice Mapping to check whether nonce is redeemed 
    mapping (uint256 nonce => bool isRedeemed) public nonceRedeemed;

    /// @notice Arbitrary token data
    mapping (uint256 tokenId => mapping(bytes32 key => string value)) public tokenData;

    /// @notice Array of all arbitraty token data keys (useful for UI)
    bytes32[] public tokenDataKeys;

    /// @notice Mapping to check whether token data key exists
    mapping(bytes32 tokenDataKey => bool isTokenDataKeyExists) public tokenDataKeyExists;

    /// @notice Total amount of minted tokens
    uint256 public tokenIdCounter;

    /// @notice Mint request signed by minter
    struct MintRequest {
        // address which is eligible for minting NFT
        address beneficiary;
        // unix timestamp until mint request is valid
        uint256 deadline;
        // array of arbitrary data keys
        bytes32[] keys;
        // unique number used to prevent mint request reusage
        uint256 nonce;
        // array of arbitrary data values
        string[] values;
    }

    /**
     * @notice _disableInitializers in the constructor, 
     * this prevents initialization of the implementation contract itself, 
     * as extra protection to prevent an attacker from initializing it.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract initializer (replaces constructor)
     * @param tokenName NFT token name
     * @param tokenSymbol NFT token symbol
     * @param initialOwner Initial owner name
     * @param minterAddress Minter address
     */
    function initialize(
        string memory tokenName, 
        string memory tokenSymbol,
        address initialOwner,
        address minterAddress
    ) 
        public 
        initializer 
    {
        require(minterAddress != address(0), "Minter cannot be zero address");
        require(initialOwner != address(0), "Initial owner cannot be zero address");
        __ERC721_init(tokenName, tokenSymbol);
        __Ownable_init(initialOwner);
        __EIP712_init("NftReward-Domain", "1");
        __UUPSUpgradeable_init();
        __Pausable_init();
        minter = minterAddress;
    }

    //==================
    // Public methods
    //==================

    /**
     * @notice Returns mint request digest which should be signed by `minter`
     * @param mintRequest Mint request data
     * @return Mint request digest which should be signed by `minter`
     */
    function getMintRequestDigest(MintRequest calldata mintRequest) public view returns (bytes32) {
        // for `string[]` array type we need to hash all the array values first
        bytes32[] memory valuesHashed = new bytes32[](mintRequest.values.length);
        for (uint256 i = 0; i < mintRequest.values.length; i++) {
            valuesHashed[i] = keccak256(bytes(mintRequest.values[i]));
        }
        // return final hash
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("MintRequest(address beneficiary,uint256 deadline,bytes32[] keys,uint256 nonce,string[] values)"),
            mintRequest.beneficiary,
            mintRequest.deadline,
            keccak256(abi.encodePacked(mintRequest.keys)),
            mintRequest.nonce,
            keccak256(abi.encodePacked(valuesHashed))
        )));
    }

    /**
     * @notice Returns all arbitrary token data keys (useful for UI)
     * @return Array of all arbitrary token data keys
     */
    function getTokenDataKeys() public view returns(bytes32[] memory) {
        return tokenDataKeys;
    }

    /**
     * @notice Returns signer of the mint request
     * @param mintRequest Mint request data
     * @param signature Minter signature
     * @return Signer of the mint request
     */
    function recover(
        MintRequest calldata mintRequest, 
        bytes calldata signature
    ) 
        public 
        view 
        returns (address) 
    {
        bytes32 digest = getMintRequestDigest(mintRequest);
        address signer = ECDSA.recover(digest, signature);
        return signer;
    }

    /**
     * @notice Mints a reward NFT to beneficiary who provided a mint request with valid minter's signature
     * @param mintRequest Mint request data
     * @param signature Minter signature
     */
    function safeMint(
        MintRequest calldata mintRequest,
        bytes calldata signature
    ) 
        public
        whenNotPaused
    {
        // validation
        require(recover(mintRequest, signature) == minter, "Signed not by minter");
        require(msg.sender == mintRequest.beneficiary, "Not eligible");   
        require(block.timestamp < mintRequest.deadline, "Signature expired");
        require(!nonceRedeemed[mintRequest.nonce], "Already minted");
        require(mintRequest.keys.length == mintRequest.values.length, "Key/value length mismatch");
        
        // mark nonce as used
        nonceRedeemed[mintRequest.nonce] = true;
        
        // save arbitrary token data
        uint256 keysCount = mintRequest.keys.length;
        for (uint256 i = 0; i < keysCount; i++) {
            // save data
            tokenData[tokenIdCounter][mintRequest.keys[i]] = mintRequest.values[i];
            // save arbitrary token data key if not saved yet
            if (!tokenDataKeyExists[mintRequest.keys[i]]) {
                tokenDataKeys.push(mintRequest.keys[i]);
                tokenDataKeyExists[mintRequest.keys[i]] = true;
            }
        }
        
        // mint token to beneficiary
        _safeMint(mintRequest.beneficiary, tokenIdCounter++);
    }

    //=================
    // Owner methods
    //=================

    /**
     * @notice Pauses contract operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Sets new base URI for all of the tokens
     * @param newBaseUri New base URI
     */
    function setBaseUri(string memory newBaseUri) external onlyOwner {
        baseUri = newBaseUri; 
    }

    /**
     * @notice Sets new minter address (who can sign off-chain mint requests)
     * @param newMinter New minter address
     */
    function setMinter(address newMinter) external onlyOwner {
        require(newMinter != address(0), "Minter cannot be zero address");
        minter = newMinter;
    }

    /**
     * @notice Unpauses contract operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Upgrades contract to new implementation
     * @param newImplementation New implementation address
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Invalidates nonce value to prevent mint request reusage
     * @param nonceValue Nonce value to invalidate
     */
    function invalidateNonce(uint256 nonceValue) external onlyOwner {
        require(!nonceRedeemed[nonceValue], "Already minted");
        nonceRedeemed[nonceValue] = true;
    }

    //====================
    // Internal methods
    //====================

    /**
     * @notice Returns URI used for all of the tokens
     * @return URI used for all of the tokens
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
}
