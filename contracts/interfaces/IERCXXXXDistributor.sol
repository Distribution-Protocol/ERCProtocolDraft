// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


/**
 * @notice The Interface dictates how the holder of any ERC721 compiant tokens (primary token) can create distributions that collectors can conditionally 
 * mint sub-tokens that gives certain privaleges to both parties. Creator can use the setDistribution to specify the condition for minting
 * a distribution of the primary token. A distribution is defined by a Nft descriptor to the primary token, the validator contract 
 * that specifies the conditions to mint, the creator actions and the collector actions.
 * 
 * The Validtor interface resides in the IERCXXXXValidator.sol file. Each distribution requires certain conditions that must be fulfilled before
 * minting. The Validator contract is responsible for the storage as well as the validation of the conditions.
 * 
 * The Creator actions refers to the set of actions that the holder of the primary token can perform on the sub-tokens.
 * The Collector actions refers to the set of actions that the holder of the sub-tokens can perform.
 * 
 * A Collector can mint a sub-token of a Distribution given that the conditions specified by the Validator are fulfilled.
 *
 * Primary tokens holder can set multiple different distributions, each with different mint conditions, and a different set of actions that the token holder
 * will be empowered with after the minting of the token.
 */
interface IDistributor {

    /**
     * @dev Emitted when a distribution is created
     * 
     * @param distHash The hash of the distribution configuration
     * @param distribution The distribution that the distHash is generated from
     */
    event SetDistribution(bytes32 distHash, Distribution distribution);
    
    /**
     * @dev Emitted when a distribution is paused
     * 
     * @param distHash The hash of the distribution configuration
     */
    event PauseDistribution(bytes32 distHash);


    /**
     * The NFT Descritpor of the primary token
     */
    struct NFTDescriptor {
        address contractAddress;
        uint256 tokenId;
    }
    
    /**
     * @dev Distribution struct that specifies the input to the validation function
     *
     * @param NFTDescriptor The tokenId of the primary token
     */
    struct Distribution {
        NFTDescriptor descriptor;
        address validator;
        bytes4[] creatorActions;
        bytes4[] collectorActions;
    }

    /**
     * @dev The creator who holds a primary token can set a distribution that enables others
     * to mint copies given that they fulfil the given conditions
     *
     * @param distribution the basic states of the sub-token to be minted
     * @param initData the data to be input into the validator contract for setup the conditions
     * 
     * @return distHash Returns the hash of the distribution conifiguration 
     */
    function setDistribution(
        Distribution memory distribution,
        bytes calldata initData
    ) external returns (bytes32 distHash);
    
    /**
     * @dev The creator can pause the distribution
     *
     * @param distHash the hash of the distribution for minting
     */ 
    function pauseDistribution(
        bytes32 distHash
    ) external;

    /**
     * @dev The owner can unpause the distribution
     *
     * @param distHash the hash of the distribution
     *
     * @return descriptor the primary token
     */
    function primaryOf(bytes32 distHash) external view returns (NFTDescriptor memory descriptor);

}
