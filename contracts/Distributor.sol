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

    // the state of the edition
    enum State { 
        NIL,     // edition not exists
        PAUSED,  // edition paused
        ACTIVE   // edition active
    }

    uint96 private constant _TRANSFER = 1<<0;  // child action
    uint96 private constant _UPDATE = 1<<1;    // child action
    uint96 private constant _REVOKE = 1<<2;    // parent action
    
    uint256 private _tokenCounter;

    // tokenId => editionHash
    mapping(uint256 => bytes32) private _editionHash;
    mapping(uint256 => string) private _tokenURI;

    // nft descriptor => edition (For Record Keeping, editions cannot be deleted once set)
    mapping(address=>mapping(uint256 => bytes32[])) _editionHashes;

    // edition fields
    mapping(bytes32 => Edition) private _edition;
    // mapping(bytes32 => address) private _validator;
    // mapping(bytes32 => uint96) private _actions;
    
    // editions state
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
    function setEdition(
        Edition memory edition,
        bytes calldata initData
    ) external virtual override onlyCreator(edition.descriptor) returns (bytes32) {
        bytes32 editionHash = _getHash(edition);
        
        // editions are only initiated if not already exists. For editions in paused state, the edition will change to active
        if ( _states[editionHash] == State.NIL ) {
            _storeEdition(edition, editionHash);
            IValidator(edition.validator).setRules(editionHash, initData);
        }
        _states[editionHash] = State.ACTIVE;
        
        emit SetEdition(editionHash, edition, initData);
        return editionHash;
    }

    function _storeEdition(
        Edition memory edition,
        bytes32 editionHash
    ) internal {
        _editionHashes[edition.descriptor.contractAddress][edition.descriptor.tokenId].push(editionHash);
        _edition[editionHash] = edition;
    }

    /// @inheritdoc IDistributor
    function pauseEdition(
        bytes32 editionHash
    ) external virtual override onlyCreator(_edition[editionHash].descriptor) {
        _states[editionHash] = State.PAUSED; // disable minting
        emit PauseEdition(editionHash);
    }
    
    // validate condition fulfilment and mint
    function mint(address to, bytes32 editionHash) external virtual payable returns (uint256) {
        require(_states[editionHash] == State.ACTIVE, 'Distributor: Minting Disabled');
        IValidator(_edition[editionHash].validator).validate{value: msg.value}(to, editionHash, bytes(''));
        
        uint256 tokenId = _mintToken(to);
        NFTDescriptor memory descriptor = _edition[editionHash].descriptor;
        _tokenURI[tokenId] = _fetchURIFromParent(descriptor);
        _editionHash[tokenId] = editionHash;
        
        return tokenId;
    }
    
    function revoke(uint256 tokenId) external virtual onlyCreator(_edition[_editionHash[tokenId]].descriptor) {
        require(isPermitted(tokenId, _REVOKE), 'Distributor: Non-revokable');
        delete _tokenURI[tokenId];
        delete _editionHash[tokenId];
        _burn(tokenId);
    }

    function destroy(uint256 tokenId) external virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: caller is not token owner nor approved'
        );
        delete _tokenURI[tokenId];
        delete _editionHash[tokenId];
        _burn(tokenId);
    }

    function update(uint256 tokenId) external virtual returns (string memory) {
        require(isPermitted(tokenId, _UPDATE), 'Distributor: Non-updatable');
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: caller is not token owner nor approved'
        );
        _tokenURI[tokenId] = _fetchURIFromParent(_edition[_editionHash[tokenId]].descriptor);
        return _tokenURI[tokenId];
    }

    function _mintToken(address to) internal returns (uint256) {
        uint256 tokenId = ++_tokenCounter;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function _fetchURIFromParent(NFTDescriptor memory descriptor) internal view virtual returns (string memory) {
        return IERC721Metadata(descriptor.contractAddress).tokenURI(descriptor.tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (address(0) != from && address(0) != to) {
            // disable transfer if the token is not transferable. It does not apply to mint/burn action
            require(isPermitted(tokenId, _TRANSFER), 'Distributor: Non-transferable');
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
        Edition memory edition
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    edition.descriptor.contractAddress,
                    edition.descriptor.tokenId,
                    edition.actions,
                    edition.validator
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

    function isPermitted(uint256 tokenId, uint96 action) view public returns (bool) {
        return _edition[_editionHash[tokenId]].actions & action == action;
    }

    function getEdition(bytes32 editionHash) external view virtual override returns (Edition memory) {
        return _edition[editionHash];
    }
    
    function getEditionHashes(NFTDescriptor memory descriptor) external view virtual returns (bytes32[] memory) {
        return _editionHashes[descriptor.contractAddress][descriptor.tokenId];
    }

}
