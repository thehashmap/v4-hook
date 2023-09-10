// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

import {
    IPoolManager
} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {
    PoolId,
    PoolIdLibrary
} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";

contract MirrorPositionHook is BaseHook {
    using PoolIdLibrary for IPoolManager.PoolKey;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return
            Hooks.Calls({
                beforeInitialize: false,
                afterInitialize: false,
                beforeModifyPosition: true,
                afterModifyPosition: true,
                beforeSwap: false,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false
            });
    }

    function beforeModifyPosition(
        address sender,
        IPoolManager.PoolKey memory key,
        IPoolManager.ModifyPositionParams calldata params
    ) external override returns (bytes4) {
        // Only perform the action if the sender is the token owner/platform
        if (sender == TokenOwnerAddress) {
            // Create a mirrored position with the same parameters as the user's position
            IPoolManager.Position memory userPosition =
                poolManager.getPosition(sender, key);

            // Creating a mirrored position
            IPoolManager.Position memory mirroredPosition =
                IPoolManager.Position({
                    liquidity: userPosition.liquidity,
                    tickLower: userPosition.tickLower,
                    tickUpper: userPosition.tickUpper
                });

            // Add the mirrored position to the pool
            poolManager.addPosition(sender, key, mirroredPosition);
        }

        return BaseHook.beforeModifyPosition.selector;
    }

    function afterModifyPosition(
        address sender,
        IPoolManager.PoolKey memory key,
        IPoolManager.ModifyPositionParams calldata params,
        BalanceDelta calldata balanceDelta
    ) external override returns (bytes4) {
        // Only perform the action if the sender is the token owner/platform
        if (sender == TokenOwnerAddress) {
            // Mirror the changes made to the user's position in the mirrored position
            IPoolManager.Position memory userPosition =
                poolManager.getPosition(sender, key);

            // Mirroring the position changes
            IPoolManager.Position memory mirroredPosition =
                IPoolManager.Position({
                    liquidity: userPosition.liquidity,
                    tickLower: userPosition.tickLower,
                    tickUpper: userPosition.tickUpper
                });

            // Update the mirrored position in the pool
            poolManager.updatePosition(sender, key, mirroredPosition);
        }

        return BaseHook.afterModifyPosition.selector;
    }
}
