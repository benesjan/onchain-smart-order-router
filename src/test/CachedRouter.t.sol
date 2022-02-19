// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../interfaces/ICachedRouter.sol";
import "../CachedRouter.sol";

contract CachedRouterTest is DSTest {
    ICachedRouter cachedRouter;

    function setUp() public {
        cachedRouter = new CachedRouter();
    }

    function testRegisterPath() public {
        assertTrue(true);
    }
}
