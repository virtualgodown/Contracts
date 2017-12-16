pragma solidity ^ 0.4 .4;

import './owned.sol';
import './TokenERC20.sol';

contract SALE is owned, TokenERC20 {
  uint256 public mintedToken = 0;
  uint256 public softCap = 1000;
  uint256 public hardCap;
  uint256 public presaleValue1 = 0;
  uint256 public presaleValue2 = 0;
  uint256 public icoValue = 0;
  uint8 flagPresale1 = 0;
  uint8 flagPresale2 = 0;
  uint256 public buyPrice = 5000000000000000; //1 Rim = 0.005ether
  bool isPresale1 = false;
  bool isPresale2 = false;
  bool isIco = false;
  uint256 private eth;
  uint256 _rim;
  address[] private userAddress;
  mapping(address => uint256) internal receivedPresaleAmount;
  uint256 _decimal = 10 ** uint256(decimals);
  //events for log
  event LogPayment(address from, uint256 amount);

  /**
   *   rollback if softCap is reached
   *   returns back user wei
   *   takes given token
   **/
  function rollBackPresale(uint8 dis) internal {
    uint256 userWei;
    for (uint256 i = 0; i < userAddress.length; i++) {

      userWei = receivedPresaleAmount[userAddress[0]];
      if (userWei != 0) {
        receivedPresaleAmount[userAddress[0]] = 0;
        userAddress[0].transfer(userWei);
        balanceOf[userAddress[0]] -= ((userWei / (buyPrice)) * dis) * _decimal;
        balanceOf[owner] -= (((userWei / (buyPrice)) * dis) / 10) * _decimal;
        mintedToken += ((((userWei / (buyPrice)) * dis) + (((userWei / (buyPrice)) * dis) / 10))) * _decimal;
      }

    }
    userAddress.length = 0; //freeing up array

  }

  /*
    this destroy all presale values
    called once a presale is ended
  */
  function destroy() internal {
    for (uint256 i = 0; i < userAddress.length; i++) {
      receivedPresaleAmount[userAddress[0]] = 0;
    }
    userAddress.length = 0;
  }

  //function to mint coin
  function mintToken(uint8 _sale) {
    if (_sale == 1) {
      mintedToken += 10000000 * 10 ** uint256(decimals);
      totalSupply -= mintedToken;
      hardCap = mintedToken; //total token in presale
    } else if (_sale == 2) {
      mintedToken += 30000000 * 10 ** uint256(decimals);
      totalSupply -= mintedToken;
      hardCap = mintedToken; //total token in ico
    }
  }


  //move ether to owner account
  function withdraw() private {
    eth = this.balance;
    owner.transfer(eth);
  }

  //presale1
  function presale_1(address _from, uint256 _value) internal {
    _rim = ((_value / buyPrice) * 4) * _decimal; //400% Discount
    if (mintedToken < _rim) revert();
    //if ((presaleValue1 + _rim) >= hardCap) revert(); //if presale value reaches hardcap , reverts
    else {
      presaleValue1 += (_rim + (_rim / 10)); //Add to Presale Value
      balanceOf[_from] += _rim; //800 tokens per ether
      receivedPresaleAmount[_from] += _value; //keep track of user wei
      balanceOf[owner] += _rim / 10; //10% 0f 800 tokens
      mintedToken -= (_rim + (_rim / 10)); //reduced in Total token
      //added
      userAddress.push(_from);

      if (presaleValue1 + (800 * _decimal) >= hardCap) {
        isPresale1 = false;
        flagPresale1 = 2;
        if (presaleValue1 < softCap) {
          rollBackPresale(4); //return ether to user
        } else {
          destroy(); //destroy presale1 values
          withdraw(); //transfer ether to owner
        }

      }
    }
  }

  //presale2
  function presale_2(address _from, uint256 _value) internal {
    _rim = ((_value / buyPrice) * 3) * _decimal; //300% Discount
    if (mintedToken < _rim) revert();
    //if ((presaleValue2 + _rim) >= hardCap) revert(); //if presale value reaches hardcap , reverts
    else {

      presaleValue2 += (_rim + (_rim / 10)); //Add to Presale Value
      balanceOf[_from] += _rim; //600 tokens per ether
      receivedPresaleAmount[_from] += _value; //keep track of user wei
      balanceOf[owner] += _rim / 10; //10% 0f 600 tokens
      mintedToken -= (_rim + (_rim / 10)); //reduced in Total token
      //added
      userAddress.push(_from);
      if (presaleValue2 + (800 * _decimal) >= hardCap) {
        isPresale2 = false;
        flagPresale2 = 2;
        if (presaleValue2 < softCap) {
          rollBackPresale(3); //return ether to user
        } else {
          destroy(); //destroy presale2 values
          withdraw(); //transfer ether to owner
        }
      }
    }
  }

  //ICO
  function ico(address _from, uint256 _value) internal {
    _rim = (_value / buyPrice) * _decimal; //Ordinary(without discount)
    if (mintedToken < _rim) revert();
    balanceOf[_from] += _rim; //200 tokens per ether
    balanceOf[owner] += _rim / 10; //10% 0f 200 tokens
    mintedToken -= (_rim + (_rim / 10)); //reduced in Total token
    icoValue += (_rim + (_rim / 10));
    withdraw();
  }



  /*
     function to start presale
     presale starts in order 1,2
  */
  function startPresale(uint8 presale_number) onlyOwner {

    if (presale_number == 1 && flagPresale1 == 0) {
      isPresale1 = true;
      flagPresale1 = 1;
      mintToken(1);
    } else if (presale_number == 2 && flagPresale2 == 0 && flagPresale1 == 2) {
      isPresale2 = true;
      flagPresale2 = 1;
      mintToken(1);
    } else revert();
  }

  /**
   * function to stop presale
   * once sale ended softcap is checked
   * if presalevalue reached softCap
   * rollback() is called
   * otherwise ether is transfered to Owner
   **/
  function stopPresale(uint8 presale_number) onlyOwner {
    if (presale_number == 1 && flagPresale1 == 1) {
      isPresale1 = false;
      flagPresale1 = 2;
      if (presaleValue1 < softCap) {
        rollBackPresale(4); //return ether to user
      } else {
        destroy(); //destroy presale1 values
        withdraw(); //transfer ether to owner
      }
    } else if (presale_number == 2 && flagPresale2 == 1) {
      isPresale2 = false;
      flagPresale2 = 2;
      if (presaleValue2 < softCap) {
        rollBackPresale(3);
      } else {
        destroy();
        withdraw();
      }
    } else revert();
  }

  function startico() onlyOwner {
    if (isPresale1 == true || isPresale2 == true || flagPresale1 == 0) revert(); //start after presale
    isIco = true;
    mintToken(2);
  }


  function buy() payable {
    if (isPresale1 == false && isPresale2 == false && isIco == false) revert(); //check if sale is true

    //    LogPayment(msg.sender, msg.value);

    if (isPresale1 == true) {
      presale_1(msg.sender, msg.value);
    } else if (isPresale2 == true) {
      presale_2(msg.sender, msg.value);
    } else if (isIco == true) {
      ico(msg.sender, msg.value);
    }
  }
  //accessory functions
  function presaleData(uint8 _no) public constant returns(uint256, uint256, uint256, uint256) {
    if (_no == 1) {

      return (presaleValue1, mintedToken, softCap, hardCap);
    } else if (_no == 2) {
      return (presaleValue2, mintedToken, softCap, hardCap);
    }
  }

  function icoData() public constant returns(uint256, uint256, uint256) {
    return (icoValue, mintedToken, hardCap);
  }

  function currentSale() public constant returns(uint8) {
    if (isPresale1 == true)
      return (1);
    else if (isPresale2 == true)
      return (2);
    else if (isIco == true)
      return (3);
  }
}