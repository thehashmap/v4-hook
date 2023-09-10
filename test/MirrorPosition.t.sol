// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MirrorPositionHook} from "../src/MirrorPositionHook.sol";

contract MirrorPositionHookTest {
    MirrorPositionHook private hook;
    MockPoolManager private poolManager;
    address private tokenOwner = address(0x123);

    function beforeEach() public {
        poolManager = new MockPoolManager();
        hook = new MirrorPositionHook(address(poolManager), tokenOwner);
    }

    function testBeforeModifyPosition() public {
        // Prepare test data
        Position memory userPosition = Position(100, 100, 200);
        bytes32 poolId =
            bytes32(uint256(keccak256(abi.encodePacked(tokenOwner))));

        // Call the hook function
        hook.beforeModifyPosition(
            address(this),
            IPoolManager.PoolKey(
                address(0xAAA),
                address(0xBBB),
                3000,
                60,
                address(0xCCC)
            ),
            IPoolManager.ModifyPositionParams(100, 200, 100, address(this))
        );

        // Check if the mirrored position was added correctly
        Position memory mirroredPosition =
            poolManager.getPosition(tokenOwner, poolId, 100, 200);

        Assert.equal(
            mirroredPosition.liquidity,
            userPosition.liquidity,
            "Mirrored position liquidity not added correctly"
        );
        Assert.equal(
            mirroredPosition.tickLower,
            userPosition.tickLower,
            "Mirrored position tickLower not added correctly"
        );
        Assert.equal(
            mirroredPosition.tickUpper,
            userPosition.tickUpper,
            "Mirrored position tickUpper not added correctly"
        );
    }

    function testAfterModifyPosition() public {
        // Prepare test data
        Position memory updatedUserPosition = Position(200, 50, 150);
        bytes32 poolId =
            bytes32(uint256(keccak256(abi.encodePacked(tokenOwner))));

        // Update the user's position in the pool manager
        poolManager
            .positions(tokenOwner, poolId)
            .liquidity = updatedUserPosition.liquidity;
        poolManager
            .positions(tokenOwner, poolId)
            .tickLower = updatedUserPosition.tickLower;
        poolManager
            .positions(tokenOwner, poolId)
            .tickUpper = updatedUserPosition.tickUpper;

        // Call the hook function
        hook.afterModifyPosition(
            address(this),
            IPoolManager.PoolKey(
                address(0xAAA),
                address(0xBBB),
                3000,
                60,
                address(0xCCC)
            ),
            IPoolManager.ModifyPositionParams(50, 150, 100, address(this)),
            BalanceDelta(100, 50, 150, 0, 0)
        );

        // Check if the mirrored position was updated correctly
        Position memory mirroredPosition =
            poolManager.getPosition(tokenOwner, poolId, 50, 150);

        Assert.equal(
            mirroredPosition.liquidity,
            updatedUserPosition.liquidity,
            "Mirrored position liquidity not updated correctly"
        );
        Assert.equal(
            mirroredPosition.tickLower,
            updatedUserPosition.tickLower,
            "Mirrored position tickLower not updated correctly"
        );
        Assert.equal(
            mirroredPosition.tickUpper,
            updatedUserPosition.tickUpper,
            "Mirrored position tickUpper not updated correctly"
        );
    }
}
