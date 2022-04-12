pragma solidity >=0.6.0 <0.7.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import './HexStrings.sol';
import './ColorsInterface.sol';
/*
██████╗░██╗██████╗░████████╗██╗░░██╗██████╗░░█████╗░██╗░░░██╗
██╔══██╗██║██╔══██╗╚══██╔══╝██║░░██║██╔══██╗██╔══██╗╚██╗░██╔╝
██████╦╝██║██████╔╝░░░██║░░░███████║██║░░██║███████║░╚████╔╝░
██╔══██╗██║██╔══██╗░░░██║░░░██╔══██║██║░░██║██╔══██║░░╚██╔╝░░
██████╦╝██║██║░░██║░░░██║░░░██║░░██║██████╔╝██║░░██║░░░██║░░░
╚═════╝░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░**/


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
  mapping (uint256 => string) public colorText;
  mapping (uint256 => bool) public colorUsed;
  
  uint256 maxDays = 366;
  uint256 PRICE = 0;//7 * 10**16;
  uint256 presentAmount = 0;//5 * 10**16;
  string baseColor = "#1B191B";
  string baseColorLight = "#F7F9F7";
  uint currentBday = 0;
  bool public presentsActive = true;
  address public colorsContract = 0x9fdb31F8CE3cB8400C7cCb2299492F2A498330a4;
  event presentGiven(address _to, address _from, uint256 _tokenId);

  function setColor(uint colorsTokenId, uint id) public {
    require(msg.sender == ownerOf(id), "Only owner can set color");
    require(ColorsInterface(colorsContract).ownerOf(colorsTokenId) == _msgSender() , "Sender does not own color");
    // require(!colorUsed[colorsTokenId], "Color already used");
    string memory color  = ColorsInterface(colorsContract).getHexColor(colorsTokenId);
    colorUsed[colorsTokenId] = true;
    colors[id] = color;
  }
  
//set colors contract

/**
@dev Set the current birthday to the given id.
@param id The id of the birthday to set.
 */
function givePresent(uint id) public payable{
  require(presentsActive, "Presents are not active at this time");
  require( _msgSender() != ownerOf(id), "Present Sender cannot be the same as the Birthday Holder");
  require(msg.value >= presentAmount, "Present amount is not enough to activate");
  require(id != currentBday, "Birthday already set");
  currentBday = id;
  address payable bdayRecipient = payable(ownerOf(id));
  bdayRecipient.transfer(msg.value);
  emit presentGiven(ownerOf(id), _msgSender(), id);

}
/**
@dev Admin Set the current birthday to the given id.
@param id The id of the birthday to set.
 */
function setCurrentBdayAdmin(uint id) public onlyOwner{
  require(id != currentBday, "Birthday already set");
  currentBday = id;
}
/** 
@dev Disable/Activate setCurrentBday public function.
*/
function togglePresentsActive() public onlyOwner{
  if (presentsActive) {
    presentsActive = false;
  }
  else {
    presentsActive = true;
  }
}
/** 
@dev set PRICE
*/
function setPrice(uint256 _PRICE) public onlyOwner{
  PRICE = _PRICE;
}
/**
@dev set presentAmount
*/
function setPresentAmount(uint256 _presentAmount) public onlyOwner{
  presentAmount = _presentAmount;
}


