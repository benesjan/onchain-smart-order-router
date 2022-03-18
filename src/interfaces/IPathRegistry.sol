// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity ^0.8.0;

/**
 * @title A contract allowing for registration of paths and token swapping on Uniswap v2 and v3.
 * @author Jan Benes (@benesjan on Github and Telegram)
 * @notice You can use this contract to register a path and then to swap tokens using this path.
 * @dev A smart contract which has 2 functions:
 *      1. A registration and a quality verification of Uniswap v2 and v3 paths.
 *      2. Swapping tokens using the registered paths. A path is selected based on the input and output token addresses
 *         and the amount of input token to swap.
 */
interface IPathRegistry {
    struct SubPathV2 {
        uint256 percent; // No packing here so I am using uint256 to avoid runtime conversion from uint8 to uint256
        address[] path;
    }

    struct SubPathV3 {
        uint256 percent;
        bytes path;
    }

    struct Path {
        uint256 amount; // Amount at which the path starts being valid
        uint256 next;
        SubPathV2[] subPathsV2;
        SubPathV3[] subPathsV3;
    }

    /**
     * @notice A function which verifies and registers a new path.
     * @param newPath A path to register.
     * @dev Reverts when the new path doesn't have a better quote than the previous path at newPath.amount.
     */
    function registerPath(Path calldata newPath) external;

    /**
     * @notice Selects a path based on `tokenIn`, `tokenOut` and `amountIn` and swaps `amountIn` of `tokenIn` for
     * as much as possible of `tokenOut` along the selected path.
     * @param tokenIn An address of to sell.
     * @param tokenOut An address of the token to buy.
     * @param amountIn An amount of `tokenIn` to swap.
     * @param amountOutMin Minimum amount of tokenOut to receive. Inactive when set to 0.
     * @return amountOut The amount of token received.
     * @dev Reverts when path is not found.
     */
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin
    ) external payable returns (uint256 amountOut);
}
