// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {console} from "forge-std/console.sol";

contract MerkleAirdrop {
    // if for some reason can't send token for the address sameerc20 lib will hangle it
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    event Claimed(address account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        // we are able to pass tke as ierc due to the fact is inherits it as erc20
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) public {
        // by default the bool value in mapping is false
        // but to due to the nature of suntax and contex here the if (s_hasClaimed[account])
        // mean that if it's true cause if we want to check negative value
        //  we will have to do if (!s_hasClaimed[account])
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        console.log("Claiming for %s", account);
        console.log("Amount: %d", amount);

            bytes32[] memory data = new bytes32[](2);
            data[0] = bytes32(uint256(uint160(account)));
            data[1] = bytes32(amount);

        
        
        


        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encodePacked(account, amount))));
        // hashing twice as good practice to mitigate the pre-image attack
        console.log("Calculated leaf:");
        console.logBytes32(leaf);


        bytes32 leafFromOutput = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
        bytes32 leafWithSingleHash = keccak256(abi.encodePacked(account, amount));



        console.log("Expected leaf:");
        console.logBytes32(leafFromOutput);
        console.log("Leaf with single hash:");
        console.logBytes32(leafWithSingleHash);

        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true;
        // anti messure to prevent double claiming
        emit Claimed(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    // Getters

    function getMerkleRoot() public view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirDropToken() public view returns (IERC20) {
        return i_airdropToken;
    }
}
