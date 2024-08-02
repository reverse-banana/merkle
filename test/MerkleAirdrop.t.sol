// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {BagelToken} from "src/BagelToken.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public airdrop;
    BagelToken public token;

    bytes32 firstProof = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 secondProof = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;

    bytes32[] public proof_array = [firstProof, secondProof];

    bytes32 public root = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address user;
    uint256 userPrivKey;
    uint256 public AMOUNT = 25e18;

    function setUp() public {
        token = new BagelToken();
        airdrop = new MerkleAirdrop(root, token);
        (user, userPrivKey) = makeAddrAndKey("user");
        // create a new user address and private key
        // (the priv key deterministic due to generation process which is based on the user name)
    }

    function testUserCanClaim() public {
        // test logic here
        uint256 startingBalance = token.balanceOf(user);

        vm.prank(user);
        airdrop.claim(user, AMOUNT, proof_array);

        uint256 endingBalance = token.balanceOf(user);
        console.log("Ending balance: %d", endingBalance);

        assertEq(endingBalance - startingBalance, AMOUNT);
    }
}
