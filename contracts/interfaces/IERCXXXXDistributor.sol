// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


/**
 * @notice The Interface dictates how the holder of any ERC721 compiant tokens (parent token) can create editions that collectors can conditionally 
 * mint child tokens that gives certain privaleges to both parties. Creator can use the setEdition to specify the condition for minting
 * a edition of the parent token. A edition is defined by a Nft descriptor to the parent token, the validator contract 
 * that specifies the rules to mint, the creator actions and the collector actions.
 * 
 * The Validtor interface resides in the IERCXXXXValidator.sol file. Each edition requires certain rules that must be fulfilled before
 * minting. The Validator contract is responsible for the storage as well as the validation of the rules.
 * 
 * The Creator actions refers to the set of actions that the holder of the parent token can perform on the child tokens.
 * The Collector actions refers to the set of actions that the holder of the child tokens can perform.
 * 
 * A Collector can mint a child token of a Edition given that the rules specified by the Validator are fulfilled.
 *
 * Parent tokens holder can set multiple different editions, each with different mint rules, and a different set of actions that the token holder
 * will be empowered with after the minting of the token.
 */
interface IDistributor {

    /**
     * @dev Emitted when a edition is created
     * 
     * @param distHash The hash of the edition configuration
     * @param edition The edition that the distHash is generated from
     */
    event SetEdition(bytes32 distHash, Edition edition);
    
    /**
     * @dev Emitted when a edition is paused
     * 
     * @param distHash The hash of the edition configuration
     */
    event PauseEdition(bytes32 distHash);


    /**
     * The NFT Descritpor of the parent token
     */
    struct NFTDescriptor {
        address contractAddress;
        uint256 tokenId;
    }
    
    /**
     * @dev Edition struct that specifies the input to the validation function
     *
     * @param NFTDescriptor The tokenId of the parent token
     */
    struct Edition {
        NFTDescriptor descriptor;
        address validator;
        bytes4[] parentActions;
        bytes4[] childActions;
    }

    /**
     * @dev The creator who holds a parent token can set a edition that enables others
     * to mint copies given that they fulfil the given rules
     *
     * @param edition the basic states of the child token to be minted
     * @param initData the data to be input into the validator contract for setup the rules
     * 
     * @return distHash Returns the hash of the edition conifiguration 
     */
    function setEdition(
        Edition memory edition,
        bytes calldata initData
    ) external returns (bytes32 distHash);
    
    /**
     * @dev The creator can pause the edition
     *
     * @param distHash the hash of the edition for minting
     */ 
    function pauseEdition(
        bytes32 distHash
    ) external;

    /**
     * @dev The owner can unpause the edition
     *
     * @param distHash the hash of the edition
     *
     * @return descriptor the parent token
     */
    function parentOf(bytes32 distHash) external view returns (NFTDescriptor memory descriptor);

}
