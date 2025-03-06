// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/DEX.sol";
import "../src/RWAStableCoin.sol";
import "./MockUSDT.sol";

contract DEXTest is Test {
    DEX public dex;
    RWAToken rwaToken;
    RWAStableCoin public rwaStableCoin;
    MockUSDT public usdt;
    address public owner = address(1);
    address public investor = address(2);
    uint256 constant P1_VALUATION = 1000 * 1e20;
    uint256 constant P1_TOTAL_SHARES = 1000;
    uint256 public constant COLLATERAL_RATIO = 120;

    function setUp() public {
        vm.startPrank(owner);

        rwaToken = new RWAToken();
        rwaStableCoin = new RWAStableCoin(address(rwaToken));

        rwaToken.addWhitelistedInvestor(owner);
        rwaToken.addWhitelistedInvestor(investor);
        rwaToken.addWhitelistedInvestor(address(rwaStableCoin));

        // mint property and transfer to investor
        rwaToken.mintProperty(P1_VALUATION, P1_TOTAL_SHARES);
        rwaToken.safeTransferFrom(owner, investor, 0, P1_TOTAL_SHARES, "");
        vm.stopPrank();

        vm.startPrank(investor);
        // provide smart contract permisiion to transfer asset on investors behalf
        rwaToken.setApprovalForAll(address(rwaStableCoin), true);

        rwaStableCoin.mintStableCoin(0, P1_TOTAL_SHARES);
        vm.stopPrank();

        vm.startPrank(owner);
        usdt = new MockUSDT();
        dex = new DEX(address(rwaStableCoin), address(usdt));

        usdt.mint(investor, 1000 * 1e18);
        vm.stopPrank();

        vm.startPrank(investor);
        rwaStableCoin.approve(address(dex), type(uint256).max);
        usdt.approve(address(dex), type(uint256).max);
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(investor);
        dex.addLiquidity(1e15, 1e15);
        vm.stopPrank();

        assertEq(dex.reserveTokenA(), 1e15);
        assertEq(dex.reserveTokenB(), 1e15);
    }

    function testSwapTokens() public {
        // ensure liquidity exists
        testAddLiquidity();

        uint256 balanceBeforeSwap = usdt.balanceOf(investor);

        vm.startPrank(investor);
        dex.swap(address(rwaStableCoin), 1e10);
        vm.stopPrank();

        uint256 expectedOut = dex.getAmountOut(1e10, 1e15, 1e15);
        assertEq(usdt.balanceOf(investor) - balanceBeforeSwap, expectedOut, "Incorrect amount of output tokens sent");
    }

    function testRemoveLiquidity() public {
        testAddLiquidity();

        vm.startPrank(owner);
        dex.removeLiquidity(1e12, 0);
        vm.stopPrank();

        assertEq(dex.reserveTokenA(), 1e15 - 1e12, "Incorrect reserve for token A");
        assertEq(dex.reserveTokenB(), 1e15, "Incorrect reserve for token B");
    }
}
