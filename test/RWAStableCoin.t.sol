// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/RWAStableCoin.sol";

contract RWAStableCoinTest is Test {
    RWAToken rwaToken;
    RWAStableCoin stableCoin;
    address owner = address(0x1);
    address investor1 = address(0x2);
    address investor2 = address(0x3);
    uint256 P1Valuation = 1_000_000;
    uint256 P1TotalShares = 1000;
    uint256 P2Valuation = 100_000;
    uint256 P2TotalShares = 500;

    uint256 public constant COLLATERAL_RATIO = 120;

    function setUp() public {
        vm.startPrank(owner);

        rwaToken = new RWAToken();
        stableCoin = new RWAStableCoin(address(rwaToken));

        rwaToken.addWhitelistedInvestor(owner);
        rwaToken.addWhitelistedInvestor(investor1);
        rwaToken.addWhitelistedInvestor(investor2);
        rwaToken.addWhitelistedInvestor(address(stableCoin));

        rwaToken.mintProperty(P1Valuation, P1TotalShares);
        rwaToken.mintProperty(P2Valuation, P2TotalShares);

        // transfer half shares of Property 1 to investor1
        rwaToken.safeTransferFrom(owner, investor1, 0, P1TotalShares / 2, "");
        // owner transfer all shares of Property 2 to investor 2
        rwaToken.safeTransferFrom(owner, investor2, 1, P2TotalShares, "");

        vm.stopPrank();
    }

    function testMintStableCoin() public {
        vm.startPrank(investor1);

        uint256 initialBalance = stableCoin.balanceOf(investor1);
        uint256 initialCollateral = stableCoin.collateralLocked(0);

        require(rwaToken.balanceOf(investor1, 0) >= P1TotalShares / 2, "Investor should have sufficient RWA tokens");

        // Give approval to move RWA Token
        rwaToken.setApprovalForAll(address(stableCoin), true);

        stableCoin.mintStableCoin(0, P1TotalShares / 2);

        uint256 newBalance = stableCoin.balanceOf(investor1);
        uint256 newCollateral = stableCoin.collateralLocked(0);

        assertEq(
            newBalance,
            initialBalance + (P1Valuation * P1TotalShares) / (2 * P1TotalShares * COLLATERAL_RATIO),
            "Incorrect stablecoin mint amount"
        );
        assertEq(newCollateral, initialCollateral + (P1TotalShares / 2), "Collateral not locked correctly");

        vm.stopPrank();
    }

    function testRedeemStableCoin() public {
        vm.startPrank(investor1);

        // uint256 initialBalance = stableCoin.balanceOf(investor1);
        require(rwaToken.balanceOf(investor1, 0) >= P1TotalShares / 2, "Investor should have sufficient RWA tokens");
        rwaToken.setApprovalForAll(address(stableCoin), true);
        stableCoin.mintStableCoin(0, P1TotalShares / 2);
        uint256 stableCoinBalance = stableCoin.balanceOf(investor1);

        stableCoin.redeemStableCoin(0, stableCoinBalance);
        assertEq(stableCoin.balanceOf(investor1), 0, "Stablecoin balance should be 0 after redemption");

        // allow a 1% error rate
        assertCloseEnough(rwaToken.balanceOf(investor1, 0), P1TotalShares / 2, 100);
    }

    function assertCloseEnough(uint256 actual, uint256 expected, uint256 tolerance) internal pure {
        uint256 lowerBound = (expected * (10000 - tolerance)) / 10000;
        assertTrue(actual >= lowerBound, "Value not within tolerance range");
    }
}
