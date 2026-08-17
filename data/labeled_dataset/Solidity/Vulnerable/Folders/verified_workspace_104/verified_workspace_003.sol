pragma solidity 0.8.6;
import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastBytes32Bytes6.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20Metadata.sol";
import "@yield-protocol/vault-interfaces/IOracle.sol";
import "../../constants/Constants.sol";
import "./CTokenInterface.sol";
contract CTokenMultiOracle is IOracle, AccessControl, Constants {
    using CastBytes32Bytes6 for bytes32;
    event SourceSet(bytes6 indexed baseId, bytes6 indexed quoteId, CTokenInterface indexed cToken);
    struct Source {
        CTokenInterface source;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        bool inverse;
    }
    mapping(bytes6 => mapping(bytes6 => Source)) public sources;
    function setSource(bytes6 cTokenId, bytes6 underlyingId, CTokenInterface cToken)
        external auth
    {
        IERC20Metadata underlying = IERC20Metadata(cToken.underlying());
        uint8 underlyingDecimals = underlying.decimals();
        uint8 cTokenDecimals = underlyingDecimals + 10;
        sources[cTokenId][underlyingId] = Source({
            source: cToken,
            baseDecimals: cTokenDecimals,
            quoteDecimals: underlyingDecimals,
            inverse: false
        });
        emit SourceSet(cTokenId, underlyingId, cToken);
        sources[underlyingId][cTokenId] = Source({
            source: cToken,
            baseDecimals: underlyingDecimals,
            quoteDecimals: cTokenDecimals,
            inverse: true
        });
        emit SourceSet(underlyingId, cTokenId, cToken);
    }
    function peek(bytes32 base, bytes32 quote, uint256 amountBase)
        external view virtual override
        returns (uint256 amountQuote, uint256 updateTime)
    {
        Source memory source = sources[base.b6()][quote.b6()];
        require (source.source != CTokenInterface(address(0)), "Source not found");
        uint256 price = source.source.exchangeRateStored();
        require(price > 0, "Compound price is zero");
        if (source.inverse == true) {
            amountQuote = amountBase * (10 ** source.quoteDecimals) / uint(price);
        } else {
            amountQuote = uint(price) * amountBase / (10 ** source.baseDecimals);
        }
        updateTime = block.timestamp;
    }
    function get(bytes32 base, bytes32 quote, uint256 amountBase)
        external virtual override
        returns (uint256 amountQuote, uint256 updateTime)
    {
        Source memory source = sources[base.b6()][quote.b6()];
        require (source.source != CTokenInterface(address(0)), "Source not found");
        uint256 price = source.source.exchangeRateCurrent();
        require(price > 0, "Compound price is zero");
        if (source.inverse == true) {
            amountQuote = amountBase * (10 ** source.quoteDecimals) / uint(price);
        } else {
            amountQuote = amountBase * uint(price) / (10 ** source.baseDecimals);
        }
        updateTime = block.timestamp;
    }
}