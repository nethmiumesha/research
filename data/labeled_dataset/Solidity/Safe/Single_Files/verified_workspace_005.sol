pragma solidity 0.8.23;
interface IStrategy {
    function lastPositionAdjustment() external view returns (uint256);
    function currentTick() external view returns (int24);
    function positionMain() external view returns (int24 lowerTick, int24 upperTick);
    function pool() external view returns (address);
    function twap() external view returns (int56);
    function positionWidth() external view returns (int24);
    function isCalm() external view returns (bool);
    function moveTicks() external;
    function maxTickDeviation() external view returns (int56);
}
interface IStrategyVelodrome {
    function currentTick() external view returns (int24);
    function positionMain() external view returns (int24 baseLower, int24 lowerTick, int24 upperTick);
    function pool() external view returns (address);
    function nftManager() external view returns (address);
}
interface IPool {
    function tickSpacing() external view returns (int24);
    function observe(uint32[] calldata secondsAgos) external view returns (int56[] memory tickCumulatives, int160[] memory secondsPerLiquidityCumulativeX128s);
}
interface IAlgebraPool {
    function getTimepoints(uint32[] calldata secondsAgos)
    external
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    );
}
contract BeefyPositionMulticall {
    address public gelato = address(0x035066D430e5ca34e7BdB0756FCe82186CAfe1F0);
    error NotAuthorized();
    function positionNeedsTickAdjustment(address[] memory _strategies) external view returns (bool[] memory inRange) {
        inRange = new bool[](_strategies.length);
        for (uint256 i; i < _strategies.length;) {
            IStrategy _strategy = IStrategy(_strategies[i]);
            address pool = _strategy.pool();
            int56 twapTick = _strategy.twap();
            int24 width = _strategy.positionWidth();
            int56 deviation = _strategy.maxTickDeviation();
            int24 tickSpacing = IPool(pool).tickSpacing();
            try IStrategyVelodrome(address(_strategy)).nftManager() returns (address) {
                IStrategyVelodrome _veloStrategy = IStrategyVelodrome(_strategies[i]);
                (,int24 lowerTick, int24 upperTick) = _veloStrategy.positionMain();
                inRange[i] = _inRange(int24(twapTick), lowerTick, upperTick, width, tickSpacing, deviation);
            } catch {
                (int24 lowerTick, int24 upperTick) = _strategy.positionMain();
                inRange[i] = _inRange(int24(twapTick), lowerTick, upperTick, width, tickSpacing, deviation);
            }
            unchecked { ++i; }
        }
        return inRange;
    }
    function _inRange(int24 twapTick, int24 lowerTick, int24 upperTick, int24 width, int24 tickSpacing, int56 deviation) internal pure returns (bool) {
        int24 bound = (width * tickSpacing) / 2;
        if (deviation <= 2) {
            int24 extremeBound = 500;
            if (twapTick <= (lowerTick - extremeBound) || twapTick >= (upperTick + extremeBound)) return true;
            return twapTick >= (lowerTick + bound) && twapTick <= (upperTick - bound);
        } else {
            return twapTick >= (lowerTick + bound) && twapTick <= (upperTick - bound);
        }
    }
    function lastPositionAdjustments(address[] memory _strategies) external view returns (uint256[] memory) {
        uint256[] memory lastAdjustments = new uint256[](_strategies.length);
        for (uint256 i; i < _strategies.length;) {
            IStrategy _strategy = IStrategy(_strategies[i]);
            lastAdjustments[i] = _strategy.lastPositionAdjustment();
            unchecked { ++i; }
        }
        return lastAdjustments;
    }
    function encodeData(address one, address two, address three, uint num) external pure returns (bytes memory) {
        if (num == 1) {
            return abi.encode(one);
        } else if (num == 2) {
            return abi.encode(one, two);
        } else {
            return abi.encode(one, two, three);
        }
    }
    function decodeData(bytes memory _data, uint num) internal pure returns (address[] memory) {
        if (num == 1) {
            address[] memory strats = new address[](num);
            address decodedAddress = abi.decode(_data, (address));
            strats[0] = decodedAddress;
            return strats;
        } else if (num == 2) {
            address[] memory strats = new address[](num);
            (address one, address two) = abi.decode(_data, (address, address));
            strats[0] = one;
            strats[1] = two;
            return strats;
        } else {
            (address one, address two, address three) = abi.decode(_data, (address, address, address));
            address[] memory strats = new address[](num);
            strats[0] = one;
            strats[1] = two;
            strats[2] = three;
            return strats;
        }
    }
    function moveTicks(bytes memory _data, uint num) external {
        if (msg.sender != gelato) {
            revert NotAuthorized();
        }
        address[] memory strats = decodeData(_data, num);
        for (uint i; i < strats.length;) {
            bool calm = IStrategy(strats[i]).isCalm();
            if (calm) {
                try IStrategy(strats[i]).moveTicks() {
                    unchecked { ++i; }
                } catch {
                    unchecked { ++i; }
                }
            }
        }
    }
    function isCalm(address[] memory _strategies) external view returns (bool[] memory) {
        bool[] memory calm = new bool[](_strategies.length);
        for (uint256 i; i < _strategies.length;) {
            calm[i] = IStrategy(_strategies[i]).isCalm();
            unchecked { ++i; }
        }
        return calm;
    }
}