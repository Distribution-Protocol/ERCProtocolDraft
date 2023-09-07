// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


/**
 * @notice The Interface of the Contract that supports ERCXXXX. Creator can use the setDistributionRule to specify the condition for minting
 * the copy. Depending on the distribution rules, collector can copy, then update, transfer, extend or destroy the copy. Creator 
 * can revoke the copy if allowed in distribution rules. This interface is intended to be used for single creator NFT contract. 
 * It can be easily extended to accept request from multiple create NFT contracts.
 * 
 * The MintInfo encapulates the information of the copy NFT, including all the permissions granted to it. This information can be 
 * stored on chain as a MintInfo struct, or simple a hashed version of it to save gas. It comes with a fixed set of basic info, such 
 * as isTransferable, isExtendable, etc, and a bytes field for defining custom additional permissions.
 * 
 * DistributionRules are external contract that is responsible for the defintion and enforcement of rules, that should be fulfilled before 
 * minting a copy NFT
 * 
 * Creator chooses the DistributionRules that associate with the corresponding MintInfos.
 * Copier fulfils the DistributionRule to obtain a copy and enjoy the benefits brought by the MintInfo.
 */
interface IDistributor {

    /**
     * @dev Emitted when a distribution rule is created
     * 
     * @param ruleHash The hash of the copy configuration
     * @param ruleInfo The distribution rule that the copyHash is generated from
     */
    event SetDistributionRule(bytes32 ruleHash, RuleInfo ruleInfo);
    
    /**
     * @dev Emitted when a distribution rule is paused
     * 
     * @param copyHash The hash of the copy configuration
     */
    event PauseDistributionRule(bytes32 copyHash);


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
    struct RuleInfo {
        NFTDescriptor descriptor;
        address validator;
        bytes4[] creatorActions;
        bytes4[] collectorActions;
    }

    /**
     * @dev The creator who holds a creator token can set a distribution rule that enables others
     * to mint copies given that they fulfil the conditions specified by the rule
     *
     * @param ruleInfo the basic states of the copy to be minted
     * @param ruleInitData the data to be input into the validator address for setup rules
     * 
     * @return ruleHash Returns the hash of the rule conifiguration 
     */
    function setDistributionRule(
        RuleInfo memory ruleInfo,
        bytes calldata ruleInitData
    ) external returns (bytes32 ruleHash);
    
    /**
     * @dev The creator can pause the distribution rule
     *
     * @param ruleHash the hash of the copy configuration for minting
     */ 
    function pauseDistributionRule(
        bytes32 ruleHash
    ) external;

    /**
     * @dev The creator can unpause the distribution rule
     *
     * @param ruleHash the hash of the rule
     *
     * @return descriptor the creator token
     */
    function creatorOf(bytes32 ruleHash) external view returns (NFTDescriptor memory descriptor);

}
