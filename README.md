---
eip: <to be assigned>
title: Multi-Tier Dependant NFTs
description: A specification on the distribution of multiple editions of child NFTs with abitrary rules and privileges.
author: Henry Yeung (henrywfyeung@gmail.com), Xiaoba <99x.capital@gmail.com>
discussions-to: <URL>
status: Draft
type: Standards Track
category (*only required for Standards Track): ERC
created: 2023-09-01
requires (*optional): 165, 721
---

## Abstract
This standard is an extension of [EIP-721](./eip-721.md), which enables any EIP-721 compliant tokens, to conditionally permit the minting of various editions of child tokens with specific privileges attached.

Edition is defined as a version of child token that encapsulates a descriptor to the parent, the address to a validator that validates rules before minting the child token, and a set of actions that can be invoked upon obtaining the child token.

Each parent token can create multiple editions, each with different set of rules to obtain the child tokens, and with different level of privalleges attached.

Upon fulfilling the corresponding rules from a specific editions, one can obtain the child token and will be able to use the token within the boundaries set by the parent token holder.

![alt text](./assets/ERCXXXX.png?raw=true)

## Motivation

Most community based relationships can be regarded as a structure with a community owner, and multiple tiers of community members. Each tier has its own cost and benefit of joining. This can apply to Profile-Follower relationship, Domain-Subdomain relationship, Creation-Collection relationship, Producer-Subscriber relationship, Dao-Member relationship, etc.

This standard gives the interfaces for implementing such tiered system. It empowers any ERC721 tokens with the ability to create editions of child tokens that give privileges at a cost.

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

This standard consists of a Distributor Interface and a Validator Interface. The Distributor interface MUST be implemented by a [EIP-721](./eip-721.md) compliant contract that enables minting of child tokens. This contract SHOULD enable any EIP-721 compliant parent token to create editions. The editions SHOULD consist of an address to a contract that implements the Validator Interface, which helps to validate the rules to mint the child token. A EIP-721 compliant contract MAY implements both the Distributor Interface and the Validator Interface, or implement only the Distributor Interface and uses external contracts that implements the Validator Interface.

### The Distributor Interface

```
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
```

### The Validator Interface

```
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice This is the validator interface. It specifies the rules that needs to be fulfilled, and enforce the
 * fulfillment of these rules. The parent token holder is required to first register these rules onto a particular
 * edition, identified by the hash of the edition configuration (editionHash). When a collector wants to mint from
 * the edition, the collector will need to pass the validation by successfully calling the validate function.  
 * 
 * In the validation process, the collector will need to supply the basic information including initiator
 * (the address of the collector), editionHash, and some optional fullfilmentData.
 */
interface IValidator {

    /**
     * @dev Sets up the validator rules by the edition hash and the data for initialisation. This function will
     * decode the data back to the required parameters and sets up the rules that decides who can or cannot
     * mint a copy of the edition.
     *
     * @param editionHash The hash of the edition configuration
     * @param initData The data bytes for initialising the validation rules. Parameters are encoded into bytes
     */
    function setRules(
        bytes32 editionHash, 
        bytes calldata initData
    ) external;

    /**
     * @dev Supply the data that will be used to validate the fulfilment of the rules setup by the parent token holder.
     *
     * @param initiator the party who initiate vadiation
     * @param editionHash the hash of the edition configuration
     * @param fullfilmentData the addtion data that is required for passing the validator rules
     */
    function validate(
        address initiator, 
        bytes32 editionHash,
        bytes calldata fullfilmentData
    ) external payable;

}
```

### Usage

Any ERC721 token can use the Distributor Interface to create multiple editions, each with a different set of rules to be validated by the Validator Interface before obtaining a child token, and the set of actions that can be invoked after obtaining the child token. This is very useful in community building, and has a diverse range of use-cases, for instance:

- Copy Issuance of Unique Artwork/Content: Artists create unique artworks. There could be multiple collectors who want to keep a copy of their artworks. This standard serves as a tool to issue multiple copies of the same kind. The copies can be created with different functions and under different rules. It gives sufficient flexibility to both the Creator and the Collector.
- Partial Copyright Transfer: This standard enables Creators to conditionally delegate different level of copyrights, i.e. the right to produce derivative work, to the Collectors. There is no need to sell the original copy, i.e. creator token, in the market. The Creator can instead keep the token as proof of authorship, and the key to manage copy issurance.

People with the following use cases can consider applying this standard:
- Creator of any unique Art/Music NFTs can use this standard to sell copies to audiences. With this standard, they can retain some control over the copies.
- Artists can use this standard to sell time-limited copies of their artwork to other artists with a copyright statement that enables the production of derivative work
- Universities can create Graduation Certificates as NFTs and use this standard to mint a batch of non-transferable issues to their students. The Univerity retains the right to revoke any issued certificates, through action.
- Web3 Domain Name holder can use this protocol to create different tiers of followers, each tier has
a different cost to obtain. Higher tier followers will be able to invoke more functions.

## Rationale

### Community Management with a Single Parent Token or a Selected Edition of Child Tokens

The default setup enables the parent token to get the permission to manage the setup of editions and the corresponding validation rules. A potentially advanced setup could lock the parent token into the distributor contract, and delegate the management role to a particular edition of child tokens.

### The Main Contract that Implements the Distributor Interface for Edition Creation

The main contract ...

### Flexible Implementation of Actions

The actions that can be performed is defined in the edition with a uint96 integer. Each bit in the integer determines whehter a particular action/function can be invoked in the contract, with a maximum of 96 actions. The actions can be implemented flexibly depending on the specific use-cases. For instance, if the parent token wants to have full control over the child token, the edition can permit the parent token holder to invocate a function that transfers the child token to the parent token holder.

Actions can give the child tokens the following characteristics:
- non-transferable: An SBT that is bound to a user's wallet address
- revokable: creator has control over the minted copies. This is suitable for NFTs that encapsulate follower relationship, or funtions as some kind of revokable permits
- extendable: NFT is valid over a duration and requires extension. This is suitable for recurring memberships.
- updateable: Allows the child token holder to update the tokenUri when the parent token is updated

### External or Internal Implementation of the Validator Interface 

The Validator Interface can be implemented externally as an independent contract, or internally as part of the contract that issues the child token. The former approach is more composable, i.e., a set of common implementation could be shared by a group of projects. The latter one is less composable, but more secured, as it does not depend on third party code. 

### Flexible Implementation of Validation Rules

The Validator Contract can be customized to enforce rules, including:
- Fee: Requires payment to mint
- Free: No Condition to mint
- NFT Holder: Process a particular NFT to mint
- ERC20 Holder: Process a certain amount of ERC20 tokens to mint
- Whitelist: In the whitelist to mint.
- Limited Issuance: Fixed Maximum number of issued copies.
- Limited Time: Enables minting within a particular time frame.


## Backwards Compatibility
This standard is compatible with [EIP-721](./eip-721.md).

## Reference Implementation

Reference implementation given in  `../assets/eip-####/`.

## Security Considerations
The current design permits the use of external validator which may not implements secure logic and may potentially be malicious. The distributor contract could whitelist a subset of trusted validators. Moreover, a ERC721 contract may at the same time implements both the distributor and the validator interfaces.

## Copyright
Copyright and related rights waived via [CC0 1.0](./LICENSE.md).
