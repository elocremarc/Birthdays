// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

contract ColorsInterface {
    function ownerOf(uint256 _token) public view returns(address){}
    function getHexColor(uint id)  public view returns (string memory) {}
}