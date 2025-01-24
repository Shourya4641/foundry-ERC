//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {DeployToken} from "../script/DeployToken.s.sol";
import {Token} from "../src/Token.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract TokenTest is Test {
    Token public token;
    DeployToken public deployToken;

    uint256 public constant STARTING_BALANCE = 100 ether;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    function setUp() public {
        deployToken = new DeployToken();
        token = deployToken.run();

        vm.prank(msg.sender);

        token.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public view {
        assertEq(token.balanceOf(bob), STARTING_BALANCE);
    }

    function testAllowanceIsWorkingCorrectly() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend the tokens on his behalf
        vm.prank(bob);
        token.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        token.transferFrom(bob, alice, transferAmount);

        assertEq(token.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(token.balanceOf(alice), transferAmount);

        assertEq(
            token.allowance(bob, alice),
            initialAllowance - transferAmount
        );
    }

    function testAllowanceCannotExceedBalance() public {
        uint256 excessiveAllowance = STARTING_BALANCE + 1 ether;

        // Bob approves Alice with an excessive allowance
        vm.prank(bob);
        token.approve(alice, excessiveAllowance);

        // Attempting to transfer more than balance will fail
        uint256 transferAmount = STARTING_BALANCE + 1 ether;
        vm.prank(alice);
        vm.expectRevert();
        token.transferFrom(bob, alice, transferAmount);
    }

    function testTransferUpdatesBalancesCorrectly() public {
        uint256 transferAmount = 50 ether;

        // Bob transfers tokens to Alice
        vm.prank(bob);
        token.transfer(alice, transferAmount);

        assertEq(token.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(token.balanceOf(alice), transferAmount);
    }

    function testTransferFailsIfBalanceIsInsufficient() public {
        uint256 excessiveAmount = STARTING_BALANCE + 1 ether;

        // Bob attempts to transfer more tokens than he owns
        vm.prank(bob);
        vm.expectRevert();
        token.transfer(alice, excessiveAmount);
    }

    function testCannotTransferToZeroAddress() public {
        uint256 transferAmount = 10 ether;

        // Attempt to transfer tokens to the zero address
        vm.prank(bob);
        vm.expectRevert();
        token.transfer(address(0), transferAmount);
    }

    function testCannotApproveZeroAddress() public {
        uint256 approvalAmount = 1000;

        // Attempt to approve the zero address
        vm.prank(bob);
        vm.expectRevert();
        token.approve(address(0), approvalAmount);
    }

    function testTotalSupplyIsCorrect() public view {
        uint256 expectedSupply = token.totalSupply(); // Capture initial supply
        assertEq(
            token.balanceOf(bob) + token.balanceOf(msg.sender),
            expectedSupply
        );
    }

    function testBurnReducesTotalSupply() public {
        uint256 burnAmount = 10 ether;

        uint256 expectedTotalSupply = token.totalSupply() - burnAmount;

        // Bob burns some of his tokens
        vm.prank(bob);
        token.burn(burnAmount);

        assertEq(token.totalSupply(), expectedTotalSupply);
    }

    function testMultipleApprovalsOverwrite() public {
        uint256 firstAllowance = 1000;
        uint256 secondAllowance = 500;

        // Bob approves Alice twice with different allowances
        vm.prank(bob);
        token.approve(alice, firstAllowance);

        vm.prank(bob);
        token.approve(alice, secondAllowance);

        // Ensure the last approval overwrites the first one
        assertEq(token.allowance(bob, alice), secondAllowance);
    }

    function testTransferFromFailsIfNotApproved() public {
        uint256 transferAmount = 500;

        // Alice attempts to transfer tokens from Bob without approval
        vm.prank(alice);
        vm.expectRevert();
        token.transferFrom(bob, alice, transferAmount);
    }
}
