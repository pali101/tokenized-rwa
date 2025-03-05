// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/RWAToken.sol";

contract RWATokenTest is Test {
    RWAToken token;
    address owner = address(0x1);
    address investor1 = address(0x2);
    address investor2 = address(0x3);

    function setUp() public {
        vm.prank(owner);
        token = new RWAToken();

        vm.prank(owner);
        token.addWhitelistedInvestor(owner);

        vm.prank(owner);
        token.addWhitelistedInvestor(investor1);

        vm.prank(owner);
        token.addWhitelistedInvestor(investor2);
    }

    function testMintProperty() public {
        vm.prank(owner);
        uint256 valuation = 100000;
        uint256 shares = 1000;
        token.mintProperty(valuation, shares);

        (uint256 id, uint256 storedValuation, uint256 storedShares) = token.properties(0);
        assertEq(id, 0);
        assertEq(storedValuation, valuation);
        assertEq(storedShares, shares);
        assertEq(token.balanceOf(owner, 0), shares);
    }

    function testMintPropertyByNonOwner() public {
        vm.prank(investor1);
        vm.expectRevert();
        token.mintProperty(100000, 1000);
    }

    function testTransfer() public {
        vm.prank(owner);
        token.mintProperty(100000, 1000);

        vm.prank(owner);
        token.safeTransferFrom(owner, investor1, 0, 100, "");

        assertEq(token.balanceOf(investor1, 0), 100);
        assertEq(token.balanceOf(owner, 0), 900);
    }

    function testTransferToNonWhitelisted() public {
        address nonWhitelisted = address(0x4);
        vm.prank(owner);
        token.mintProperty(100000, 1000);

        vm.prank(owner);
        vm.expectRevert();
        token.safeTransferFrom(owner, nonWhitelisted, 0, 100, "");
    }

    function testUpdateValuation() public {
        vm.prank(owner);
        token.mintProperty(100000, 1000);

        vm.prank(owner);
        token.updateValuation(0, 120000);

        (, uint256 updatedValuation,) = token.properties(0);
        assertEq(updatedValuation, 120000);
    }

    function testUpdateValuationByNonOwner() public {
        vm.prank(owner);
        token.mintProperty(100000, 1000);

        vm.prank(investor1);
        vm.expectRevert();
        token.updateValuation(0, 120000);
    }

    function testWhitelistInvestor() public {
        address newInvestor = address(0x5);

        vm.prank(owner);
        token.addWhitelistedInvestor(newInvestor);

        assertEq(token.whitelistedInvestors(newInvestor), true);
    }

    function testRemoveWhitelistInvestor() public {
        vm.prank(owner);
        token.removeWhitelistedInvestor(investor1);

        assertEq(token.whitelistedInvestors(investor1), false);
    }

    function testForcedTransfer() public {
        vm.prank(owner);
        token.mintProperty(100000, 1000);

        vm.prank(owner);
        token.safeTransferFrom(owner, investor1, 0, 100, "");

        vm.prank(owner);
        token.forceTransfer(investor1, investor2, 0, 50);

        assertEq(token.balanceOf(investor1, 0), 50);
        assertEq(token.balanceOf(investor2, 0), 50);
    }

    function testBurnAllShares() public {
        vm.prank(owner);
        token.mintProperty(100000, 1000);

        vm.prank(owner);
        token.burnAllShares(0);

        assertEq(token.balanceOf(owner, 0), 0);
    }

    function testBurnSharesWhenNotAllOwned() public {
        vm.prank(owner);
        token.mintProperty(100000, 1000);

        vm.prank(owner);
        token.safeTransferFrom(owner, investor1, 0, 50, "");

        vm.prank(owner);
        // Should fail since owner doesn't own all shares
        vm.expectRevert();
        token.burnAllShares(0);
    }
}
