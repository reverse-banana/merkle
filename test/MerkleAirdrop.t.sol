// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {BagelToken} from "src/BagelToken.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    MerkleAirdrop public airdrop;
    BagelToken public token;

    bytes32 firstProof = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 secondProof = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;

    bytes32[] public proof_array = [firstProof, secondProof];

    bytes32 public root = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address user;
    uint256 userPrivKey;
    address public gasPayer;
    uint256 public AMOUNT_TO_CLAIM = 25e18;
    uint256 public AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;

    function setUp() public {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.run();
        } else {
            token = new BagelToken();
            airdrop = new MerkleAirdrop(root, token);
            token.transfer(address(airdrop), AMOUNT_TO_SEND);
            // sending the token to the airdrop contract since we as the test contract are inial owner
        }
        (user, userPrivKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
        // create a new user address and private key
        // (the priv key deterministic due to generation process which is based on the user name)
    }

    function testUserCanClaim() public {
        // test logic here
        uint256 startingBalance = token.balanceOf(user);
        console.log("Starting balance: %d", startingBalance);
        bytes32 digest = airdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        
        console.logBytes32(digest);


        // sign a message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        console.log(userPrivKey);
        console.log(user);
        console.log("v: %d", v);
        console.logBytes32(r);
        console.logBytes32(s);

        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, proof_array, v, r, s);

        uint256 endingBalance = token.balanceOf(user);
        console.log("Ending balance: %d", endingBalance);

        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }

}
