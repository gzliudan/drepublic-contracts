// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title NFTFactory
 * NFTFactory - ERC1155 contract has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract NFTFactory is ERC1155, Ownable {
    using Address for address;
    using Strings for string;
    using SafeMath for uint256;
    
    // onReceive function signatures
    bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;
    
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => string) customUri;
    
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    
    /**
     * @dev Require _msgSender() to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == _msgSender(), "NFTFactory#creatorOnly: ONLY_CREATOR_ALLOWED");
        _;
    }
    
    /**
     * @dev Require _msgSender() to own more than 0 of the token id
     */
    modifier ownersOnly(uint256 _id) {
        require(balanceOf(_msgSender(), _id) > 0, "NFTFactory#ownersOnly: ONLY_OWNERS_ALLOWED");
        _;
    }
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
    }
    
    function uri(
        uint256 _id
    ) override public view returns (string memory) {
        require(_exists(_id), "NFTFactory#uri: nonexistent token");
        // We have to convert string to bytes to check for existence
        bytes memory customUriBytes = bytes(customUri[_id]);
        if (customUriBytes.length > 0) {
            return customUri[_id];
        } else {
            return super.uri(_id);
        }
    }
    
    /**
      * @dev Returns the total quantity for a token ID
      * @param _id uint256 ID of the token to query
      * @return amount of token in existence
      */
    function totalSupply(
        uint256 _id
    ) public view returns (uint256) {
        return tokenSupply[_id];
    }
    
    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
      * substitution mechanism
      * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     * @param _newURI New URI for all tokens
     */
    function setURI(
        string memory _newURI
    ) public onlyOwner {
        _setURI(_newURI);
    }
    
    /**
     * @dev Will update the base URI for the token
     * @param _tokenId The token to update. _msgSender() must be its creator.
     * @param _newURI New URI for the token.
     */
    function setCustomURI(
        uint256 _tokenId,
        string memory _newURI
    ) public creatorOnly(_tokenId) {
        customUri[_tokenId] = _newURI;
        emit URI(_newURI, _tokenId);
    }
    
    function creatorOf(uint256 _id) public view returns (address) {
        return creators[_id];
    }
    
    /**
      * @dev Creates a new token type and assigns _initialSupply to an address
      * NOTE: remove onlyOwner if you want third parties to create new tokens on
      *       your contract (which may change your IDs)
      * NOTE: The token id must be passed. This allows lazy creation of tokens or
      *       creating NFTs by setting the id's high bits with the method
      *       described in ERC1155 or to use ids representing values other than
      *       successive small integers. If you wish to create ids as successive
      *       small integers you can either subclass this class to count onchain
      *       or maintain the offchain cache of identifiers recommended in
      *       ERC1155 and calculate successive ids from that.
      * @param _initialOwner address of the first owner of the token
      * @param _id The id of the token to create (must not currenty exist).
      * @param _initialSupply amount to supply the first owner
      * @param _uri Optional URI for this token type
      * @param _data Data to pass if receiver is contract
      * @return The newly created token ID
      */
    function create(
        address _initialOwner,
        uint256 _id,
        uint256 _initialSupply,
        string memory _uri,
        bytes memory _data
    ) public onlyOwner returns (uint256) {
        require(!_exists(_id), "NFTFactory#create: token _id already exists");
        creators[_id] = _msgSender();
        
        if (bytes(_uri).length > 0) {
            customUri[_id] = _uri;
            emit URI(_uri, _id);
        }
        
        _mint(_initialOwner, _id, _initialSupply, _data);
        
        tokenSupply[_id] = _initialSupply;
        return _id;
    }
    
    /**
     * @notice Transfers amount amount of an _id from the _from address to the _to address specified
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     * @param _data    Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public virtual override {
        require(
            _from == _msgSender() || isApprovedForAll(_from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(_from, _to, _id, _amount, _data);
        
        // Check if recipient is contract
        if (_to.isContract()) {
            bytes4 retval = IERC1155Receiver(_to).onERC1155Received(_msgSender(), _from, _id, _amount, _data);
            require(retval == ERC1155_RECEIVED_VALUE, "NFTFactory#safeTransferFrom: INVALID_ON_RECEIVE_MESSAGE");
        }
    }
    
    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     * @param _data     Additional data with no specified format, sent in call to `_to`
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public virtual override {
        require(
            _from == _msgSender() || isApprovedForAll(_from, _msgSender()),
            "NFTFactory#safeBatchTransferFrom: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
        
        // Pass data if recipient is contract
        if (_to.isContract()) {
            bytes4 retval = IERC1155Receiver(_to).onERC1155BatchReceived(_msgSender(), _from, _ids, _amounts, _data);
            require(retval == ERC1155_BATCH_RECEIVED_VALUE, "NFTFactory#safeBatchTransferFrom: INVALID_ON_RECEIVE_MESSAGE");
        }
    }
    
    /**
      * @dev Mints some amount of tokens to an address
      * @param _to          Address of the future owner of the token
      * @param _id          Token ID to mint
      * @param _quantity    Amount of tokens to mint
      * @param _data        Data to pass if receiver is contract
      */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) virtual public creatorOnly(_id) {
        _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }
    
    /**
      * @dev Mint tokens for each id in _ids
      * @param _to          The address to mint tokens to
      * @param _ids         Array of ids to mint
      * @param _quantities  Array of amounts of tokens to mint per id
      * @param _data        Data to pass if receiver is contract
      */
    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            require(creators[_id] == _msgSender(), "NFTFactory#batchMint: ONLY_CREATOR_ALLOWED");
            uint256 quantity = _quantities[i];
            tokenSupply[_id] = tokenSupply[_id].add(quantity);
        }
        _mintBatch(_to, _ids, _quantities, _data);
    }
    
    /**
     * @notice Burn _quantity of tokens of a given id from msg.sender
     * @dev This will not change the current issuance tracked in _supplyManagerAddr.
     * @param _id     Asset id to burn
     * @param _quantity The amount to be burn
     */
    function burn(
        uint256 _id,
        uint256 _quantity
    ) public ownersOnly(_id)
    {
        _burn(_msgSender(), _id, _quantity);
        tokenSupply[_id] = tokenSupply[_id].sub(_quantity);
    }
    
    /**
     * @notice Burn _quantities of tokens of given ids from msg.sender
     * @dev This will not change the current issuance tracked in _supplyManagerAddr.
     * @param _ids     Asset id to burn
     * @param _quantities The amount to be burn
     */
    function batchBurn(
        uint256[] calldata _ids,
        uint256[] calldata _quantities
    ) public
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            require(balanceOf(_msgSender(), _id) > 0, "NFTFactory#ownersOnly: ONLY_OWNERS_ALLOWED");
            uint256 quantity = _quantities[i];
            tokenSupply[_id] = tokenSupply[_id].sub(quantity);
        }
        _burnBatch(msg.sender, _ids, _quantities);
    }
    
    /**
      * @dev Change the creator address for given tokens
      * @param _to   Address of the new creator
      * @param _ids  Array of Token IDs to change creator
      */
    function setCreator(
        address _to,
        uint256[] memory _ids
    ) public {
        require(_to != address(0), "NFTFactory#setCreator: INVALID_ADDRESS.");
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            _setCreator(_to, id);
        }
    }
    
    /**
      * @dev Change the creator address for given token
      * @param _to   Address of the new creator
      * @param _id  Token IDs to change creator of
      */
    function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
    {
        creators[_id] = _to;
    }
    
    /**
      * @dev Returns whether the specified token exists by checking to see if it has a creator
      * @param _id uint256 ID of the token to query the existence of
      * @return bool whether the token exists
      */
    function _exists(
        uint256 _id
    ) internal view returns (bool) {
        return creators[_id] != address(0);
    }
    
    function exists(
        uint256 _id
    ) external view returns (bool) {
        return _exists(_id);
    }
}
