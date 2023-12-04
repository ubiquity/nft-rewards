// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title NFT reward contract
 * @notice Allows NFT minter to sign off-chain mint requests for target users
 * who can later claim NFTs by minter's signature
 */
contract NftReward is ERC721, Ownable, Pausable, EIP712 {
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
     * @notice Contract constructor
     * @param _tokenName NFT token name
     * @param _tokenSymbol NFT token symbol
     * @param _initialOwner Initial owner name
     * @param _minter Minter address
     */
    constructor (
        string memory _tokenName, 
        string memory _tokenSymbol,
        address _initialOwner,
        address _minter
    ) 
        ERC721(_tokenName, _tokenSymbol) 
        Ownable(_initialOwner)
        EIP712("NftReward-Domain", "1")
    {
        minter = _minter;
    }

    //==================
    // Public methods
    //==================

    /**
     * @notice Returns mint request digest which should be signed by `minter`
     * @param _mintRequest Mint request data
     * @return Mint request digest which should be signed by `minter`
     */
    function getMintRequestDigest(MintRequest calldata _mintRequest) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("MintRequest(address beneficiary,uint256 deadline,bytes32[] keys,uint256 nonce,string[] values"),
            _mintRequest.beneficiary,
            _mintRequest.deadline,
            _mintRequest.keys,
            _mintRequest.nonce,
            _mintRequest.values
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
     * @param _mintRequest Mint request data
     * @param _signature Minter signature
     * @return Signer of the mint request
     */
    function recover(
        MintRequest calldata _mintRequest, 
        bytes calldata _signature
    ) 
        public 
        view 
        returns (address) 
    {
        bytes32 digest = getMintRequestDigest(_mintRequest);
        address signer = ECDSA.recover(digest, _signature);
        return signer;
    }

    /**
     * @notice Mints a reward NFT to beneficiary who provided a mint request with valid minter's signature
     * @param _mintRequest Mint request data
     * @param _signature Minter signature
     */
    function safeMint(
        MintRequest calldata _mintRequest,
        bytes calldata _signature
    ) public {
        // validation
        require(recover(_mintRequest, _signature) == minter, "Signed not by minter");
        require(msg.sender == _mintRequest.beneficiary, "Not eligible");   
        require(block.timestamp < _mintRequest.deadline, "Signature expired");
        require(!nonceRedeemed[_mintRequest.nonce], "Already minted");
        require(_mintRequest.keys.length == _mintRequest.values.length, "Key/value length mismatch");
        
        // mark nonce as used
        nonceRedeemed[_mintRequest.nonce] = true;
        
        // save arbitrary token data
        uint256 keysCount = _mintRequest.keys.length;
        for (uint256 i = 0; i < keysCount; i++) {
            // save data
            tokenData[tokenIdCounter][_mintRequest.keys[i]] = _mintRequest.values[i];
            // save arbitrary token data key if not saved yet
            if (!tokenDataKeyExists[_mintRequest.keys[i]]) {
                tokenDataKeys.push(_mintRequest.keys[i]);
                tokenDataKeyExists[_mintRequest.keys[i]] = true;
            }
        }
        
        // mint token to beneficiary
        _safeMint(_mintRequest.beneficiary, tokenIdCounter);
        
        // increase token counter
        tokenIdCounter++;
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
     * @param _newBaseUri New base URI
     */
    function setBaseUri(string memory _newBaseUri) external onlyOwner {
        baseUri = _newBaseUri; 
    }

    /**
     * @notice Sets new minter address (who can sign off-chain mint requests)
     * @param _newMinter New minter address
     */
    function setMinter(address _newMinter) external onlyOwner {
        minter = _newMinter;
    }

    /**
     * @notice Unpauses contract operations
     */
    function unpause() external onlyOwner {
        _unpause();
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
