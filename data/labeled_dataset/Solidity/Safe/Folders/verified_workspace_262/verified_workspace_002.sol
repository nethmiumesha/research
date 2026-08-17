pragma solidity 0.7.6;
pragma abicoder v2;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '../../interfaces/actions/IMint.sol';
import '../../interfaces/actions/IZapIn.sol';
import '../../interfaces/IPositionManager.sol';
import '../../interfaces/IPositionManagerFactory.sol';
import '../../interfaces/IUniswapAddressHolder.sol';
contract DepositRecipes {
    IUniswapAddressHolder uniswapAddressHolder;
    IPositionManagerFactory positionManagerFactory;
    constructor(address _uniswapAddressHolder, address _positionManagerFactory) {
        uniswapAddressHolder = IUniswapAddressHolder(_uniswapAddressHolder);
        positionManagerFactory = IPositionManagerFactory(_positionManagerFactory);
    }
    event PositionDeposited(address indexed positionManager, address from, uint256 tokenId);
    function depositUniNft(uint256[] calldata tokenIds) external {
        address positionManagerAddress = positionManagerFactory.userToPositionManager(msg.sender);
        for (uint32 i = 0; i < tokenIds.length; i++) {
            INonfungiblePositionManager(uniswapAddressHolder.nonfungiblePositionManagerAddress()).safeTransferFrom(
                msg.sender,
                positionManagerAddress,
                tokenIds[i],
                '0x0'
            );
            IPositionManager(positionManagerAddress).middlewareDeposit(tokenIds[i]);
            emit PositionDeposited(positionManagerAddress, msg.sender, tokenIds[i]);
        }
    }
    function mintAndDeposit(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external returns (uint256 tokenId) {
        address positionManagerAddress = positionManagerFactory.userToPositionManager(msg.sender);
        IERC20(token0).transferFrom(msg.sender, positionManagerAddress, amount0Desired);
        IERC20(token1).transferFrom(msg.sender, positionManagerAddress, amount1Desired);
        (tokenId, , ) = IMint(positionManagerAddress).mint(
            IMint.MintInput(token0, token1, fee, tickLower, tickUpper, amount0Desired, amount1Desired)
        );
    }
    function zapInUniNft(
        address tokenIn,
        uint256 amountIn,
        address token0,
        address token1,
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) external returns (uint256 tokenId) {
        address positionManagerAddress = positionManagerFactory.userToPositionManager(msg.sender);
        (tokenId) = IZapIn(positionManagerAddress).zapIn(tokenIn, amountIn, token0, token1, tickLower, tickUpper, fee);
    }
}