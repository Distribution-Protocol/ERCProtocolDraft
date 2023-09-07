// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import './interfaces/IERCXXXXDistributor.sol';
import './interfaces/IERCXXXXValidator.sol';

import 'hardhat/console.sol';

/**
 * @notice This is an implementation of the ICopy interface.
 */
contract Distributor is ERC721Enumerable, IDistributor {
    using Strings for uint256;
    
    /**
     * @dev Struct containing the information of the minted copy NFT
     *
     * @param copyURI Shows the contentUri copied from the creator token for collection purposes
     * the copy NFT owner will get, for instance, the right to create derivative work based on the creator NFT content
     */
    struct CopyInfo {
        string copyURI;
        bytes32 ruleHash;
    }

    enum State {
        NIL,
        EXIST,
        PAUSED
    }

    // collector actions
    bytes4 private constant _TRANSFER = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 private constant _UPDATE = bytes4(keccak256(bytes('update(uint256)')));
    // creator actions
    bytes4 private constant _REVOKE = bytes4(keccak256(bytes('revoke(uint256)')));

    // mapping for tokenId generation address => creatorAddress => creatorId => tokenId
    mapping(address=>mapping(address=>mapping(uint256=>uint256))) private _tokenCounter;
    
    // creatorId => index => tokenId
    mapping(address=> mapping(uint256 => mapping(uint256 => uint256))) private _copys;
    // creatorId => copy_count
    mapping(address=> mapping(uint256 => uint256)) private _copyCount;

    // tokenId => CopyInfo
    mapping(uint256 => CopyInfo) private _copyInfo;
    // tokenId => index
    mapping(uint256 => uint256) private _copyIndex;

    // creatorId => copyRules (For Record Keeping, mint info cannot be deleted once set)
    mapping(address=>mapping(uint256 => bytes32[])) _ruleHashes;

    // rule Items
    mapping(bytes32 => NFTDescriptor) private _creator;
    mapping(bytes32 => address) private _validator;
    mapping(bytes32 => mapping(bytes4 => bool)) private _creatorActions;
    mapping(bytes32 => mapping(bytes4 => bool)) private _collectorActions;
    
    mapping(bytes32 => State) private _states;

    constructor (
        string memory name_, 
        string memory symbol_
    ) ERC721(name_, symbol_) {}
    
    /// @inheritdoc IDistributor
    function setDistributionRule(
        RuleInfo memory ruleInfo,
        bytes calldata ruleInitData
    ) external virtual override returns (bytes32) {
        require(
            _isApprovedOrCreator(_msgSender(), ruleInfo.descriptor),
            'Copy: caller is not creator nor approved'
        );
        bytes32 ruleHash = _getHash(ruleInfo);
        
        if ( _states[ruleHash] == State.NIL ) {
            _ruleHashes[ruleInfo.descriptor.contractAddress][ruleInfo.descriptor.tokenId].push(ruleHash);
            _creator[ruleHash] = ruleInfo.descriptor;
            _validator[ruleHash] = ruleInfo.validator;
            for (uint256 i = 0; i < ruleInfo.creatorActions.length; i++) {
                _creatorActions[ruleHash][ruleInfo.creatorActions[i]] = true;
            }
            for (uint256 i = 0; i < ruleInfo.collectorActions.length; i++) {
                _collectorActions[ruleHash][ruleInfo.collectorActions[i]] = true;
            }
        }

        _states[ruleHash] = State.EXIST;
                
        IValidator(ruleInfo.validator).setRule(ruleHash, ruleInitData);
                
        emit SetDistributionRule(ruleHash, ruleInfo);
        return ruleHash;
    }

    /// @inheritdoc IDistributor
    function pauseDistributionRule(
        bytes32 ruleHash
    ) external virtual override {
        require(
            _isApprovedOrCreator(_msgSender(), _creator[ruleHash]),
            'Copy: caller is not creator nor approved'
        );
        _states[ruleHash] = State.PAUSED; // disable copying
        emit PauseDistributionRule(ruleHash);
    }
    
    function create(address to, bytes32 ruleHash) external virtual payable returns (uint256) {
        require(_states[ruleHash] == State.EXIST, 'Copy: Copying Disabled');
        IValidator(_validator[ruleHash]).validate{value: msg.value}(to, ruleHash, bytes32(0), bytes(''));
        
        uint256 tokenId = _mintToken(to, _creator[ruleHash]);
        _register(tokenId, ruleHash);

        return tokenId;
    }
    
    function revoke(uint256 tokenId) external virtual  {
        require(isPermittedCreator(tokenId, _REVOKE), 'Copy: Non-revokable');
        require(
            _isApprovedOrCreator(_msgSender(), creatorOf(tokenId)),
            'Copy: caller is not creator nor approved'
        );
        _deregisterAndBurn(tokenId);
    }

    function destroy(uint256 tokenId) external virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: caller is not token owner nor approved'
        );
        _deregisterAndBurn(tokenId);
    }

    function update(uint256 tokenId) external virtual returns (string memory) {
        require(isPermittedCollector(tokenId, _UPDATE), 'Copy: Non-updatable');
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: caller is not token owner nor approved'
        );
        _copyInfo[tokenId].copyURI = _fetchURIForCopy(creatorOf(tokenId));
        return _copyInfo[tokenId].copyURI;
    }

    /**
     * @dev Register the information of a newly minted token Id.
     *
     * @param tokenId The copy NFT token Id
     * @param ruleHash The hash of the copy configuration
     */
    function _register(
        uint256 tokenId,
        bytes32 ruleHash
    ) internal {
        NFTDescriptor memory descriptor = _creator[ruleHash];
        uint256 copyCount = ++_copyCount[descriptor.contractAddress][descriptor.tokenId];
        _copys[descriptor.contractAddress][descriptor.tokenId][copyCount] = tokenId;
        _copyIndex[tokenId] = copyCount;

        _copyInfo[tokenId].copyURI = _fetchURIForCopy(descriptor);
        _copyInfo[tokenId].ruleHash = ruleHash;
    }

    /**
     * @dev Remove the copy NFT token from the mappings. And clear the memory of the copy NFT token information
     *
     * @param tokenId The copy NFT token Id
     */
    function _deregister(uint256 tokenId) internal virtual {
        NFTDescriptor memory descriptor = creatorOf(tokenId);
        uint256 copyIndex = _copyIndex[tokenId];
        uint256 lastCopyIndex = _copyCount[descriptor.contractAddress][descriptor.tokenId]--;
        if (copyIndex < lastCopyIndex) {
            _copys[descriptor.contractAddress][descriptor.tokenId][copyIndex] = _copys[descriptor.contractAddress][descriptor.tokenId][lastCopyIndex];
            _copyIndex[_copys[descriptor.contractAddress][descriptor.tokenId][lastCopyIndex]] = copyIndex;
        }
        delete _copys[descriptor.contractAddress][descriptor.tokenId][lastCopyIndex];
        delete _copyIndex[tokenId];
        delete _copyInfo[tokenId];
    }

    /**
     * @notice Deregister, clear up information related to a copy NFT and burn the NFT
     *
     * @param tokenId The copy NFT token Id
     *
     */
    function _deregisterAndBurn(uint256 tokenId) internal virtual {
        _deregister(tokenId);
        _burn(tokenId);
    }

    /**
     * @notice SafeMint a new copy NFT token
     *
     * @param to The address to mint the NFT token tos
     * @param descriptor The creator NFT 
     *
     * @return uint256 Returns the newly minted token Id
     */
    function _mintToken(address to, NFTDescriptor memory descriptor) internal returns (uint256) {
        uint256 tokenId = ++_tokenCounter[to][descriptor.contractAddress][descriptor.tokenId];
        _safeMint(to, tokenId);
        return tokenId;
    }

    /**
     * @notice Fetch the token URI from the creator token, using the {IERC721Metadata-tokenURI} method
     * This function can be overriden to fetch contentUri from other functions
     *
     * @param descriptor The creator NFT token
     *
     * @return string Returns the token URI of the creator token
     */
    function _fetchURIForCopy(NFTDescriptor memory descriptor) internal view virtual returns (string memory) {
        return IERC721Metadata(descriptor.contractAddress).tokenURI(descriptor.tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (address(0) != from && address(0) != to) {
            // disable transfer if the token is not transferable. It does not apply to mint/burn action
            require(isPermittedCollector(tokenId, _TRANSFER), 'Copy: Non-transferable');
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _isApprovedOrCreator(address spender, NFTDescriptor memory descriptor)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = IERC721(descriptor.contractAddress).ownerOf(descriptor.tokenId);
        return
            owner == spender ||
            IERC721(descriptor.contractAddress).getApproved(descriptor.tokenId) == spender ||
            IERC721(descriptor.contractAddress).isApprovedForAll(owner, spender);
    }

    function _getHash(
        RuleInfo memory ruleInfo
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ruleInfo.descriptor.contractAddress,
                    ruleInfo.descriptor.tokenId,
                    ruleInfo.creatorActions,
                    ruleInfo.collectorActions,
                    ruleInfo.validator
                )
            );
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == type(IDistributor).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return _copyInfo[tokenId].copyURI;
    }

    function getCopyCount(NFTDescriptor memory descriptor) external view virtual returns (uint256) {
        return _copyCount[descriptor.contractAddress][descriptor.tokenId];
    }

    function getCopyByIndex(NFTDescriptor memory descriptor, uint256 index)
        external
        view
        virtual
        returns (uint256)
    {
        require(index <= _copyCount[descriptor.contractAddress][descriptor.tokenId], 'Copy: Index Out Of Bounds');
        return _copys[descriptor.contractAddress][descriptor.tokenId][index];
    }

    function getCopyInfo(uint256 tokenId) external view returns (CopyInfo memory) {
        return _copyInfo[tokenId];
    }

    function isPermittedCollector(uint256 tokenId, bytes4 func) view public returns (bool) {
        return _collectorActions[_copyInfo[tokenId].ruleHash][func];
    }

    function isPermittedCreator(uint256 tokenId, bytes4 func) view public returns (bool) {
        return _collectorActions[_copyInfo[tokenId].ruleHash][func];
    }

    function creatorOf(uint256 tokenId) public view virtual returns (NFTDescriptor memory) {
        return _creator[_copyInfo[tokenId].ruleHash];
    }

    function creatorOf(bytes32 ruleHash) public view virtual returns (NFTDescriptor memory) {
        return _creator[ruleHash];
    }

    function getValidationRule(uint256 tokenId) external view virtual returns (address) {
        return _validator[_copyInfo[tokenId].ruleHash];
    }
    
    function getRuleHashes(NFTDescriptor memory descriptor) external view virtual returns (bytes32[] memory) {
        return _ruleHashes[descriptor.contractAddress][descriptor.tokenId];
    }

    function hasValidCopy(address collector, NFTDescriptor memory descriptor) external view virtual returns (bool) {
        uint256 count = balanceOf(collector);
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(collector, i);
            NFTDescriptor memory creatorDescriptor = creatorOf(tokenId);
            if ( creatorDescriptor.tokenId == descriptor.tokenId && creatorDescriptor.contractAddress == descriptor.contractAddress) {
                return true;
            }
        }
        return false;
    }

    function getCopyHashes(NFTDescriptor memory descriptor) external view returns (bytes32[] memory){
        return _ruleHashes[descriptor.contractAddress][descriptor.tokenId];
    }

}
