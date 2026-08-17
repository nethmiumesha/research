pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/ITokenExchange.sol";
import "../interfaces/IConnector.sol";
contract Usdc2AUsdcTokenExchange is ITokenExchange {
    IConnector public aaveConnector;
    IERC20 public usdcToken;
    IERC20 public aUsdcToken;
    uint256 usdcDenominator;
    uint256 aUsdcDenominator;
    constructor(
        address _aaveConnector,
        address _usdcToken,
        address _aUsdcToken
    ) {
        require(_aaveConnector != address(0), "Zero address not allowed");
        require(_usdcToken != address(0), "Zero address not allowed");
        require(_aUsdcToken != address(0), "Zero address not allowed");
        aaveConnector = IConnector(_aaveConnector);
        usdcToken = IERC20(_usdcToken);
        aUsdcToken = IERC20(_aUsdcToken);
        usdcDenominator = 10 ** (18 - IERC20Metadata(address(usdcToken)).decimals());
        aUsdcDenominator = 10 ** (18 - IERC20Metadata(address(aUsdcToken)).decimals());
    }
    function exchange(
        address spender,
        IERC20 from,
        address receiver,
        IERC20 to,
        uint256 amount
    ) external override {
        require(
            (from == usdcToken && to == aUsdcToken) || (from == aUsdcToken && to == usdcToken),
            "Usdc2AUsdcTokenExchange: Some token not compatible"
        );
        if (amount == 0) {
            uint256 fromBalance = from.balanceOf(address(this));
            if (fromBalance > 0) {
                from.transfer(spender, fromBalance);
            }
            return;
        }
        if (from == usdcToken && to == aUsdcToken) {
            amount = amount / usdcDenominator;
            uint256 balance = usdcToken.balanceOf(address(this));
            if (amount == 0) {
                if (balance > 0) {
                    usdcToken.transfer(spender, balance);
                }
                return;
            }
            require(
                balance >= amount,
                "Usdc2AUsdcTokenExchange: Not enough usdcToken"
            );
            usdcToken.transfer(address(aaveConnector), amount);
            aaveConnector.stake(address(usdcToken), amount, receiver);
            uint256 unusedBalance = usdcToken.balanceOf(address(this));
            if (unusedBalance > 0) {
                usdcToken.transfer(spender, unusedBalance);
            }
        } else {
            amount = amount / aUsdcDenominator;
            uint256 balance = aUsdcToken.balanceOf(address(this));
            if (amount == 0) {
                if (balance > 0) {
                    aUsdcToken.transfer(spender, balance);
                }
                return;
            }
            if (balance + 1 == amount) {
                amount = amount - 1;
            }
            require(
                balance >= amount,
                "Usdc2AUsdcTokenExchange: Not enough aUsdcToken"
            );
            aUsdcToken.transfer(address(aaveConnector), amount);
            uint256 onAaveConnectorBalance = aUsdcToken.balanceOf(address(aaveConnector));
            if (onAaveConnectorBalance < amount) {
                amount = onAaveConnectorBalance;
            }
            uint256 withdrewAmount = aaveConnector.unstake(address(usdcToken), amount, receiver);
            uint256 unusedBalance = aUsdcToken.balanceOf(address(this));
            if (unusedBalance > 0) {
                aUsdcToken.transfer(spender, unusedBalance);
            }
        }
    }
}