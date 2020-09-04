// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./mixins/Initializable.sol";
import "./interfaces/IPriceFeed.sol";
import "./interfaces/IMakerPriceFeed.sol";
import "./libraries/UniswapV2Library.sol";

contract PriceFeed is Initializable, IPriceFeed {
    using SafeMath for uint256;

    address internal _uniswapFactory;
    address internal _weth;
    address internal _makerPriceFeed;

    function initialize(address makerPriceFeed) public initializer {
        _makerPriceFeed = makerPriceFeed;

        IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapFactory = router.factory();
        _weth = router.WETH();
    }

    function ethPriceInUSD(uint256 amount) public override view returns (uint256) {
        uint256 price = uint256(IMakerPriceFeed(_makerPriceFeed).read());
        return price.mul(amount).div(10**18);
    }

    function erc20PriceInETH(address token, uint256 amount) public override view returns (uint256) {
        (uint256 reserve0, uint256 reserve1) = UniswapV2Library.getReserves(
            _uniswapFactory,
            token,
            _weth
        );
        if (reserve0 > 0 && reserve1 > 0) {
            return UniswapV2Library.quote(amount, reserve0, reserve1);
        }
        return 0;
    }

    function erc20PriceInUSD(address token, uint256 amount) public override view returns (uint256) {
        uint256 ethPrice = ethPriceInUSD(10**18);
        uint256 erc20Price = erc20PriceInETH(token, amount);
        return erc20Price == 0 ? 0 : ethPrice.mul(erc20Price).div(10**18);
    }
}
