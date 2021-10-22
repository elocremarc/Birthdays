pragma solidity >=0.6.0 <0.7.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import './HexStrings.sol';
import './ToColor.sol';
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract Birthday is ERC721, Ownable {

  using Strings for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

    struct Birthday {
        string month;
        string day;
    }


  constructor() public ERC721("Birthday", "BDAY") {
// Happy Birthday!  
}

  mapping (uint256 => bytes3) public color;
  mapping (uint256 => uint256) public chubbiness;

  mapping (uint256 => Birthday) public bday;
  mapping (uint256 => bool) public claimedBirthday;
  mapping (address => bool) public  claimed;

  address creator1 = 0x0000000000000000000000000000000000000000;
  address creator2 = 0x0000000000000000000000000000000000000000;
  string creator1Bday = "April 15";
  string creator2Bday = "May 15";
  uint256 maxDays = 366;
  uint256 PRICE = 7 * 10**16;

  //uint256 mintDeadline = block.timestamp + 24 hours;

  function mintItem(uint256 _birthday)
      public
      returns (uint256)
  {
      claimed[msg.sender] = true;
      claimedBirthday[_birthday] = true;
      setBday(_birthday);
      //bday[_birthday] = getBday(_birthday);
     // require( block.timestamp < mintDeadline, "DONE MINTING");
     // _tokenIds.increment();

      //uint256 id = _tokenIds.current();
      _mint(msg.sender,  _birthday);

       bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) ));
      color[_birthday] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
      chubbiness[_birthday] = 35+((55*uint256(uint8(predictableRandom[3])))/255);

      return _birthday;
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      string memory name = string(abi.encodePacked(bday[id].month, " ",bday[id].day));
      string memory description = string(abi.encodePacked('Happy Birthday'));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "external_url":"https://burnyboys.com/token/',
                              id.toString(),
                              '", "attributes": [{"trait_type": "color", "value": "#',
                              color[id].toColor(),
                              '"},{"trait_type": "chubbiness", "value": ',
                              uint2str(chubbiness[id]),
                              '}], "owner":"',
                              (uint160(ownerOf(id))).toHexString(20),
                              '", "image": "',
                              'data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          );
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    string memory render = string(abi.encodePacked(
    
  '<svg width="400" height="400">',
  '<rect width="400" height="400" style="=fill:black" />',
  '<text x="150" y="220" font-size="6em" >🎂</text>',
  '<text x="40" y="360" font-size="2em" font-family="Helvetica" fill="white"> ',bday[id].month, " ",bday[id].day, '</text>',
  '</svg>'));

    return render;
  }

/**
@dev Map Bday Struct
@param _birthday day of year
@param _month Month of bday
@param _day Day of bday */

function mapBday(uint256 _birthday, string memory _month, string memory _day) private {
    string memory month = string(abi.encodePacked(_month));
    string memory day = string(abi.encodePacked(_day));
    Birthday storage birthday = bday[_birthday];
        birthday.month = _month;
        birthday.day = _day;
  
}

  /**  x
@dev Converts day number to Bday
@param _day uint256
*/
function setBday(uint256 _day) internal  {
    if (_day <1 || _day > maxDays) {
      revert("Invalid day");
    }
    else if (_day <= 31 && _day >= 1 ) {

    mapBday(_day, "January", uint2str(_day));
      //  return (string(abi.encodePacked("January", " ", uint2str(_day))));
    }
    // else if (_day <= 31 && _day >= 1 ) {
    //     return (string(abi.encodePacked("January", " ", uint2str(_day))));
    // }
    // else if (_day <= 60 && _day >= 32) {
    //     return (string(abi.encodePacked("February", " ", uint2str(_day - 31))));
    // }
    // else if (_day <= 91 && _day >= 61) {
    //     return (string(abi.encodePacked("March" , " " , uint2str (_day - 60))));
    // }
    // else if (_day <= 121 && _day >= 92) {
    //     return (string(abi.encodePacked("April" , " " , uint2str(_day - 91))));
    // }
    // else if (_day <= 152 && _day >= 122) {
    //     return (string(abi.encodePacked("May" , " " , uint2str(_day - 121))));
    // }
    // else if  (_day <= 182 && _day >= 153) {
    //     return (string(abi.encodePacked("June" , " " , uint2str(_day - 152))));
    // }
    // else if (_day <= 213 && _day >= 183) {
    //     return (string(abi.encodePacked("July" , " " , uint2str(_day - 182))));
    // }
    // else if (_day <= 244 && _day >= 214) {
    //     return (string(abi.encodePacked("August" , " " , uint2str(_day - 213))));
    // }
    // else if (_day <= 274 && _day >= 245) {
    //     return (string(abi.encodePacked("September" , " " , uint2str( _day - 244))));
    // }
    // else if (_day <= 305 && _day >= 275) {
    //     return (string(abi.encodePacked("October" , " " , uint2str( _day - 274))));
    // }
    // else if (_day <= 335 && _day >= 306) {
    //     return (string(abi.encodePacked("November" , " " , uint2str( _day - 305))));
    // }
    // else if (_day <= 366 && _day >= 336) {
    //     return (string(abi.encodePacked("December" , " " , uint2str( _day - 335))));
    // }
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }
}
