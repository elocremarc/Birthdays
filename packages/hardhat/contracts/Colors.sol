// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Colors is ERC721 {
    constructor() ERC721("Color", "Color") public {

    }

    mapping (uint256 => string) public colors;


    function mint( uint256 _tokenId) public payable {        
        _mint(msg.sender, _tokenId);
    }

    function getHexColor(uint id) public returns ( string memory) {
        return  "#ff53de";
    }

}
