// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./ERC3664/extensions/ERC3664Combinable.sol";

contract Metacore is ERC3664Combinable, ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    uint256 private _curTokenId = 0;

    string private _projectName = "Metacore";

    uint256 public constant METANAME_ID = 1;

    constructor() ERC3664Combinable() ERC721("Metacore Identity", "MCI") Ownable() {
        _mint(METANAME_ID, "Metacore Identity", "Metaname", "");
    }

    function getNextTokenID() public view returns (uint256) {
        return _curTokenId.add(1);
    }

    function claim(string memory name) public nonReentrant {
        require(getNextTokenID() <= 8000, "Metacore: reached the maximum number of claim");

        _curTokenId += 1;
        _safeMint(_msgSender(), _curTokenId);
        attach(_curTokenId, METANAME_ID, 1, bytes(name));
    }

    function combine(uint256 tokenId, uint256[] calldata subTokens) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Metacore: caller is not main token owner nor approved");
        for (uint256 i = 0; i < subTokens.length; i++) {
            require(_isApprovedOrOwner(_msgSender(), subTokens[i]), "Metacore: caller is not sub token owner nor approved");
            _burn(subTokens[i]);
            super.combine(tokenId, subTokens[i]);
        }
    }

    function mintAttribute(
        uint256 attrId,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) public onlyOwner {
        _mint(attrId, _name, _symbol, _uri);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[3] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 300 100"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="25" class="base">';

        parts[1] = getImageText(tokenId, 25);

        parts[2] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        string memory attributes = getAttributes(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', _projectName, ' #', tokenId.toString(), '", "description": "MetaCore is an identity system which can make all metaverse citizens join into different metaverses by using same MetaCore Identity. The first modular NFT with MetaCore at its core, with arbitrary attributes addition and removal, freely combine and divide each components. Already adapted to multiple metaverse blockchain games. FUTURE IS COMMING", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '","attributes":[', attributes, ']}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function getImageText(uint256 tokenId, uint256 pos) internal view returns (string memory) {
        bytes memory text = abi.encodePacked(_projectName, ' #', tokenId.toString());
        return string(abi.encodePacked(text, getSubImageText(tokenId, pos)));
    }

    function getSubImageText(uint256 tokenId, uint256 pos) internal view returns (bytes memory) {
        bytes memory text = "";
        uint256[] memory tokens = subTokens(tokenId);
        for (uint i = 0; i < tokens.length; i++) {
            uint256 newPos = 20 * (i + 1) + pos;
            text = abi.encodePacked(text, '</text><text x="10" y="', newPos.toString(), '" class="base">');
            text = abi.encodePacked(text, getImageText(tokens[i], newPos));
        }
        return text;
    }

    function getAttributes(uint256 tokenId) internal view returns (string memory) {
        bytes memory data = "";
        uint256[] memory attrs = attributesOf(tokenId);
        for (uint i = 0; i < attrs.length; i++) {
            if (data.length > 0) {
                data = abi.encodePacked(data, ',');
            }
            data = abi.encodePacked(data, '{"trait_type":"', symbol(attrs[i]), '","value":"', textOf(tokenId, attrs[i]), '"}');
        }
        data = abi.encodePacked(data, getSubAttributes(tokenId));

        return string(data);
    }

    function getSubAttributes(uint256 tokenId) internal view returns (bytes memory) {
        bytes memory data = "";
        uint256[] memory subTokens = bundles[tokenId];
        for (uint i = 0; i < subTokens.length; i++) {
            data = abi.encodePacked(data, ',');
            data = abi.encodePacked(data, getAttributes(subTokens[i]));
        }
        return data;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}