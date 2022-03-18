// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {stdCheats} from "forge-std/stdlib.sol";

import "./TestPaths.sol";
import "../PathRegistry.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IERC20.sol";

contract PathRegistryTest is DSTest, stdCheats, TestPaths {
    PathRegistry private pathRegistry;

    function setUp() public {
        pathRegistry = new PathRegistry();
    }

    function testRegisterPathWith0Amount() public {
        // Test the "if" execution path
        try pathRegistry.registerPath(getPath1(0)) {
            assertTrue(false, "registerPath(..) has to revert when initializing a path with zero amount.");
        } catch Error(string memory reason) {
            assertEq(reason, "AS");
        }

        // Test the "else if" execution path
        pathRegistry.registerPath(getPath1(1e18));
        try pathRegistry.registerPath(getPath1(0)) {
            assertTrue(false, "registerPath(..) has to revert when initializing a path with zero amount.");
        } catch Error(string memory reason) {
            assertEq(reason, "AS");
        }

        // "else" execution path can't be reached with a path with 0 amount
    }

    function testRegisterPath() public {
        pathRegistry.registerPath(getPath0(1e16));
        pathRegistry.registerPath(getPath1(3e17));
        pathRegistry.registerPath(getPath2(4e19));
        pathRegistry.registerPath(getPath3(32e19));

        (uint256 amount1, uint256 next1) = pathRegistry.allPaths(1);
        assertEq(amount1, 1e16);
        assertEq(next1, 2);

        (uint256 amount2, uint256 next2) = pathRegistry.allPaths(2);
        assertEq(amount2, 3e17);
        assertEq(next2, 3);

        (uint256 amount3, uint256 next3) = pathRegistry.allPaths(3);
        assertEq(amount3, 4e19);
        assertEq(next3, 4);

        (uint256 amount4, uint256 next4) = pathRegistry.allPaths(4);
        assertEq(amount4, 32e19);
        assertEq(next4, 0);
    }

    /**
     * @notice A test testing whether a path gets replaced by a new one (instead of inserting the new one before
     * the original one). This should happen when the new path is better at both newPath.amount and oldPath.amount
     */
    function testFirstPathReplacement() public {
        pathRegistry.registerPath(getPath3(1e17));
        pathRegistry.registerPath(getPath0(1e16));

        (uint256 amount1, uint256 next1) = pathRegistry.allPaths(1);
        assertEq(amount1, 1e16);
        assertEq(next1, 0);
    }

    function testFailRegisterBrokenPathUniV2() public {
        pathRegistry.registerPath(getPath1(0));
        pathRegistry.registerPath(getBrokenPathUniV2(1e18));
    }

    function testFailRegisterBrokenPathUniV3() public {
        pathRegistry.registerPath(getPath1(0));
        pathRegistry.registerPath(getBrokenPathUniV3(1e18));
    }

    function testPathPruning() public {
        // TODO
    }

    function testSwapFuzz(uint96 amountIn) public {
        pathRegistry.registerPath(getPath0(1e16));
        pathRegistry.registerPath(getPath1(3e17));
        pathRegistry.registerPath(getPath2(4e19));
        pathRegistry.registerPath(getPath3(32e19));

        // give amountIn WEI to address(1337) and call the next function with msg.origin = address(1337)
        hoax(address(1337), amountIn);

        if (amountIn == 0) {
            try pathRegistry.swap{value: amountIn}(WETH, LUSD, amountIn, 0) {
                assertTrue(false, "swap(..) should revert with amountIn = 0.");
            } catch Error(string memory reason) {
                assertEq(reason, "INSUFFICIENT_INPUT_AMOUNT");
            }
        } else {
            pathRegistry.swap{value: amountIn}(WETH, LUSD, amountIn, 0);
        }
    }

    function testSwapERC20() public {
        pathRegistry.registerPath(getPath1(3e17));
        pathRegistry.registerPath(getPath5(1e22));

        // give 1 ETH to address(1337) and call the next function with msg.origin = address(1337)
        uint256 amountIn = 1e18;

        startHoax(address(1337), amountIn);
        IWETH(WETH).deposit{value: amountIn}();
        IERC20(WETH).approve(address(pathRegistry), amountIn);

        pathRegistry.swap(WETH, LUSD, amountIn, 0);
        assertGt(IERC20(LUSD).balanceOf(address(1337)), 0);
    }

    function testSwapOnlyPathWithLargerAmountAvailable() public {
        pathRegistry.registerPath(getPath5(1e22));

        // give 1 ETH to address(1337) and call the next function with msg.origin = address(1337)
        uint256 amountIn = 1e18;

        hoax(address(1337), amountIn);
        pathRegistry.swap{value: amountIn}(WETH, LUSD, amountIn, 0);
        assertGt(IERC20(LUSD).balanceOf(address(1337)), 0);
    }
}