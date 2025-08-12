// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DecentralizedPasswordManager
 * @dev A decentralized password manager that stores encrypted passwords on-chain
 * @notice This contract allows users to store, retrieve, and manage encrypted passwords
 */
contract DecentralizedPasswordManager {
    
    // Structure to store password data
    struct PasswordEntry {
        string website;
        string encryptedUsername;
        string encryptedPassword;
        uint256 timestamp;
        bool exists;
    }
    
    // Mapping from user address to their password entries
    mapping(address => mapping(string => PasswordEntry)) private userPasswords;
    
    // Mapping to track all websites for a user
    mapping(address => string[]) private userWebsites;
    
    // Events
    event PasswordStored(address indexed user, string website, uint256 timestamp);
    event PasswordUpdated(address indexed user, string website, uint256 timestamp);
    event PasswordDeleted(address indexed user, string website, uint256 timestamp);
    
    /**
     * @dev Store or update an encrypted password for a website
     * @param _website The website identifier
     * @param _encryptedUsername Encrypted username for the website
     * @param _encryptedPassword Encrypted password for the website
     */
    function storePassword(
        string memory _website,
        string memory _encryptedUsername,
        string memory _encryptedPassword
    ) external {
        require(bytes(_website).length > 0, "Website cannot be empty");
        require(bytes(_encryptedPassword).length > 0, "Password cannot be empty");
        
        bool isNewEntry = !userPasswords[msg.sender][_website].exists;
        
        userPasswords[msg.sender][_website] = PasswordEntry({
            website: _website,
            encryptedUsername: _encryptedUsername,
            encryptedPassword: _encryptedPassword,
            timestamp: block.timestamp,
            exists: true
        });
        
        if (isNewEntry) {
            userWebsites[msg.sender].push(_website);
            emit PasswordStored(msg.sender, _website, block.timestamp);
        } else {
            emit PasswordUpdated(msg.sender, _website, block.timestamp);
        }
    }
    
    /**
     * @dev Retrieve encrypted password data for a specific website
     * @param _website The website identifier
     * @return website The website name
     * @return encryptedUsername The encrypted username
     * @return encryptedPassword The encrypted password
     * @return timestamp When the password was last updated
     */
    function getPassword(string memory _website) 
        external 
        view 
        returns (
            string memory website,
            string memory encryptedUsername,
            string memory encryptedPassword,
            uint256 timestamp
        ) 
    {
        PasswordEntry memory entry = userPasswords[msg.sender][_website];
        require(entry.exists, "Password entry does not exist");
        
        return (
            entry.website,
            entry.encryptedUsername,
            entry.encryptedPassword,
            entry.timestamp
        );
    }
    
    /**
     * @dev Get all websites for which the user has stored passwords
     * @return Array of website identifiers
     */
    function getAllWebsites() external view returns (string[] memory) {
        return userWebsites[msg.sender];
    }
    
    /**
     * @dev Delete a password entry for a specific website
     * @param _website The website identifier to delete
     */
    function deletePassword(string memory _website) external {
        require(userPasswords[msg.sender][_website].exists, "Password entry does not exist");
        
        // Delete the password entry
        delete userPasswords[msg.sender][_website];
        
        // Remove website from user's website list
        string[] storage websites = userWebsites[msg.sender];
        for (uint256 i = 0; i < websites.length; i++) {
            if (keccak256(bytes(websites[i])) == keccak256(bytes(_website))) {
                websites[i] = websites[websites.length - 1];
                websites.pop();
                break;
            }
        }
        
        emit PasswordDeleted(msg.sender, _website, block.timestamp);
    }
    
    /**
     * @dev Check if a password entry exists for a website
     * @param _website The website identifier
     * @return bool indicating if the password exists
     */
    function passwordExists(string memory _website) external view returns (bool) {
        return userPasswords[msg.sender][_website].exists;
    }
}
