pragma solidity ^0.4.25;
import "../externals/SafeMath.sol";
contract ParseIntScientific {
    using SafeMath for uint256;
    byte constant private _PLUS_ASCII = byte(43);
    byte constant private _DASH_ASCII = byte(45);
    byte constant private _DOT_ASCII = byte(46);
    byte constant private _ZERO_ASCII = byte(48);
    byte constant private _NINE_ASCII = byte(57);
    byte constant private _E_ASCII = byte(69);
    byte constant private _LOWERCASE_E_ASCII = byte(101);
    function _parseIntScientific(string _inString) internal pure returns (uint) {
        return _parseIntScientific(_inString, 0);
    }
    function _parseIntScientificWei(string _inString) internal pure returns (uint) {
        return _parseIntScientific(_inString, 18);
    }
    function _parseIntScientific(string _inString, uint _magnitudeMult) internal pure returns (uint) {
        bytes memory inBytes = bytes(_inString);
        uint mint = 0;
        uint mintDec = 0;
        uint mintExp = 0;
        uint decMinted = 0;
        uint expIndex = 0;
        bool integral = false;
        bool decimals = false;
        bool exp = false;
        bool minus = false;
        bool plus = false;
        for (uint i = 0; i < inBytes.length; i++) {
            if ((inBytes[i] >= _ZERO_ASCII) && (inBytes[i] <= _NINE_ASCII) && (!exp)) {
                if (decimals) {
                    mintDec = mintDec.mul(10);
                    mintDec = mintDec.add(uint(inBytes[i]) - uint(_ZERO_ASCII));
                    decMinted++;
                } else {
                    integral = true;
                    mint = mint.mul(10);
                    mint = mint.add(uint(inBytes[i]) - uint(_ZERO_ASCII));
                }
            } else if ((inBytes[i] >= _ZERO_ASCII) && (inBytes[i] <= _NINE_ASCII) && (exp)) {
                mintExp = mintExp.mul(10);
                mintExp = mintExp.add(uint(inBytes[i]) - uint(_ZERO_ASCII));
            } else if (inBytes[i] == _DOT_ASCII) {
                require(integral, "missing integral part");
                require(!decimals, "duplicate decimal point");
                require(!exp, "decimal after exponent");
                decimals = true;
            } else if (inBytes[i] == _DASH_ASCII) {
                require(!minus, "duplicate -");
                require(!plus, "extra sign");
                require(expIndex + 1 == i, "- sign not immediately after e");
                minus = true;
            } else if (inBytes[i] == _PLUS_ASCII) {
                require(!plus, "duplicate +");
                require(!minus, "extra sign");
                require(expIndex + 1 == i, "+ sign not immediately after e");
                plus = true;
            } else if ((inBytes[i] == _E_ASCII) || (inBytes[i] == _LOWERCASE_E_ASCII)) {
                require(integral, "missing integral part");
                require(!exp, "duplicate exponent symbol");
                exp = true;
                expIndex = i;
            } else {
                revert("invalid digit");
            }
        }
        if (minus || plus) {
            require(i > expIndex + 2);
        } else if (exp) {
            require(i > expIndex + 1);
        }
        if (minus) {
            if (mintExp >= _magnitudeMult) {
                require(mintExp - _magnitudeMult < 78, "exponent > 77");
                mint /= 10 ** (mintExp - _magnitudeMult);
                return mint;
            } else {
                _magnitudeMult = _magnitudeMult - mintExp;
            }
        } else {
            _magnitudeMult = _magnitudeMult.add(mintExp);
        }
        if (_magnitudeMult >= decMinted) {
            require(decMinted < 78, "more than 77 decimal digits parsed");
            mint = mint.mul(10 ** (decMinted));
            mint = mint.add(mintDec);
            require(_magnitudeMult - decMinted < 78, "exponent > 77");
            mint = mint.mul(10 ** (_magnitudeMult - decMinted));
        } else {
            decMinted -= _magnitudeMult;
            require(decMinted < 78, "more than 77 decimal digits parsed");
            mintDec /= 10 ** (decMinted);
            require(_magnitudeMult < 78, "more than 77 decimal digits parsed");
            mint = mint.mul(10 ** (_magnitudeMult));
            mint = mint.add(mintDec);
        }
        return mint;
    }
}