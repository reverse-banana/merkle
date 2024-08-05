// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {console} from "forge-std/console.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712{
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool claimed) private s_hasClaimed;
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");
     

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    event Claimed(address account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        // we are able to pass tke as ierc due to the fact is inherits it as erc20
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    /**
     * @notice due to the problem with leaf proof generation I have to hard copy the function
     * from the HelperScript to the contract
     * bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))))
     * wasn't working due to the different encoding of the bytes
     */
    function ltrim64(bytes memory _bytes) public pure returns (bytes memory) {
        require(_bytes.length >= 64, "ltrim64: input less than 64 bytes");
        bytes memory result = new bytes(_bytes.length - 64);
        for (uint256 i = 64; i < _bytes.length; i++) {
            result[i - 64] = _bytes[i];
        }
        return result;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) public {
        // by default the bool value in mapping is false
        // but to due to the nature of suntax and contex here the if (s_hasClaimed[account])
        // mean that if it's true cause if we want to check negative value
        //  we will have to do if (!s_hasClaimed[account])
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }

        bytes32[] memory data = new bytes32[](2);
        data[0] = bytes32(uint256(uint160(account)));
        data[1] = bytes32(amount);

        bytes memory encodedData = abi.encode(data);
        bytes memory trimmedData = ltrim64(encodedData);
        bytes32 leaf1 = keccak256(bytes.concat(keccak256(trimmedData)));
        console.log("Calculated leaf:");
        console.logBytes32(leaf1);

        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf1)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true;
        // anti messure to prevent double claiming
        emit Claimed(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }


    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({ account: account, amount: amount }))));
        // the triest part here that the _hashTypedDataV4 is auto adding the domain separator
        // and returning full eip-712 message digest 
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        (address actualSigner, , ) = ECDSA.tryRecover(digest, v, r, s);
        return (actualSigner == account);
    }


    // Getters

    function getMerkleRoot() public view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirDropToken() public view returns (IERC20) {
        return i_airdropToken;
    }
}
