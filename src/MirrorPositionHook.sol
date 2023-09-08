// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {
    PoolId,
    PoolIdLibrary
} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {
    IPoolManager
} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Position} from "@uniswap/v4-core/contracts/libraries/Position.sol";

contract MirrorPositionHook is BaseHook {
    using PoolIdLibrary for IPoolManager.PoolKey;

    address public TokenOwnerAddress;

    constructor(IPoolManager _poolManager, address _tokenOwnerAddress)
        BaseHook(_poolManager)
    {
        TokenOwnerAddress = _tokenOwnerAddress;
    }

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
        require(sender == TokenOwnerAddress, "Sender is not the token owner");

        // Fetch the mirrored position directly from IPoolManager
        IPoolManager.Position memory userPosition =
            _poolManager.getPosition(
                key,
                TokenOwnerAddress,
                params.tickLower,
                params.tickUpper
            );

        // Creating a mirrored position
        IPoolManager.Position memory mirroredPosition =
            IPoolManager.Position({
                liquidity: userPosition.liquidity,
                tickLower: userPosition.tickLower,
                tickUpper: userPosition.tickUpper
            });

        // Add the mirrored position to the pool
        _poolManager.addPosition(key, TokenOwnerAddress, mirroredPosition);

        return BaseHook.beforeModifyPosition.selector;
    }

    function afterModifyPosition(
        address sender,
        IPoolManager.PoolKey memory key,
        IPoolManager.ModifyPositionParams calldata params,
        BalanceDelta calldata balanceDelta
    ) external override returns (bytes4) {
        // Only perform the action if the sender is the token owner/platform
        require(sender == TokenOwnerAddress, "Sender is not the token owner");

        // Mirror the changes made to the user's position in the mirrored position
        IPoolManager.Position memory userPosition =
            _poolManager.getPosition(
                key,
                TokenOwnerAddress,
                params.tickLower,
                params.tickUpper
            );

        // Mirroring the position changes
        IPoolManager.Position memory mirroredPosition =
            IPoolManager.Position({
                liquidity: userPosition.liquidity,
                tickLower: userPosition.tickLower,
                tickUpper: userPosition.tickUpper
            });

        // Update the mirrored position in the pool
        _poolManager.updatePosition(key, TokenOwnerAddress, mirroredPosition);

        return BaseHook.afterModifyPosition.selector;
    }
}
