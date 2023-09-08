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
 * and extending a token with a fee charged. The primary token holder will need to setup rules for collector 
 * to follow before a copy token is minted. 
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


    event SetRules(
        bytes32 distHash,
        ValidationInfo validationInfo
    );
    
    mapping(bytes32 => ValidationInfo) private _validationInfo;
    mapping(bytes32 => uint256) private _count;

    constructor () {}

    /// @inheritdoc IValidator
    function setRules(bytes32 distHash, bytes calldata initData) external override {
        (ValidationInfo memory valInfo) = abi.decode(initData, (ValidationInfo));

        // require(valInfo.start > uint64(block.timestamp), "Validator: Invalid Start Time");
        _validationInfo[distHash] = valInfo;
        emit SetRules(distHash, valInfo);
    }
    
    /// @inheritdoc IValidator
    function validate(address to, bytes32 distHash, bytes32 task, bytes calldata fullfilmentData) external payable override {
        _validateMint(to, distHash);
        ++_count[distHash];
    }
    
    // no reentrant**
    function _validateMint(
        address to,
        bytes32 distHash
    ) internal {
        ValidationInfo memory valInfo = _validationInfo[distHash];
        // check start time
        require(valInfo.start < uint64(block.timestamp), "Validator: Minting Period Not Started");

        // check deadline (timestamp - start to prevent overflow)
        require(valInfo.time > uint64(block.timestamp) - valInfo.start, "Validator: Minting Period Ended");

        // check limit
        require(valInfo.limit > _count[distHash], "Validator: Minting Limit Reached");

        // check token binding
        if (valInfo.requiredERC721Token != address(0)) {
            require(IERC721(valInfo.requiredERC721Token).balanceOf(to) > 0, "Validator: Required ERC721 Token has Zero Balance");
        }
        
        
        IDistributor.NFTDescriptor memory descriptor = IDistributor(msg.sender).parentOf(distHash);
        address primaryHolder = IERC721(descriptor.contractAddress).ownerOf(descriptor.tokenId);

        // address(0) is the native token
        if (valInfo.feeToken == address(0)) {
            require(msg.value >= valInfo.mintAmount, "Validator: Insufficient Native Tokens");
            payable(primaryHolder).transfer(valInfo.mintAmount);
        } else {
            IERC20(valInfo.feeToken).transferFrom(
                to,
                primaryHolder,
                valInfo.mintAmount
            );
        }
    }

    /**
    * @dev This function is called to get the validation rules for a copy token
    *
    * @param distHash the hash of the copy token
    * @return validationInfo the validation rules for the copy token
    */
    function getValidationInfo(
        bytes32 distHash
    ) external view returns (ValidationInfo memory) {
        return _validationInfo[distHash];
    }

    function getMintCount(
        bytes32 distHash
    ) external view returns (uint256) {
        return _count[distHash];
    }

}
