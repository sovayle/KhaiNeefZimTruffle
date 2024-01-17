const Election = artifacts.require("Election");

contract("Election", (accounts) => {
  let electionInstance;
  const owner = accounts[0];
  const voter = accounts[1];
  const candidate = accounts[2];

  beforeEach(async () => {
    electionInstance = await Election.new();
  });

  it("should initialize with the correct owner", async () => {
    const contractOwner = await electionInstance.owner();
    assert.equal(contractOwner, owner, "Contract owner is incorrect");
  });

  it("should not allow non-owner to register a voter", async () => {
    try {
      await electionInstance.registerVoter(voter, { from: voter });
      assert.fail("Should not allow non-owner to register a voter");
    } catch (error) {
      assert.include(
        error.message,
        "You are not the owner",
        "Non-owner was able to register a voter"
      );
    }
  });

  it("should not allow owner to register a voter with the same address twice", async () => {
    await electionInstance.registerVoter(voter, { from: owner });

    try {
      await electionInstance.registerVoter(voter, { from: owner });
      assert.fail("Should not allow owner to register a voter with the same address twice");
    } catch (error) {
      assert.include(
        error.message,
        "Voter is already registered",
        "Owner was able to register a voter with the same address twice"
      );
    }
  });

  it("should allow owner to add a candidate after registration and fee payment", async () => {
    const candidateName = "John Doe";

    await electionInstance.payFee({ from: candidate, value: web3.utils.toWei("100", "wei") });
    await electionInstance.addCandidate(candidate, candidateName, { from: owner });

    const candidateInfo = await electionInstance.candidates(candidate);
    assert.equal(candidateInfo.registered, true, "Candidate not registered");
    assert.equal(candidateInfo.name, candidateName, "Candidate name is incorrect");
    assert.equal(candidateInfo.votable, true, "Candidate not marked as votable");
    assert.equal(candidateInfo.voteCount, 0, "Candidate vote count is not zero");
  });
});
