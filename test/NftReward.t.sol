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

    function testGetMintRequestDigest_ShouldReturnDigestToSign() public {
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](1);
        values[0] = "ubiquity";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
        });

        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);

        assertEq(digest, 0x2c680706f2350ed5622f229af6736cd20626f7b9b4569b2fd5abb7e086886dc3);
    }

    function testGetTokenDataKeys_ReturnAllTokenDataKeys() public {
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](2);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        keys[1] = keccak256("GITHUB_REPOSITORY_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](2);
        values[0] = "ubiquity";
        values[1] = "nft-rewards";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
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

        // minter updates mint request with new token data key
        mintRequest.keys[1] = keccak256("GITHUB_ISSUE_ID");
        mintRequest.values[1] = "1";
        mintRequest.nonce = 2;
        digest = nftReward.getMintRequestDigest(mintRequest);
        (v, r, s) = vm.sign(minterPrivateKey, digest);
        signature = abi.encodePacked(r, s, v);

        // user1 mints again
        vm.prank(user1);
        nftReward.safeMint(mintRequest, signature);

        bytes32[] memory tokenDataKeys = nftReward.getTokenDataKeys();
        assertEq(tokenDataKeys.length, 3);
        assertEq(tokenDataKeys[0], keccak256("GITHUB_ORGANIZATION_NAME"));
        assertEq(tokenDataKeys[1], keccak256("GITHUB_REPOSITORY_NAME"));
        assertEq(tokenDataKeys[2], keccak256("GITHUB_ISSUE_ID"));
    }

    function testRecover_ShouldReturnMinterAddress_IfDigestIsSignedByMinter() public {
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](1);
        values[0] = "ubiquity";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
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
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](1);
        values[0] = "ubiquity";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
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
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](1);
        values[0] = "ubiquity";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
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
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](1);
        values[0] = "ubiquity";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
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
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](1);
        values[0] = "ubiquity";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp - 1, // set expired signature
            keys: keys,
            nonce: 1,
            values: values
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
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](1);
        values[0] = "ubiquity";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
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

    function testSafeMint_ShouldRevert_OnKeyValueLengthMismatch() public {
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](0);
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
        });
        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);
        // minter signs mint request digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(minterPrivateKey, digest);
        // get minter's signature
        bytes memory signature = abi.encodePacked(r, s, v);

        // user1 mints
        vm.prank(user1);
        vm.expectRevert("Key/value length mismatch");
        nftReward.safeMint(mintRequest, signature);
    }

    function testSafeMint_ShouldRevert_OnOtherUserSignatureReuse() public {
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](1);
        values[0] = "ubiquity";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
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
            keys: keys,
            nonce: 1,
            values: values
        });
        vm.prank(user2);
        vm.expectRevert("Signed not by minter");
        nftReward.safeMint(mintRequestForged, signature);
    }

    function testSafeMint_ShouldRevert_OnOwnSignatureReuse() public {
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](1);
        values[0] = "ubiquity";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
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
            keys: keys,
            nonce: 2,
            values: values
        });
        vm.prank(user1);
        vm.expectRevert("Signed not by minter");
        nftReward.safeMint(mintRequestForged, signature);
    }

    function testSafeMint_ShouldRevert_OnArbitraryDataKeyChange() public {
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](1);
        values[0] = "ubiquity";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
        });
        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);
        // minter signs mint request digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(minterPrivateKey, digest);
        // get minter's signature
        bytes memory signature = abi.encodePacked(r, s, v);

        // user1 tries to mint using forged mint request
        mintRequest.keys[0] = keccak256("OTHER_ORGANIZATION_NAME");
        vm.prank(user1);
        vm.expectRevert("Signed not by minter");
        nftReward.safeMint(mintRequest, signature);
    }

    function testSafeMint_ShouldRevert_OnArbitraryDataValueChange() public {
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](1);
        values[0] = "ubiquity";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
        });
        // get mint request digest which should be signed
        bytes32 digest = nftReward.getMintRequestDigest(mintRequest);
        // minter signs mint request digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(minterPrivateKey, digest);
        // get minter's signature
        bytes memory signature = abi.encodePacked(r, s, v);

        // user1 tries to mint using forged mint request
        mintRequest.values[0] = "FORGED_VALUE";
        vm.prank(user1);
        vm.expectRevert("Signed not by minter");
        nftReward.safeMint(mintRequest, signature);
    }

    function testSafeMint_ShouldMint() public {
        // prepare arbitrary data keys
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256("GITHUB_ORGANIZATION_NAME"); 
        // prepare arbitrary data values
        string[] memory values = new string[](1);
        values[0] = "ubiquity";
        // prepare mint request
        NftReward.MintRequest memory mintRequest = NftReward.MintRequest({
            beneficiary: user1,
            deadline: block.timestamp + 1,
            keys: keys,
            nonce: 1,
            values: values
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
        assertEq(nftReward.tokenDataKeyExists(keccak256("GITHUB_ORGANIZATION_NAME")), false);

        // user1 mints
        vm.prank(user1);
        nftReward.safeMint(mintRequest, signature);

        // after
        assertEq(nftReward.nonceRedeemed(1), true);
        assertEq(nftReward.tokenDataKeys(0), keccak256("GITHUB_ORGANIZATION_NAME"));
        assertEq(nftReward.tokenDataKeyExists(keccak256("GITHUB_ORGANIZATION_NAME")), true);
        assertEq(nftReward.ownerOf(tokenId), user1);
        assertEq(nftReward.tokenIdCounter(), 1);
        assertEq(nftReward.tokenData(0, keccak256("GITHUB_ORGANIZATION_NAME")), "ubiquity");
    }

    //=================
    // Owner methods
    //=================

    function testPause_ShouldPauseContract() public {
        // before
        assertFalse(nftReward.paused());

        // owner pauses contract
        vm.prank(owner);
        nftReward.pause();

        // after
        assertTrue(nftReward.paused());
    }

    function testSetBaseUri_ShouldSetBaseUri() public {
        // before
        assertEq(nftReward.baseUri(), '');

        // owner sets base URI
        vm.prank(owner);
        nftReward.setBaseUri('https://website/com/');

        // after
        assertEq(nftReward.baseUri(), 'https://website/com/');
    }

    function testSetMinter_ShouldSetMinterAddress() public {
        // before
        assertEq(nftReward.minter(), minter);

        // owner sets new minter
        vm.prank(owner);
        nftReward.setMinter(user1);

        // after
        assertEq(nftReward.minter(), user1);
    }

    function testUnpause_ShouldUnpauseContract() public {
        // owner pauses contract
        vm.prank(owner);
        nftReward.pause();

        // before
        assertTrue(nftReward.paused());

        // owner unpauses contract
        vm.prank(owner);
        nftReward.unpause();

        // after
        assertFalse(nftReward.paused());
    }
}
