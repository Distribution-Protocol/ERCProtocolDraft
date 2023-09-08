// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice This is the interface of the Validator Contract, the validator contract specifies the rules that needs to be fulfilled, 
 * and enforce the fulfillment of these rules. The parent token holder is required to first register these rules onto a particular edition, 
 * identified by the hash of the edition configuration (distHash). 
 * When a collector wants to mint a copy of the edition, or want to perform certain action that requires additional 
 * permission, the collector will need to pass the validation by successfully calling the validate function.  
 * 
 * In the validation process, the collector will need to supply the basic information including initiator (the address of the collector), 
 * distHash, and optional parameters, such as task and fullfilmentData.
 * task is required if the validation function implements validation processes on more than one task. For example, collectors need to fulfil one set of
 * validation rules for minting a copy, and another set for extending the valid duration of the copy. The set up can be 
 * different depending on the usecases.
 * fulfulmentData is the additional data passed to the function
 */
interface IValidator {

    /**
     * @dev Sets up the validator rules by the edition hash and the data for initialisation. This function will
     * decode the data back to the required parameters and sets up the rules that decides who
     * can or cannot mint a copy of the edition. see {IValidator-MintInfo}
     *
     * @param distHash The hash of the copy configuration
     * @param initData The data bytes for initialising the validation rules. Parameters are encoded into bytes
     */
    function setRules(bytes32 distHash, bytes calldata initData) external;

    /**
     * @dev Supply the data that will be used to validate the fulfilment of the rules setup by the parent token holder.
     *
     * @param initiator the party who initiate vadiation on a particular task
     * @param distHash the hash of the copy configuration
     * @param task the task that a specific individual wants to validate. If there is only one task, the task can be empty
     * @param fullfilmentData the data that will be used to passed the validator rules setup by the parent token holder
     */
    function validate(address initiator, bytes32 distHash, bytes32 task, bytes calldata fullfilmentData) external payable;

}
