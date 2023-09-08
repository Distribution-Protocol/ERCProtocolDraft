---
eip: <to be assigned>
title: ERC721Copy
description: NFT Copy Creation under conditions specified by the creator
author: Henry Yeung (@henrywfyeung), Xiaoba <99x.capital@gmail.com>
discussions-to: <URL>
status: Draft
type: Standards Track
category (*only required for Standards Track): ERC
created: 2023-04-01
requires (*optional): 165, 721
---

## Abstract
This standard is an extension of [EIP-721](./eip-721.md). This standard enables any primary token, i.e. token from any EIP-721 compliant contracts, to work as an original that conditionally allows the production of sub-tokens with specific privileges attached.

The Creator, who holds the primary ERC721 token, can specify the conditions to mint a sub-token from a particular distribution of the primary token.

A distribution is defined as a version of sub-token that associates with the primary token. The holder of the sub-token under a distribution, gains the permission to invoke certain functions on the sub-token contract. Each primary token can be associated with multiple distributions, each with different conditions to obtain sub-tokens, and different level of privalleges attached.

The Collector, upon fulfilling the corresponding conditions from a specific distribution to obtain the sub-token, will be able to use the token within the boundaries set by the creator.

### Flow Diagram 

![alt text](./assets/Distribution.png?raw=true)



### Relation Diagram

![alt text](./assets/Relation.png?raw=true)

## Motivation
This standard solves the following problems.

- Copy Issuance of Unique Artwork/Content: Artists create unique artworks. There could be multiple collectors who want to keep a copy of their artworks. This standard serves as a tool to issue multiple copies of the same kind. The copies can be created with different functions and under different conditions. It gives sufficient flexibility to both the Creator and the Collector.
- Partial Copyright Transfer: This standard enables Creators to conditionally delegate the copyright, i.e. the right to produce derivative work, to the Collectors. There is no need to sell the original copy, i.e. creator token, in the market. The Creator can instead keep the token as proof of authorship, and the key to manage copy issurance.

This standard will serve a wide range of usecases, coupled with the followings:

- Decentralized storage facilities, such as Arweave, that enables permissionless, permanent and tamper-proof storage of content. The purchase of any copy NFT guarantees the owner the right to access such content.
- Decentralized Encrption Protocol, such as Lit Protocol, that enables the encryption of content specified by on-chain conditions. This enables selective reveal of content based on Copy NFT ownership and its expiry date.

People with the following use cases can consider applying this standard:
- Creator of any unique Art/Music NFTs can use this standard to sell copies to audiences. With this standard, they can retain some control over the copies.
- Artists can use this standard to sell time-limited copies of their artwork to other artists with a copyright statement that enables the production of derivative work
- Universities can create Graduation Certificates as NFTs and use this standard to mint a batch of non-transferable issues to their students. The Univerity retains the right to revoke any issued certificates.
- Novel writers can publish their content with the first chapter publicly viewable, and the following chapters encrypted with Lit Protocol. The readers will be required to purchase a Copy NFT to decrypt the encrypted chapters


## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

This standard consists of a Copy Contract and a Mintable Contract. They together enable copy creation from the Creator Contract.

### Deployment

- The Creator Contract MUST be [EIP-721](./eip-721.md) Compliant.
- The Creator Contract MUST implement the **metadata extension** specified in [EIP-721](./eip-721.md).
- The Creator Token Holder MUST process the copyright of the content that permits the issuing of the copy NFT.

### Usage

- The token holder of the Creator Contract MAY set the mintable rule in the Copy Contract to specify the condition of minting a particular copy.
- The mintable rule SHOULD call a particular implementation of Mintable Contract and set rules inside the Mintable Contract.
- The creator MAY specifies states of the copy, such as transferable, extendable, revokable, updateable, the copyright statement in the Contract.

- The Collector MUST fulfill the rules set by the Creator to obtain a copy.
- The Collector MAY exercise the rights specified by the Creator, such as transferable, extendable, revokable, updateable, and the copyright statement.
- The Collector SHOULD always reserve the right to destroy a copy.
- The Creator MAY revoke a copy if the state revokable of the copy is true.

## Rationale

This standard is designed to be as flexible as possible so that it can fulfill as much needs as possible. 

The Copy Contract permits the minting of tokens that process the following charateristics:
- non-transferable: An SBT that is bound to a user's wallet address
- revokable: creator has control over the minted copies. This is suitable for NFT that expresses follower relationship, or some kind of revokable permit
- extendable: NFT is valid over a duration and requires extension. This is suitable for recurring memberships.
- updateable: Allows the copy NFT holder to update the NFT content when the creator NFT is updated
- statement: Copyright transfer or other forms of declaration from the Creator.

The Mintable Contract can be customized to enforce conditions for Collectors, including:
- Fee: Requires payment to mint
- Free: No Condition to mint
- NFT Holder: Process a particular NFT to mint
- ERC20 Holder: Process a certain amount of ERC20 tokens to mint
- Whitelist: In the whitelist to mint.
- Limited Issuance: Fixed Maximum number of issued copies.
- Limited Time: Enables minting within a particular time frame.

## Backwards Compatibility
This standard is compatible with [EIP-721](./eip-721.md) and their extension.

## Test Cases
The full test case is given in  `../assets/eip-####/`.

## Reference Implementation

### The Distributor Interface

```
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
```

### The Validator Interface

```
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice This is the interface of the Validator Contract, the validator contract specifies the conditions that needs to be fulfilled, 
 * and enforce the fulfillment of these conditions. The Creator is required to first register these conditions onto a particular distribution, 
 * identified by the hash of the distribution configuration (distHash). 
 * When a collector wants to mint a copy of the distribution, or want to perform certain action that requires additional 
 * permission, the collector will need to pass the validation by successfully calling the validate function.  
 * 
 * In the validation process, the collector will need to supply the basic information including initiator (the address of the collector), 
 * distHash, and optional parameters, such as task and fullfilmentData.
 * task is required if the validation function implements validation processes on more than one task. For example, collectors need to fulfil one set of
 * validation conditions for minting a copy, and another set for extending the valid duration of the copy. The set up can be 
 * different depending on the usecases.
 * fulfulmentData is the additional data passed to the function
 */
interface IValidator {

    /**
     * @dev Sets up the validator conditions by the distribution hash and the data for initialisation. This function will
     * decode the data back to the required parameters and sets up the conditions that decides who
     * can or cannot mint a copy of the distribution. see {IValidator-MintInfo}
     *
     * @param distHash The hash of the copy configuration
     * @param initData The data bytes for initialising the validation conditions. Parameters are encoded into bytes
     */
    function setConditions(bytes32 distHash, bytes calldata initData) external;

    /**
     * @dev Supply the data that will be used to validate the fulfilment of the conditions setup by the creator.
     *
     * @param initiator the party who initiate vadiation on a particular task
     * @param distHash the hash of the copy configuration
     * @param task the task that a specific individual wants to validate. If there is only one task, the task can be empty
     * @param fullfilmentData the data that will be used to passed the validator conditions setup by the creator
     */
    function validate(address initiator, bytes32 distHash, bytes32 task, bytes calldata fullfilmentData) external payable;
}
```

The full implementation of the standard is given in the folder `../assets/eip-####/`.

## Security Considerations
The expiry timestamp computation depends on the block timestamp which may not accurately reflect the real-world time. Please refrain from setting an overly low duration for the NFT.

## Copyright
Copyright and related rights waived via [MIT](./LICENSE.md).
