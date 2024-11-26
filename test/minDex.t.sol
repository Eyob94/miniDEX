// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DEX} from "../src/Dex.sol";
import {TestToken} from "../src/TestToken.sol";

contract DexTest is Test {
    DEX dex;
    TestToken tokenA;
    TestToken tokenB;
    address user;

    function setUp() public {
        tokenA = new TestToken("tokenA", "TKA");
        tokenB = new TestToken("tokenB", "TKB");

        // Deploy the DEX
        dex = new DEX(address(tokenA), address(tokenB));

        user = address(0x13);

        tokenA.transfer(user, 100 * 10 ** 18);
        tokenB.transfer(user, 100 * 10 ** 18);

        vm.label(address(tokenA), "Token A");
        vm.label(address(tokenB), "Token B");
        vm.label(user, "User");
    }

    function testAddLiquidity() public {
        vm.startPrank(user);

        // Approve tokens for the DEX contract
        tokenA.approve(address(dex), 50 * 10 ** 18);
        tokenB.approve(address(dex), 50 * 10 ** 18);

        // Add liquidity
        dex.addLiquidity(50 * 10 ** 18, 50 * 10 ** 18);

        // Check that the reserves are updated correctly
        assertEq(dex.reserveA(), 50 * 10 ** 18);
        assertEq(dex.reserveB(), 50 * 10 ** 18);

        vm.stopPrank(); // Stop impersonation
    }

    function testSwapTokens() public {
        vm.startPrank(user);

        // Approve tokens for the DEX contract
        tokenA.approve(address(dex), 100 * 10 ** 18);
        tokenB.approve(address(dex), 100 * 10 ** 18);

        // Add initial liquidity
        dex.addLiquidity(50 * 10 ** 18, 50 * 10 ** 18);

        // Perform a swap
        dex.swap(address(tokenA), 10 * 10 ** 18);

        // Check reserves
        uint256 expectedReserveA = dex.reserveA(); // 50 + 10 = 60
        uint256 expectedReserveB = dex.reserveB(); // Expected value calculated from AMM formula

        assertEq(dex.reserveA(), 60 * 10 ** 18);
        assertEq(dex.reserveB(), expectedReserveB);

        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        vm.startPrank(user);

        tokenA.approve(address(dex), 100 * 10 ** 18);
        tokenB.approve(address(dex), 100 * 10 ** 18);

        dex.addLiquidity(100 * 10 ** 18, 100 * 10 ** 18);

        assertEq(dex.reserveA(), 100 * 10 ** 18);
        assertEq(dex.reserveB(), 100 * 10 ** 18);

        dex.removeLiquidity(50);

        assertEq(dex.reserveA(), 50 * 10 ** 18);
        assertEq(dex.reserveB(), 50 * 10 ** 18);
    }
}
