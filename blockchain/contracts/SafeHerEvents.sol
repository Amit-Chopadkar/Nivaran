// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SafeHerEvents
 * @dev Stores hashed safety critical events (SOS triggers, Incident reports)
 */
contract SafeHerEvents {

    struct SafetyEvent {
        bytes32 eventHash;
        uint256 timestamp;
        address userWallet;
    }

    // Immutable on-chain log of all events
    SafetyEvent[] public eventLogs;

    // Emitted when a new event is logged
    event EventLogged(address indexed userWallet, bytes32 indexed eventHash, uint256 timestamp);

    /**
     * @dev Logs a safety event hash to the blockchain. Keeps exact details off-chain.
     * @param _eventHash The bytes32 hash of the event data (generated off-chain)
     */
    function logEvent(bytes32 _eventHash) public {
        uint256 currentTimestamp = block.timestamp;
        
        SafetyEvent memory newEvent = SafetyEvent({
            eventHash: _eventHash,
            timestamp: currentTimestamp,
            userWallet: msg.sender
        });

        eventLogs.push(newEvent);
        
        emit EventLogged(msg.sender, _eventHash, currentTimestamp);
    }

    /**
     * @dev Returns total number of events logged
     */
    function getTotalEvents() public view returns (uint256) {
        return eventLogs.length;
    }

    /**
     * @dev Optional: Fetch a specific event by index
     */
    function getEvent(uint256 index) public view returns (bytes32, uint256, address) {
        require(index < eventLogs.length, "Index out of bounds");
        SafetyEvent memory e = eventLogs[index];
        return (e.eventHash, e.timestamp, e.userWallet);
    }
}
