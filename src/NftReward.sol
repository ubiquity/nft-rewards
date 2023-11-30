// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title NFT reward contract
 * @notice Allows NFT minter to sign off-chain mint requests for target users
 * who can later claim NFTs by minter's signature
 */
contract NftReward is ERC721, Ownable, Pausable {
    /// @notice Base URI used for all of the tokens
    string public baseUri;

    /// @notice Minter address who will sign off-chain mint requests
    address public minter;

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
    {
        minter = _minter;
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
