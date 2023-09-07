// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice This is the interface of the Validator Contract, the validator contract specifies the rule for minting copies. 
 * Contracts that inherit the IValidator Interface can define their own rules. The creator will first specifies rules 
 * using the setupRule function. Then, the collector can mint a copy with the isValidator function, or subsequently extend
 * the validity of the copy with the isExtendable function.
 */
interface IValidator {

    /**
     * @dev Sets up the validator rule by the creator NFT's tokenId and the ruleData. This function will
     * decode the ruleData back to the required parameters and sets up the rule that decides who
     * can or cannot mint a copy of the creator's NFT content, with the corresponding parameters, such as
     * transferable, updatable etc. see {IValidator-MintInfo}
     *
     * @param ruleHash The hash of the copy configuration
     * @param ruleInitData The data bytes for initialising the validationRule. Parameters are encoded into bytes
     */
    function setRule(bytes32 ruleHash, bytes calldata ruleInitData) external;

    /**
     * @dev Supply the data that will be used to passed the validator rule setup by the creator. Different
     * rule has different requirement
     *
     * @param to the address that the NFT will be minted to
     * @param ruleHash the hash of the copy configuration
     * @param task the task that a specific individual wants to validate
     * @param fullfilmentData the data that will be used to passed the validator rule setup by the creator
     */
    function validate(address to, bytes32 ruleHash, bytes32 task, bytes calldata fullfilmentData) external payable;

}
