// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import './interfaces/IERCXXXXDistributor.sol';
import './interfaces/IERCXXXXValidator.sol';

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256);
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

/**
 * @notice This contract is an implementation of the IValidator interface. It is used to enable mintable 
 * and extending a token with a fee charged. The creator will need to setup rules for copier/collector 
 * to follow before a copy token is minted / extended. 
 * 
 */
contract Validator is IValidator {

    /**
    * @dev the fee to be paid before minting / extending a copy token
    * 
    * @param feeToken The contract address of the fee token, i.e. USDT token contract address
    * @param mintAmount The token amount that is required for minting a copy token
    * @param duration The time duration that should add to the NFT token after mint
    */
    struct ValidationInfo {
        address feeToken;
        uint64 duration;
        uint256 mintAmount;
        address requiredERC721Token;
        uint256 limit;
        uint64  start;
        uint64  time;
    }


    event SetupRule(
        bytes32 ruleHash,
        ValidationInfo validationInfo
    );
    
    mapping(bytes32 => ValidationInfo) private _validationInfo;
    mapping(bytes32 => uint256) private _count;

    constructor () {}

    /// @inheritdoc IValidator
    function setRule(bytes32 ruleHash, bytes calldata ruleData) external override {
        (ValidationInfo memory valInfo) = abi.decode(ruleData, (ValidationInfo));

        // require(valInfo.start > uint64(block.timestamp), "Mintable: Invalid Start Time");
        _validationInfo[ruleHash] = valInfo;
        emit SetupRule(ruleHash, valInfo);
    }
    
    /// @inheritdoc IValidator
    function validate(address to, bytes32 ruleHash, bytes32 task, bytes calldata fullfilmentData) external payable override {
        _validateMint(to, ruleHash);
        ++_count[ruleHash];
    }
    
    // no reentrant**
    function _validateMint(
        address to,
        bytes32 ruleHash
    ) internal {
        ValidationInfo memory valInfo = _validationInfo[ruleHash];
        // check start time
        require(valInfo.start < uint64(block.timestamp), "Mintable: Minting Period Not Started");

        // check deadline (timestamp - start to prevent overflow)
        require(valInfo.time > uint64(block.timestamp) - valInfo.start, "Mintable: Minting Period Ended");

        // check limit
        require(valInfo.limit > _count[ruleHash], "Mintable: Minting Limit Reached");

        // check token binding
        if (valInfo.requiredERC721Token != address(0)) {
            require(IERC721(valInfo.requiredERC721Token).balanceOf(to) > 0, "Mintable: Required ERC721 Token has Zero Balance");
        }
        

        IDistributor.NFTDescriptor memory descriptor = IDistributor(msg.sender).creatorOf(ruleHash);
        address creatorAddress = IERC721(descriptor.contractAddress).ownerOf(descriptor.tokenId);

        // address(0) is the native token
        if (valInfo.feeToken == address(0)) {
            require(msg.value >= valInfo.mintAmount, "Mintable: Insufficient Native Tokens");
            payable(creatorAddress).transfer(valInfo.mintAmount);
        } else {
            IERC20(valInfo.feeToken).transferFrom(
                to,
                creatorAddress,
                valInfo.mintAmount
            );
        }
    }

    /**
    * @dev This function is called to get the validation rule for a copy token
    *
    * @param ruleHash the hash of the copy token
    * @return validationInfo the validation rule for the copy token
    */
    function getValidationInfo(
        bytes32 ruleHash
    ) external view returns (ValidationInfo memory) {
        return _validationInfo[ruleHash];
    }

    function getMintCount(
        bytes32 ruleHash
    ) external view returns (uint256) {
        return _count[ruleHash];
    }

}
