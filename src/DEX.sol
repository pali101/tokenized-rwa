// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DEX is Ownable {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveTokenA;
    uint256 public reserveTokenB;

    event Swap(address indexed user, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);
    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed user, uint256 amountA, uint256 amountB);

    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        reserveTokenA += amountA;
        reserveTokenB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(reserveTokenA >= amountA && reserveTokenB >= amountB, "Not enough liquidity");

        reserveTokenA -= amountA;
        reserveTokenB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    function swap(address tokenIn, uint256 amountIn) external {
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token");

        bool isTokenA = tokenIn == address(tokenA);
        IERC20 inputToken = isTokenA ? tokenA : tokenB;
        IERC20 outputToken = isTokenA ? tokenB : tokenA;
        uint256 inputReserve = isTokenA ? reserveTokenA : reserveTokenB;
        uint256 outputReserve = isTokenA ? reserveTokenB : reserveTokenA;

        inputToken.transferFrom(msg.sender, address(this), amountIn);
        uint256 amountOut = getAmountOut(amountIn, inputReserve, outputReserve);
        require(amountOut > 0, "Insufficient output amount");

        outputToken.transfer(msg.sender, amountOut);

        if (isTokenA) {
            reserveTokenA += amountIn;
            reserveTokenB -= amountOut;
        } else {
            reserveTokenB += amountIn;
            reserveTokenA -= amountOut;
        }

        emit Swap(msg.sender, tokenIn, amountIn, address(outputToken), amountOut);
    }

    function getAmountOut(uint256 amountIn, uint256 inputReserve, uint256 outputReserve)
        public
        pure
        returns (uint256)
    {
        uint256 amountInWithFee = amountIn * 997; // 0.3% fee
        return (amountInWithFee * outputReserve) / ((inputReserve * 1000) + amountInWithFee);
    }
}
