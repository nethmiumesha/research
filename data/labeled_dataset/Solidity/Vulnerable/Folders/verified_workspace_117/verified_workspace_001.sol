pragma solidity ^0.8.24;
import "../interfaces/ISwapAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/external/ICurve.sol";
contract CurveAdapter is ISwapAdapter {
    function swap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) external override returns (uint256 amountOut) {
        IERC20(tokenIn).approve(pool, amountIn);
        uint256 outBefore = IERC20(tokenOut).balanceOf(address(this));
        uint256 curveMin = minAmountOut > 10 ? (minAmountOut * 999) / 1000 : 0;
        (int128 i, int128 j) = _findIndices(pool, tokenIn, tokenOut);
        if (i >= 0 && j >= 0) {
            uint256 ui = uint256(uint128(i));
            uint256 uj = uint256(uint128(j));
            (bool ok,) = pool.call(abi.encodeWithSignature(
                "exchange(int128,int128,uint256,uint256,address)", i, j, amountIn, curveMin, address(this)
            ));
            if (!ok) {
                (bool ok2,) = pool.call(abi.encodeWithSignature(
                    "exchange(int128,int128,uint256,uint256)", i, j, amountIn, curveMin
                ));
                if (!ok2) {
                    (bool ok3,) = pool.call(abi.encodeWithSignature(
                        "exchange(uint256,uint256,uint256,uint256,bool,address)", ui, uj, amountIn, curveMin, false, address(this)
                    ));
                    if (!ok3) {
                        (bool ok4,) = pool.call(abi.encodeWithSignature(
                            "exchange(uint256,uint256,uint256,uint256,bool)", ui, uj, amountIn, curveMin, false
                        ));
                        require(ok4, "Curve: exchange failed (tried all 4 interfaces)");
                    }
                }
            }
        } else {
            (int128 ui, int128 uj) = _findUnderlyingIndices(pool, tokenIn, tokenOut);
            require(ui >= 0 && uj >= 0, "Curve: token not in pool (tried coins and underlying_coins)");
            (bool ok5,) = pool.call(abi.encodeWithSignature(
                "exchange_underlying(int128,int128,uint256,uint256,address)", ui, uj, amountIn, curveMin, address(this)
            ));
            if (!ok5) {
                (bool ok6,) = pool.call(abi.encodeWithSignature(
                    "exchange_underlying(int128,int128,uint256,uint256)", ui, uj, amountIn, curveMin
                ));
                require(ok6, "Curve: exchange_underlying failed");
            }
        }
        amountOut = IERC20(tokenOut).balanceOf(address(this)) - outBefore;
        require(amountOut >= minAmountOut, "Curve: insufficient output");
        if (recipient != address(this)) {
            require(IERC20(tokenOut).transfer(recipient, amountOut), "Curve: transfer failed");
        }
    }
    function _findIndices(
        address pool,
        address tokenIn,
        address tokenOut
    ) internal view returns (int128 i, int128 j) {
        i = -1;
        j = -1;
        for (uint256 k = 0; k < 8; k++) {
            (bool ok, bytes memory data) = pool.staticcall(
                abi.encodeWithSelector(0xc6610657, k)
            );
            if (!ok) break;
            address coin = abi.decode(data, (address));
            if (coin == address(0)) break;
            if (coin == tokenIn)  i = int128(int256(k));
            if (coin == tokenOut) j = int128(int256(k));
        }
    }
    function _findUnderlyingIndices(
        address pool,
        address tokenIn,
        address tokenOut
    ) internal view returns (int128 i, int128 j) {
        i = -1;
        j = -1;
        {
            (bool ok, bytes memory data) = pool.staticcall(
                abi.encodeWithSignature("underlying_coins(uint256)", uint256(0))
            );
            if (ok) {
                address coin0 = abi.decode(data, (address));
                if (coin0 != address(0)) {
                    for (int128 k = 0; k < 4; k++) {
                        (bool okk, bytes memory dk) = pool.staticcall(
                            abi.encodeWithSignature("underlying_coins(uint256)", uint256(uint128(k)))
                        );
                        if (!okk) break;
                        address coin = abi.decode(dk, (address));
                        if (coin == address(0)) break;
                        if (coin == tokenIn)  i = k;
                        if (coin == tokenOut) j = k;
                    }
                    return (i, j);
                }
            }
        }
        {
            (bool ok, bytes memory data) = pool.staticcall(
                abi.encodeWithSignature("underlying_coins(int128)", int128(0))
            );
            if (ok) {
                address coin0 = abi.decode(data, (address));
                if (coin0 != address(0)) {
                    for (int128 k = 0; k < 4; k++) {
                        (bool okk, bytes memory dk) = pool.staticcall(
                            abi.encodeWithSignature("underlying_coins(int128)", k)
                        );
                        if (!okk) break;
                        address coin = abi.decode(dk, (address));
                        if (coin == address(0)) break;
                        if (coin == tokenIn)  i = k;
                        if (coin == tokenOut) j = k;
                    }
                    return (i, j);
                }
            }
        }
        {
            address[2] memory factories = [
                0x0959158b6040D32d04c301A72CBFD6b39E21c9AE,
                0xB9fC157394Af804a3578134A6585C0dc9cc990d4
            ];
            bytes memory callData = abi.encodeWithSignature("get_underlying_coins(address)", pool);
            for (uint256 f = 0; f < 2; f++) {
                (bool ok, bytes memory data) = factories[f].staticcall(callData);
                if (!ok) continue;
                address[8] memory coins = abi.decode(data, (address[8]));
                if (coins[0] == address(0)) continue;
                for (int128 k = 0; k < 8; k++) {
                    address coin = coins[uint256(uint128(k))];
                    if (coin == address(0)) break;
                    if (coin == tokenIn)  i = k;
                    if (coin == tokenOut) j = k;
                }
                if (i >= 0 && j >= 0) return (i, j);
            }
        }
    }
}