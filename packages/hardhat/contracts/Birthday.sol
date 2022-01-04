pragma solidity >=0.6.0 <0.7.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import './HexStrings.sol';
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract Birthday is ERC721, Ownable {

  using Strings for uint256;
  using HexStrings for uint160;
  
  constructor()

   public ERC721("Birthday", "BDAY") {
// Happy Birthday!  
}
  struct Birthday {
        string month;
        string day;
        string ordinal;
  }
  mapping (uint256 => Birthday) public bday;
  mapping (uint256 => bool) public claimedBirthday;
  mapping (address => bool) public  claimed;
  mapping (uint256 => string) public colors;
  
  uint256 maxDays = 366;
  uint256 PRICE = 7 * 10**16;
  string baseColor = "#000000";

  function setColor(string memory color, uint id) public {
    require(msg.sender == ownerOf(id), "Only owner can set color");
    colors[id] = color;
  }

  function mintItem(uint256 _birthday)
      public payable
      returns (uint256)
  {
      
      // require(!claimed[msg.sender], "You cant have 2 birthdays you silly goose");
      require(msg.value >= PRICE, "Too low price");
      claimed[msg.sender] = true;
      require(!claimedBirthday[_birthday], "Birthday already claimed :)");
      claimedBirthday[_birthday] = true;
      setBday(_birthday);
      _mint(msg.sender,  _birthday);
      return _birthday;
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      string memory owner = uint160(ownerOf(id)).toHexString(20);
      string memory name = string(abi.encodePacked(bday[id].month, " ",bday[id].day, bday[id].ordinal));
      string memory description = string(abi.encodePacked('Happy Birthday'));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));
      string memory day = string(abi.encodePacked(bday[id].day));
      string memory month = string(abi.encodePacked(bday[id].month));


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
                              '", "attributes": [{"trait_type": "month", "value": "',
                              month,
                              '"},{"trait_type": "day", "value": "',
                              day,
                              '"}], "owner":"',
                              owner,
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
  '<rect width="400" height="400" fill="',colors[id],'" />',
  '<text x="200" y="200" font-size="2em" text-anchor="middle" font-family="Helvetica" fill="white" > ''🎂'," ",bday[id].month, " ",bday[id].day, bday[id].ordinal, '</text>',
  '<text x="40" y="360" font-size="2em" font-family="Helvetica" fill="white"> ''</text>',
  '</svg>'));

    return render;
  }
/**
@dev returns number into ordinal date */
function ordinal(uint256 _day) internal view returns (string memory)  {
  if (_day == 1 || _day == 21 || _day == 31) {
    return ("st");
  } else if (_day == 2 || _day == 22) {
    return ("nd");
  } else if (_day == 3 || _day == 23) {
    return ("rd");
  } else {
    return ("th");
  }
}

/**
@dev Map Bday Struct
@param _birthday day of year
@param _month Month of bday
@param _day Day of bday */

function mapBday(uint256 _birthday, string memory _month, uint256 _day) private {
    string memory month = string(abi.encodePacked(_month));
    string memory day = string(abi.encodePacked(uint2str(_day)));
    string memory ordinal = string(abi.encodePacked(ordinal(_day)));
    Birthday storage birthday = bday[_birthday];
        birthday.month = _month;
        birthday.day = day;
        birthday.ordinal = ordinal;
}

/**
@dev Set bday mapping
@param _day uint256
*/
function setBday(uint256 _day) internal  {
    if (_day <1 || _day > maxDays) {
      revert("Invalid day");
    }
    else if (_day <= 31 && _day >= 1 ) {
      mapBday(_day, "January", _day);
    }
    else if (_day <= 60 && _day >= 32) {
      mapBday(_day, "February", _day -31 );
    }
    else if (_day <= 91 && _day >= 61) {
      mapBday(_day, "March", _day - 60);
    }
    else if (_day <= 121 && _day >= 92) {
      mapBday(_day, "April", _day - 91);
    }
    else if (_day <= 152 && _day >= 122) {
      mapBday(_day, "May", _day - 121);
    }
    else if  (_day <= 182 && _day >= 153) {
      mapBday(_day, "June", _day - 152);
    }
    else if (_day <= 213 && _day >= 183) {
      mapBday(_day, "July", _day - 182);
    }
    else if (_day <= 244 && _day >= 214) {
      mapBday(_day, "August", _day - 213);
    }
    else if (_day <= 274 && _day >= 245) {
      mapBday(_day, "September", _day - 244);
    }
    else if (_day <= 305 && _day >= 275) {
      mapBday(_day, "October", _day - 274);
    }
    else if (_day <= 335 && _day >= 306) {
      mapBday(_day, "November", _day - 305);
    }
    else if (_day <= 366 && _day >= 336) {
      mapBday(_day, "December", _day - 335);
    }
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