function setColorsContract(address _colorsContract) public onlyOwner {
    colorsContract = _colorsContract;
  } 
  function invertTextColor(uint id) private {
        require(msg.sender == ownerOf(id), "Only owner can set color");
        if (compareStrings(baseColor,colorText[id])) {
            colorText[id] = baseColorLight;
        } else {
            colorText[id] = baseColor;
        }   
    }
  function toggleDarkmode(uint id) public {
     require(msg.sender == ownerOf(id), "Only owner can set color");
        if (compareStrings(baseColor,colors[id])) {
            colorText[id] = baseColor;
            colors[id] = baseColorLight;
        } else if (compareStrings(baseColorLight,colors[id])) {
            colorText[id] = baseColor;
            colors[id] = baseColorLight;
        } 
        else {
            invertTextColor(id);
        }
  }

  function mintItem(uint256 _birthday)
      public payable
      returns (uint256)
  {
      require(!claimed[msg.sender], "You cant have 2 birthdays you silly goose");
      require(msg.value >= PRICE, "Too low price");
      claimed[msg.sender] = true;
      require(!claimedBirthday[_birthday], "Birthday already claimed :)");
      claimedBirthday[_birthday] = true;
      colors[_birthday] = baseColor;
      colorText[_birthday] = baseColorLight;
      setBday(_birthday);
      _mint(msg.sender, _birthday);
      return _birthday;
  }

  //get birthday by day of the year aka token id
  function getBday(uint256 id) public view returns (string memory)
  {
    return string(abi.encodePacked(bday[id].month, " ",bday[id].day, bday[id].ordinal));
  }

  // withdaw ether from contract 
  function withdraw() public onlyOwner {
    require(address(this).balance > 0, "No ether to withdraw");
    msg.sender.transfer(address(this).balance);
  }
  

  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      string memory owner = uint160(ownerOf(id)).toHexString(20);
      string memory name = string(abi.encodePacked(bday[id].month, " ",bday[id].day, bday[id].ordinal));
      string memory description = string(abi.encodePacked('Happy Birthday!'));
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

  function generateSVGofTokenById(uint256 id) public view returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    if (id == currentBday){
    
    string memory render = string(abi.encodePacked('<svg baseProfile="full" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="400" height="400"><path fill="',
    colors[id],'" d="M0 0h400v400H0z"/><text dx="-180" dy="-30" letter-spacing="3" x="10" y="50" font-size="3em" text-anchor="middle" font-family="Impact">🎁 <animateTransform begin="6s" attributeName="transform" type="translate" dur="10s" values="0,-80; 0,50;" repeatCount="indefinite"/> <animateMotion begin="6s" dur="10s" repeatCount="indefinite"> <mpath xlink:href="#prefix__a"/> </animateMotion></text><text dx="-160" dy="-30" letter-spacing="3" x="10" y="50" font-size="4em" text-anchor="middle" font-family="Impact">🎁 <animateTransform begin="1s" attributeName="transform" type="translate" dur="10s" values="0,-80; 0,50;" repeatCount="indefinite"/> <animateMotion begin="1s" dur="10s" repeatCount="indefinite"> <mpath xlink:href="#prefix__a"/> </animateMotion></text><text dx="-80" letter-spacing="3" x="10" y="50" font-size="3em" text-anchor="middle" font-family="Impact">🎁 <animateTransform begin="4s" attributeName="transform" type="translate" dur="10s" values="0,-80; 0,50;" repeatCount="indefinite"/> <animateMotion begin="4s" dur="10" rotate="yes" repeatCount="indefinite"> <mpath xlink:href="#prefix__a"/> </animateMotion></text><text dx="-80" letter-spacing="3" x="10" y="50" font-size="3em" text-anchor="middle" font-family="Impact">🎁 <animateTransform begin="9s" attributeName="transform" type="translate" dur="10s" values="0,-80; 0,50;" repeatCount="indefinite"/> <animateMotion begin="9s" dur="10" rotate="yes" repeatCount="indefinite"> <mpath xlink:href="#prefix__a"/> </animateMotion></text><text dy="-70" letter-spacing="3" x="10" y="50" font-size="3em" text-anchor="middle" font-family="Impact">🎁 <animateTransform attributeName="transform" begin="1s" type="translate" dur="10s" values="0,-80; 0,50;" repeatCount="indefinite"/> <animateMotion dur="10s" begin="1s" repeatCount="indefinite"> <mpath xlink:href="#prefix__a"/> </animateMotion></text><text dy="-70" letter-spacing="3" x="10" y="50" font-size="4em" text-anchor="middle" font-family="Impact">🎁 <animateTransform attributeName="transform" begin="4s" type="translate" dur="10s" values="0,-80; 0,50;" repeatCount="indefinite"/> <animateMotion dur="10s" begin="4s" repeatCount="indefinite"> <mpath xlink:href="#prefix__a"/> </animateMotion></text><text dy="-70" dx="80" letter-spacing="3" x="10" y="50" font-size="4em" text-anchor="middle" font-family="Impact">🎁 <animateTransform begin="7s" attributeName="transform" type="translate" dur="10s" values="0,-80; 0,50;" repeatCount="indefinite"/> <animateMotion begin="7s" dur="10s" repeatCount="indefinite"> <mpath xlink:href="#prefix__a"/> </animateMotion></text><text dy="-70" dx="100" letter-spacing="3" x="10" y="50" font-size="3em" text-anchor="middle" font-family="Impact">🎁 <animateTransform begin="3s" attributeName="transform" type="translate" dur="10s" values="0,-80; 0,50;" repeatCount="indefinite"/> <animateMotion begin="3s" dur="10s" repeatCount="indefinite"> <mpath xlink:href="#prefix__a"/> </animateMotion></text><text dx="160" letter-spacing="3" x="10" y="50" font-size="3em" text-anchor="middle" font-family="Impact">🎁 <animateTransform attributeName="transform" type="translate" dur="10s" values="0,-80; 0,50;" repeatCount="indefinite"/> <animateMotion dur="10s" repeatCount="indefinite"> <mpath xlink:href="#prefix__a"/> </animateMotion></text><g transform="scale(.9)"><path d="M200 0c-25 50 25 50 0 100s25 50 0 100 25 50 0 100 25 50 0 100" fill="none" stroke="red" stroke-width="0" id="prefix__a"/></g><text fill="#fff" x="200" y="210" letter-spacing="3" font-size="4em" text-anchor="middle" font-family="Impact"><animate attributeName="font-size" values="4em;6em;4em" keyTimes="0; 0.5; 1" keySplines=".42,0,1,1;" dur="5s" repeatCount="indefinite"/>', 
    bday[id].month,'</text><text x="350" y="50" letter-spacing="2" font-size="2em" text-anchor="middle" font-family="Impact" fill="#fff"> <tspan>',
    bday[id].day,'</tspan> <tspan font-size=".6em" dx="-.45em" dy="-.55em">',bday[id].ordinal,'</tspan></text></svg>'));
    return render;

    } else {

    string memory renderNormal = string(abi.encodePacked(
    
  '<svg width="400" height="400">',
  '<rect width="400" height="400" fill="',colors[id],'" />',
  '<text x="200" y="210" letter-spacing="3px" font-size="4em" text-anchor="middle" font-family="Impact" fill="',colorText[id],'"> '" ",bday[id].month, " "'</text>',
  '<text x="380" y="50" letter-spacing="2px" font-size="2em" text-anchor="end" font-family="Impact" fill="',colorText[id],'"> <tspan>',bday[id].day,'</tspan><tspan font-size="0.6em" dy="-0.55em">', bday[id].ordinal,"" '</tspan></text>',
  '</svg>') );
      return renderNormal;
  }}

function compareStrings(string memory a, string memory b) public view returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
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
