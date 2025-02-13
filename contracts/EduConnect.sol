// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EduConnect {
    struct Profile {
        string fullName;
        string ipfsProfilePicture;
        string title;
        string[] techStack;
        string about;
        mapping(address => bool) isFriend;
        mapping(address => bool) pendingRequests;
        address[] friendList;
        address[] pendingRequestsList;  // Added to store list of pending requests
    }

    struct Event {
        string name;
        string description;
        uint256 date;
        address organizer;
        bool isHackathon;
    }
    struct ProfileView {
        string fullName;
        string ipfsProfilePicture;
        string title;
        string[] techStack;
        string about;
        address userAddress;
    }

    mapping(address => Profile) public profiles;
    mapping(address => bool) public hasProfile;
    mapping(address => mapping(address => bool)) public friendships;
    address[] public allProfiles;
    Event[] public events;

    event ProfileCreated(address indexed user, string fullName);
    event FriendRequestSent(address indexed from, address indexed to);
    event FriendRequestAccepted(address indexed from, address indexed to);
    event EventCreated(uint256 indexed eventId, string name, bool isHackathon);

    modifier onlyRegistered() {
        require(hasProfile[msg.sender], "Profile not registered");
        _;
    }

    function createProfile(
        string memory _fullName,
        string memory _ipfsProfilePicture,
        string memory _title,
        string[] memory _techStack,
        string memory _about
    ) public {
        require(!hasProfile[msg.sender], "Profile already exists");

        Profile storage newProfile = profiles[msg.sender];
        newProfile.fullName = _fullName;
        newProfile.ipfsProfilePicture = _ipfsProfilePicture;
        newProfile.title = _title;
        newProfile.techStack = _techStack;
        newProfile.about = _about;

        hasProfile[msg.sender] = true;
        allProfiles.push(msg.sender);
        emit ProfileCreated(msg.sender, _fullName);
    }

    function sendFriendRequest(address _to) public onlyRegistered {
        require(_to != msg.sender, "Cannot send request to yourself");
        require(hasProfile[_to], "Recipient profile does not exist");
        require(!profiles[msg.sender].isFriend[_to], "Already friends");
        require(!profiles[_to].pendingRequests[msg.sender], "Request already sent");

        profiles[_to].pendingRequests[msg.sender] = true;
        profiles[_to].pendingRequestsList.push(msg.sender);  // Add to pending requests list
        emit FriendRequestSent(msg.sender, _to);
    }

    function acceptFriendRequest(address _from) public onlyRegistered {
        require(profiles[msg.sender].pendingRequests[_from], "No pending request");

        profiles[msg.sender].friendList.push(_from);
        profiles[_from].friendList.push(msg.sender);
        
        profiles[msg.sender].isFriend[_from] = true;
        profiles[_from].isFriend[msg.sender] = true;
        
        friendships[msg.sender][_from] = true;
        friendships[_from][msg.sender] = true;
        
        // Remove from pending requests
        profiles[msg.sender].pendingRequests[_from] = false;
        removePendingRequest(msg.sender, _from);
        
        emit FriendRequestAccepted(_from, msg.sender);
    }

    // New function to remove pending request from the list
    function removePendingRequest(address user, address requestor) internal {
        Profile storage profile = profiles[user];
        for (uint i = 0; i < profile.pendingRequestsList.length; i++) {
            if (profile.pendingRequestsList[i] == requestor) {
                // Move the last element to the position we want to delete
                profile.pendingRequestsList[i] = profile.pendingRequestsList[profile.pendingRequestsList.length - 1];
                // Remove the last element
                profile.pendingRequestsList.pop();
                break;
            }
        }
    }

    // New function to get pending requests
    function getPendingRequests(address _user) public view returns (ProfileView[] memory) {
        require(hasProfile[_user], "Profile does not exist");
        Profile storage userProfile = profiles[_user];
        ProfileView[] memory profilesArr = new ProfileView[](userProfile.pendingRequestsList.length);
        for(uint i=0;i<userProfile.pendingRequestsList.length;i++){
            Profile storage friend = profiles[userProfile.pendingRequestsList[i]];
            profilesArr[i] = ProfileView({
                fullName: friend.fullName,
                ipfsProfilePicture: friend.ipfsProfilePicture,
                title: friend.title,
                techStack: friend.techStack,
                about: friend.about,
                userAddress:userProfile.pendingRequestsList[i]
            });
        }
        return profilesArr;
    }

    function getFriends(address _user) public view returns (address[] memory) {
        require(hasProfile[_user], "Profile does not exist");
        return profiles[_user].friendList;
    }

    function getFriendCount(address _user) public view returns (uint256) {
        require(hasProfile[_user], "Profile does not exist");
        return profiles[_user].friendList.length;
    }

    function checkFriendship(address _user1, address _user2) public view returns (bool) {
        return friendships[_user1][_user2];
    }

    function createEvent(
        string memory _name,
        string memory _description,
        uint256 _date,
        bool _isHackathon
    ) public onlyRegistered {
        events.push(Event({
            name: _name,
            description: _description,
            date: _date,
            organizer: msg.sender,
            isHackathon: _isHackathon
        }));

        emit EventCreated(events.length - 1, _name, _isHackathon);
    }

    function getProfile(address _user) public view returns (
        ProfileView memory _profile
    ) {
        require(hasProfile[_user], "Profile does not exist");
        Profile storage profile = profiles[_user];
        ProfileView memory userProfile = ProfileView({
            fullName: profile.fullName,
            ipfsProfilePicture: profile.ipfsProfilePicture,
            title: profile.title,
            techStack: profile.techStack,
            about: profile.about,
            userAddress:_user
        });
        return (
           userProfile
        );
    }

    function getAllProfiles() public view returns (ProfileView[] memory) {
        ProfileView[] memory profilesArr = new ProfileView[](allProfiles.length);
        
        for (uint i = 0; i < allProfiles.length; i++) {
            address userAddress = allProfiles[i];
            Profile storage profile = profiles[userAddress];
            
            profilesArr[i] = ProfileView({
                fullName: profile.fullName,
                ipfsProfilePicture: profile.ipfsProfilePicture,
                title: profile.title,
                techStack: profile.techStack,
                about: profile.about,
                userAddress: userAddress
            });
        }
        
        return profilesArr;
    }

    function getProfileByTech(string[] memory _techStack) public view returns (ProfileView[] memory _filteredProfiles) {
        ProfileView[] memory profilesArr = new ProfileView[](allProfiles.length);
        
        for(uint i = 0; i < allProfiles.length; i++) {
            address userAddress = allProfiles[i];
            Profile storage profile = profiles[userAddress];
            
            if (_techStack.length != 0 && _techStack.length == profile.techStack.length){
                for (uint j = 0; j <_techStack.length ; j++) {
                    string memory techStackItem = _techStack[j];
                    
                    bool itemFound = false;
                    for (uint k = 0; k < profile.techStack.length ; k++) {
                        string memory currentTechItem = profile.techStack[k];
                        
                        if(keccak256(abi.encodePacked(currentTechItem)) == keccak256(abi.encodePacked(techStackItem))){
                            itemFound = true;
                            break;
                        }
                    }
                   if(itemFound){
                    profilesArr[profilesArr.length-1] = ProfileView({
                        fullName: profile.fullName,
                        ipfsProfilePicture: profile.ipfsProfilePicture,
                        title: profile.title,
                        techStack: profile.techStack,
                        about: profile.about,
                        userAddress: userAddress
                   });
                    }
            }
        }
        
        }
        return profilesArr;
    }

    function getEvents() public view returns(Event[] memory){   
        return events;
    }

    function getEventCount() public view returns (uint256) {
        return events.length;
    }
}