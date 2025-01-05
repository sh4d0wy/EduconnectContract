const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EduConnect", function () {
  let EduConnect;
  let eduConnect;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    EduConnect = await ethers.getContractFactory("EduConnect");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    // Deploy a new EduConnect contract before each test
    eduConnect = await EduConnect.deploy();
    // No need for .deployed() anymore
  });

  describe("Profile Management", function () {
    const mockProfile = {
      fullName: "John Doe",
      ipfsProfilePicture: "ipfs://QmTest",
      title: "Software Engineer",
      techStack: ["Solidity", "JavaScript", "Python"],
      about: "Blockchain Developer"
    };

    it("Should create a new profile", async function () {
      await eduConnect.connect(addr1).createProfile(
        mockProfile.fullName,
        mockProfile.ipfsProfilePicture,
        mockProfile.title,
        mockProfile.techStack,
        mockProfile.about
      );

      const profile = await eduConnect.getProfile(addr1.address);
      expect(profile.fullName).to.equal(mockProfile.fullName);
      expect(profile.ipfsProfilePicture).to.equal(mockProfile.ipfsProfilePicture);
      expect(profile.title).to.equal(mockProfile.title);
      expect(profile.techStack).to.deep.equal(mockProfile.techStack);
      expect(profile.about).to.equal(mockProfile.about);
    });

    it("Should not allow creating duplicate profiles", async function () {
      await eduConnect.connect(addr1).createProfile(
        mockProfile.fullName,
        mockProfile.ipfsProfilePicture,
        mockProfile.title,
        mockProfile.techStack,
        mockProfile.about
      );

      await expect(
        eduConnect.connect(addr1).createProfile(
          mockProfile.fullName,
          mockProfile.ipfsProfilePicture,
          mockProfile.title,
          mockProfile.techStack,
          mockProfile.about
        )
      ).to.be.revertedWith("Profile already exists");
    });
  });

  describe("Friend Request System", function () {
    beforeEach(async function () {
      // Create profiles for testing
      await eduConnect.connect(addr1).createProfile(
        "User 1",
        "ipfs://user1",
        "Developer",
        ["Solidity"],
        "About user 1"
      );
      
      await eduConnect.connect(addr2).createProfile(
        "User 2",
        "ipfs://user2",
        "Designer",
        ["UI/UX"],
        "About user 2"
      );
    });

    it("Should send friend request", async function () {
      await eduConnect.connect(addr1).sendFriendRequest(addr2.address);
      
      // Verify friend request was sent by checking the event
      await expect(eduConnect.connect(addr1).sendFriendRequest(addr2.address))
        .to.be.revertedWith("Request already sent");
    });

    it("Should accept friend request", async function () {
      await eduConnect.connect(addr1).sendFriendRequest(addr2.address);
      await eduConnect.connect(addr2).acceptFriendRequest(addr1.address);

      expect(await eduConnect.checkFriendship(addr1.address, addr2.address)).to.be.true;
      expect(await eduConnect.getFriendCount(addr1.address)).to.equal(1);
      expect(await eduConnect.getFriendCount(addr2.address)).to.equal(1);
    });

    it("Should not allow sending request to non-existent profile", async function () {
      await expect(
        eduConnect.connect(addr1).sendFriendRequest(addrs[0].address)
      ).to.be.revertedWith("Recipient profile does not exist");
    });
  });

  describe("Events Management", function () {
    beforeEach(async function () {
      // Create a profile for the event organizer
      await eduConnect.connect(addr1).createProfile(
        "Organizer",
        "ipfs://organizer",
        "Event Manager",
        ["Management"],
        "Professional event organizer"
      );
    });

    it("Should create a new event", async function () {
      const eventDetails = {
        name: "Blockchain Workshop",
        description: "Learn about blockchain",
        date: Math.floor(Date.now() / 1000) + 86400, // Tomorrow
        isHackathon: false
      };

      await eduConnect.connect(addr1).createEvent(
        eventDetails.name,
        eventDetails.description,
        eventDetails.date,
        eventDetails.isHackathon
      );

      expect(await eduConnect.getEventCount()).to.equal(1);
      
      const event = await eduConnect.events(0);
      expect(event.name).to.equal(eventDetails.name);
      expect(event.description).to.equal(eventDetails.description);
      expect(event.date).to.equal(eventDetails.date);
      expect(event.isHackathon).to.equal(eventDetails.isHackathon);
      expect(event.organizer).to.equal(addr1.address);
    });

    it("Should not allow unregistered users to create events", async function () {
      await expect(
        eduConnect.connect(addr2).createEvent(
          "Test Event",
          "Description",
          Math.floor(Date.now() / 1000),
          false
        )
      ).to.be.revertedWith("Profile not registered");
    });
  });
});