// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Colors is ERC721 {
    constructor() ERC721("Color", "Color") public {

    }

    mapping (uint256 => string) public colors;


    function mint( uint256 _tokenId) public {        
        _mint(msg.sender, _tokenId);
    }

    function getHexColor(uint id)  public view returns ( string memory) {
        if(id == 1) return "#aecef8";
        if(id == 2) return "#fabbe2";
        if(id == 3) return "#21b20f";
        if(id == 4) return "#f8f5ef";
        else return "grey";
    }

}
