// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TrustVerify
 * @dev Stores hashed KYC and SOS event data for verification and trust.
 */
contract TrustVerify {
    // Mapping from user address to their hashed KYC data
    mapping(address => string) public kycHashes;
    
    // Array to store SOS event hashes (immutable log)
    string[] public sosHashes;

    event KYCStored(address indexed user, string hash);
    event SOSStored(address indexed user, string sosHash);

    /**
     * @dev Stores hashed KYC data for the sender.
     * @param _hash The SHA256 hash of the user's KYC data.
     */
    function storeKYC(string memory _hash) public {
        kycHashes[msg.sender] = _hash;
        emit KYCStored(msg.sender, _hash);
    }

    /**
     * @dev Stores an SOS event hash in the global log.
     * @param _sosHash The SHA256 hash of the SOS event data.
     */
    function storeSOS(string memory _sosHash) public {
        sosHashes.push(_sosHash);
        emit SOSStored(msg.sender, _sosHash);
    }

    /**
     * @dev Returns all SOS event hashes stored in the contract.
     * @return An array of strings containing SOS hashes.
     */
    function getSOSLogs() public view returns (string[] memory) {
        return sosHashes;
    }
    
    /**
     * @dev Returns the KYC hash for a specific address.
     * @param _user The address of the user.
     * @return The stored KYC hash.
     */
    function getKYCHash(address _user) public view returns (string memory) {
        return kycHashes[_user];
    }
}
