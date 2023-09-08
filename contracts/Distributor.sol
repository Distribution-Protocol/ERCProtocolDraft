// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import './interfaces/IERCXXXXDistributor.sol';
import './interfaces/IERCXXXXValidator.sol';

import 'hardhat/console.sol';

/**
 * @notice This is an implementation of the IDistributor interface.
 */
contract Distributor is ERC721Enumerable, IDistributor {
    using Strings for uint256;

    // the state of the distribution
    enum State { 
        NIL,     // distribution not exists
        PAUSED,  // distribution paused
        ACTIVE   // distribution active
    }

    // collector actions
    bytes4 private constant _TRANSFER = 0x23b872dd; // function signiture of 'transferFrom(address,address,uint256)'
    bytes4 private constant _UPDATE = 0x82ab890a; // function signiture of 'update(uint256)'
    // distributor actions
    bytes4 private constant _REVOKE = 0x20c5429b; // function signiture of 'revoke(uint256)'
    
    uint256 private _tokenCounter;

    // tokenId => distHash
    mapping(uint256 => bytes32) private _distHash;
    mapping(uint256 => string) private _tokenURI;

    // nft descriptor => distribution (For Record Keeping, distributions cannot be deleted once set)
    mapping(address=>mapping(uint256 => bytes32[])) _distHashes;

    // distribution fields
    mapping(bytes32 => NFTDescriptor) private _primary;
    mapping(bytes32 => address) private _validator;
    mapping(bytes32 => mapping(bytes4 => bool)) private _primaryTokenActions;
    mapping(bytes32 => mapping(bytes4 => bool)) private _subTokenActions;
    
    // distributions state
    mapping(bytes32 => State) private _states;

    constructor (
        string memory name_, 
        string memory symbol_
    ) ERC721(name_, symbol_) {}
    
    modifier onlyCreator(NFTDescriptor memory descriptor) {
        require(
            _isApprovedOrCreator(_msgSender(), descriptor),
            'Distributor: caller is not creator nor approved'
        );
        _;
    }

    /// @inheritdoc IDistributor
    function setDistribution(
        Distribution memory distribution,
        bytes calldata initData
    ) external virtual override onlyCreator(distribution.descriptor) returns (bytes32) {
        bytes32 distHash = _getHash(distribution);
        
        // distributions are only initiated if not already exists. For distributions in paused state, the distribution will change to active
        if ( _states[distHash] == State.NIL ) {
            _storeDistribution(distribution, distHash);
            IValidator(distribution.validator).setConditions(distHash, initData);
        }
        _states[distHash] = State.ACTIVE;
        
        emit SetDistribution(distHash, distribution);
        return distHash;
    }

    function _storeDistribution(
        Distribution memory distribution,
        bytes32 distHash
    ) internal {
        _distHashes[distribution.descriptor.contractAddress][distribution.descriptor.tokenId].push(distHash);
        _primary[distHash] = distribution.descriptor;
        _validator[distHash] = distribution.validator;
        for (uint256 i = 0; i < distribution.creatorActions.length; i++) {
            _primaryTokenActions[distHash][distribution.creatorActions[i]] = true;
        }
        for (uint256 i = 0; i < distribution.collectorActions.length; i++) {
            _subTokenActions[distHash][distribution.collectorActions[i]] = true;
        }
    }

    /// @inheritdoc IDistributor
    function pauseDistribution(
        bytes32 distHash
    ) external virtual override onlyCreator(_primary[distHash]) {
        _states[distHash] = State.PAUSED; // disable minting
        emit PauseDistribution(distHash);
    }
    
    // validate condition fulfilment and mint
    function mint(address to, bytes32 distHash) external virtual payable returns (uint256) {
        require(_states[distHash] == State.ACTIVE, 'Distributor: Minting Disabled');
        IValidator(_validator[distHash]).validate{value: msg.value}(to, distHash, bytes32(0), bytes(''));
        
        uint256 tokenId = _mintToken(to);
        NFTDescriptor memory descriptor = _primary[distHash];
        _tokenURI[tokenId] = _fetchURIFromPrimary(descriptor);
        _distHash[tokenId] = distHash;
        
        return tokenId;
    }
    
    function revoke(uint256 tokenId) external virtual onlyCreator(primaryOf(tokenId)) {
        require(isPermittedCreator(tokenId, _REVOKE), 'Distributor: Non-revokable');
        delete _tokenURI[tokenId];
        delete _distHash[tokenId];
        _burn(tokenId);
    }

    function destroy(uint256 tokenId) external virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: caller is not token owner nor approved'
        );
        delete _tokenURI[tokenId];
        delete _distHash[tokenId];
        _burn(tokenId);
    }

    function update(uint256 tokenId) external virtual returns (string memory) {
        require(isPermittedCollector(tokenId, _UPDATE), 'Distributor: Non-updatable');
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: caller is not token owner nor approved'
        );
        _tokenURI[tokenId] = _fetchURIFromPrimary(primaryOf(tokenId));
        return _tokenURI[tokenId];
    }

    function _mintToken(address to) internal returns (uint256) {
        uint256 tokenId = ++_tokenCounter;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function _fetchURIFromPrimary(NFTDescriptor memory descriptor) internal view virtual returns (string memory) {
        return IERC721Metadata(descriptor.contractAddress).tokenURI(descriptor.tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (address(0) != from && address(0) != to) {
            // disable transfer if the token is not transferable. It does not apply to mint/burn action
            require(isPermittedCollector(tokenId, _TRANSFER), 'Distributor: Non-transferable');
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
        Distribution memory distribution
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    distribution.descriptor.contractAddress,
                    distribution.descriptor.tokenId,
                    distribution.creatorActions,
                    distribution.collectorActions,
                    distribution.validator
                )
            );
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return _tokenURI[tokenId];
    }

    function isPermittedCollector(uint256 tokenId, bytes4 func) view public returns (bool) {
        return _subTokenActions[_distHash[tokenId]][func];
    }

    function isPermittedCreator(uint256 tokenId, bytes4 func) view public returns (bool) {
        return _subTokenActions[_distHash[tokenId]][func];
    }

    function primaryOf(uint256 tokenId) public view virtual returns (NFTDescriptor memory) {
        return _primary[_distHash[tokenId]];
    }

    function primaryOf(bytes32 distHash) public view virtual returns (NFTDescriptor memory) {
        return _primary[distHash];
    }

    function getValidationCondition(uint256 tokenId) external view virtual returns (address) {
        return _validator[_distHash[tokenId]];
    }
    
    function getDistHashes(NFTDescriptor memory descriptor) external view virtual returns (bytes32[] memory) {
        return _distHashes[descriptor.contractAddress][descriptor.tokenId];
    }

}
