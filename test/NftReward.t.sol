// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NftReward} from "../src/NftReward.sol";

contract NftRewardTest is Test {
    NftReward nftReward;

    uint minterPrivateKey = 100;

    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);
    address minter = vm.addr(minterPrivateKey);

    function setUp() public {
        vm.prank(owner);
        nftReward = new NftReward(
            "NFT reward", // token name
            "RWD", // token symbol
            owner, // initial owner
            minter // minter (off-chain signer)
        );
    }

    //==================
    // Public methods
    //==================

    function testRecover_ShouldReturnMinterAddress_IfDigestIsSignedByMinter() public {
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            nonce: 1
        });
        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);
        // minter signs mint request digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(minterPrivateKey, digest);
        // get minter's signature
        bytes memory signature = abi.encodePacked(r, s, v);

        address recovered = nftReward.recover(mintRequest, signature);
        assertTrue(recovered == minter);
    }

    function testRecover_ShouldReturnSomeOtherAddress_IfDigestIsNotSignedByMinter() public {
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            nonce: 1
        });
        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);
        // some other address (not minter) signs mint request digest
        uint someOtherPrivateKey = 200;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(someOtherPrivateKey, digest);
        // get signer's signature
        bytes memory signature = abi.encodePacked(r, s, v);

        address recovered = nftReward.recover(mintRequest, signature);
        assertFalse(recovered == minter);
    }

    function testSafeMint_ShouldRevert_IfDigestIsNotSignedByMinter() public {
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            nonce: 1
        });
        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);
        // some other address (not minter) signs mint request digest
        uint someOtherPrivateKey = 200;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(someOtherPrivateKey, digest);
        // get signer's signature
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user1);
        vm.expectRevert('Signed not by minter');
        nftReward.safeMint(mintRequest, signature);
    }

    function testSafeMint_ShouldRevert_IfBeneficiaryIsNotEligibleForCurrentNft() public {
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            nonce: 1
        });
        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);
        // minter signs mint request digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(minterPrivateKey, digest);
        // get minter's signature
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user2);
        vm.expectRevert('Not eligible');
        nftReward.safeMint(mintRequest, signature);
    }

    function testSafeMint_ShouldRevert_IfSignatureExpired() public {
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp - 1, // set expired signature
            nonce: 1
        });
        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);
        // minter signs mint request digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(minterPrivateKey, digest);
        // get minter's signature
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user1);
        vm.expectRevert('Signature expired');
        nftReward.safeMint(mintRequest, signature);
    }

    function testSafeMint_ShouldRevert_IfNonceAlreadyUsed() public {
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            nonce: 1
        });
        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);
        // minter signs mint request digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(minterPrivateKey, digest);
        // get minter's signature
        bytes memory signature = abi.encodePacked(r, s, v);

        // user1 mints
        vm.prank(user1);
        nftReward.safeMint(mintRequest, signature);

        // user1 tries to mint 1 more time
        vm.prank(user1);
        vm.expectRevert("Already minted");
        nftReward.safeMint(mintRequest, signature);
    }

    function testSafeMint_ShouldRevert_OnOtherUserSignatureReuse() public {
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            nonce: 1
        });
        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);
        // minter signs mint request digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(minterPrivateKey, digest);
        // get minter's signature
        bytes memory signature = abi.encodePacked(r, s, v);

        // user2 tries to mint using signature for user1
        NftReward.MintRequest memory mintRequestForged = NftReward.MintRequest({
            beneficiary: user2,
            deadline: block.timestamp + 1,
            nonce: 1
        });
        vm.prank(user2);
        vm.expectRevert("Signed not by minter");
        nftReward.safeMint(mintRequestForged, signature);
    }

    function testSafeMint_ShouldRevert_OnOwnSignatureReuse() public {
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            nonce: 1
        });
        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);
        // minter signs mint request digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(minterPrivateKey, digest);
        // get minter's signature
        bytes memory signature = abi.encodePacked(r, s, v);

        // user1 tries to mint using own signature
        NftReward.MintRequest memory mintRequestForged = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            nonce: 2
        });
        vm.prank(user1);
        vm.expectRevert("Signed not by minter");
        nftReward.safeMint(mintRequestForged, signature);
    }

    function testSafeMint_ShouldMint() public {
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            nonce: 1
        });
        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);
        // minter signs mint request digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(minterPrivateKey, digest);
        // get minter's signature
        bytes memory signature = abi.encodePacked(r, s, v);

        uint tokenId = 0;

        // before
        vm.expectRevert();
        nftReward.ownerOf(tokenId);
        assertEq(nftReward.nonceRedeemed(1), false);

        // user1 mints
        vm.prank(user1);
        nftReward.safeMint(mintRequest, signature);

        // after
        assertEq(nftReward.nonceRedeemed(1), true);
        assertEq(nftReward.ownerOf(tokenId), user1);
        assertEq(nftReward.tokenIdCounter(), 1);
    }
}
