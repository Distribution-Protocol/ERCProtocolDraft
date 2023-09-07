// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


/**
 * @notice The Interface of the Contract that supports ERCXXXX. Creator can use the setDistributionRule to specify the condition for minting
 * a distribution of the Creation NFT. A distribution is defined by its origin (Creation NFT), the validator contract that specifies the conditions
 * to mint, the creator actions and the collector actions.
 * 
 * The Validtor interface resides in the IERCXXXXValidator.sol file. Each distribution requires certain conditions that must be fulfilled before
 * minting. The Validator contract is responsible for the storage as well as the validation of the conditions.
 * 
 * The Creator actions refers to the set of actions that the holder of the creation NFT can perform on the copy NFT.
 * The Collector actions refers to the set of actions that the holder of the copy NFT can perform.
 * 
 * A Collector can mint a copy of a Distribution given that the conditions specified by the Validator are fulfilled.
 *
 * Creation NFT tokens holder can set multiple different distributions, each with different mint conditions, and a different set of actions that the token holder
 * will be empowered with after the minting of the token.
 */
interface IDistributor {

    /**
     * @dev Emitted when a distribution rule is created
     * 
     * @param distHash The hash of the distribution configuration
     * @param distribution The distribution that the distHash is generated from
     */
    event SetDistribution(bytes32 distHash, Distribution distribution);
    
    /**
     * @dev Emitted when a distribution rule is paused
     * 
     * @param distHash The hash of the copy configuration
     */
    event PauseDistribution(bytes32 distHash);


    /**
     * The NFT Descritpor of the creator NFT that produces the original content
     */
    struct NFTDescriptor {
        address contractAddress;
        uint256 tokenId;
    }
    
    /**
     * @dev RuleInfo struct that specifies the input to the validation function
     *
     * @param NFTDescriptor The tokenId of the creator NFT that produces the original content
     */
    struct Distribution {
        NFTDescriptor descriptor;
        address validator;
        bytes4[] creatorActions;
        bytes4[] collectorActions;
    }

    /**
     * @dev The creator who holds a creator token can set a distribution rule that enables others
     * to mint copies given that they fulfil the conditions specified by the rule
     *
     * @param distribution the basic states of the copy to be minted
     * @param initData the data to be input into the validator address for setup rules
     * 
     * @return distHash Returns the hash of the rule conifiguration 
     */
    function setDistribution(
        Distribution memory distribution,
        bytes calldata initData
    ) external returns (bytes32 distHash);
    
    /**
     * @dev The creator can pause the distribution rule
     *
     * @param distHash the hash of the copy configuration for minting
     */ 
    function pauseDistribution(
        bytes32 distHash
    ) external;

    /**
     * @dev The creator can unpause the distribution rule
     *
     * @param distHash the hash of the rule
     *
     * @return descriptor the creator token
     */
    function creatorOf(bytes32 distHash) external view returns (NFTDescriptor memory descriptor);

}
