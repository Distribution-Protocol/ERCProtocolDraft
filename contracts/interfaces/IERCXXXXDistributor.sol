// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


/**
 * @notice The Distributor interface dictates how the holder of any ERC721 compliant tokens (parent token) 
 * can create editions that collectors can conditionally mint child tokens from. Parent token holder can 
 * use the setEdition to specify the condition for minting an edition of the parent token. An edition is 
 * defined by a Nft descriptor to the parent token, the address of the validator contract that specifies
 *  the rules to obtain the child token, the actions that is allowed after obtaining the token.
 *   
 * A Collector can mint a child token of an Edition given that the rules specified by the Validator are 
 * fulfilled.
 *
 * Parent tokens holder can set multiple different editions, each with different set of rules, and a 
 * different set of actions that the token holder will be empowered with after the minting of the token.
 */
interface IDistributor {

    /**
     * @dev Emitted when a nedition is created
     * 
     * @param editionHash The hash of the edition configuration
     * @param edition The edition that the editionHash is generated from
     * @param initData The data bytes for initialising the validator.
     */
    event SetEdition(bytes32 editionHash, Edition edition, bytes initData);
    
    /**
     * @dev Emitted when an edition is paused
     * 
     * @param editionHash The hash of the edition configuration
     */
    event PauseEdition(bytes32 editionHash);


    /**
     * The NFT Descritpor of the parent token
     */
    struct NFTDescriptor {
        address contractAddress;
        uint256 tokenId;
    }
    
    /**
     * @dev Edition struct holds the parameters that describes an edition
     *
     * @param NFTDescriptor The token descriptor of the parent token
     * @param validator The address of the validator contract
     * @param actions The functions in the descriptor contract that will be permitted.
     * It is a binary mask corresponds to 96 potential functions
     */
    struct Edition {
        NFTDescriptor descriptor;
        address validator;
        uint96 actions;
    }

    /**
     * @dev The parent token holder can set an edition that enables others
     * to mint child tokens given that they fulfil the given rules
     *
     * @param edition the basic parameters of the child token to be minted
     * @param initData the data to be input into the validator contract for seting up the rules
     * 
     * @return editionHash Returns the hash of the edition conifiguration 
     */
    function setEdition(
        Edition memory edition,
        bytes calldata initData
    ) external returns (bytes32 editionHash);
    
    /**
     * @dev The parent token holder can pause the edition
     *
     * @param editionHash the hash of the edition
     */ 
    function pauseEdition(
        bytes32 editionHash
    ) external;

    /**
     * @dev Find the parent token of an edition
     *
     * @param editionHash the hash of the edition
     *
     * @return edition the edition data
     */
    function getEdition(
        bytes32 editionHash
    ) external view returns (Edition memory edition);

}
