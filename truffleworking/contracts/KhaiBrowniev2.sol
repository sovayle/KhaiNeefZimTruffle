// SPDX-License-Identifier: MIT
//v2: candidates can no longer register twice
pragma solidity >=0.5.0 <0.9.0;


contract Election {

    struct Candidate {
        string name;
        bool registered;
        uint voteCount;
        bool votable; //added in v2
    }

    struct Voter {
        bool voted;
        bool registered;
        address vote;
    }

    address[] public candidateAddresses;
    address public owner;
    //string public electionName;

    mapping(address => Voter) public voters;
    mapping(address => Candidate) public candidates;
    uint public totalVotes;

    enum State { Created, Voting, Ended }
    State public state;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "Wrong state");
        _;
    }

    //constructor(string memory _name) public {
    constructor() {
        owner = msg.sender;
        //electionName = _name; 
        state = State.Created;
    }

    //this function is called by a new candidate in which they pay 100 to register as a candidate
    function payFee() public payable {
        require(msg.value == 100 wei, "Pay 100 wei to register");
        require(!candidates[msg.sender].votable, "Candidate can already be voted for"); //added in v2
        candidates[msg.sender].registered = true;        
    }

    //this function is called by owner to manually register a new voter
    function registerVoter(address _voterAddress) onlyOwner inState(State.Created) public {
        require(!voters[_voterAddress].registered, "Voter is already registered");
        require(_voterAddress != owner, "Owner cannot be registered");
        voters[_voterAddress].registered = true;
    }

  //this function is called by owner to manually register a new candidate after they pay 100 wei
    function addCandidate(address _canAddress, string memory _name) inState(State.Created) onlyOwner public {
        require(!candidates[_canAddress].votable, "Candidate can already be voted for");    //added in v2
        require(candidates[_canAddress].registered, "Candidate is not registered");
        candidates[_canAddress].name = _name;
        candidates[_canAddress].votable = true; //added in v2
        candidates[_canAddress].voteCount = 0;
        candidateAddresses.push(_canAddress);
    }

    //this function indicates the start of the election.
    function startVote() public inState(State.Created) onlyOwner {
        state = State.Voting;
    }

    // this funciton is called by a voter to vote for a candidate
    function vote(address _canAddress) inState(State.Voting) public {
        require(voters[msg.sender].registered, "Voter is not registered");
        require(!voters[msg.sender].voted, "Voter has already voted");
        require(candidates[_canAddress].registered, "Not a registered candidate");
        require(msg.sender!=owner, "Owner cannot vote"); 

        voters[msg.sender].vote = _canAddress;
        voters[msg.sender].voted = true;
        candidates[_canAddress].voteCount++;
        totalVotes++;
    }

    //this function ends the vote state
    function endVote() public inState(State.Voting) onlyOwner {
        state = State.Ended;
    }

    //this function announces the winner's address, compares the vote count for all the candidates.
    function announceWinner() inState(State.Ended) public view returns (address) {
        uint max = 0;
        uint i;
        address winnerAddress;
        for(i=0; i<candidateAddresses.length; i++) {
            if(candidates[candidateAddresses[i]].voteCount > max) {
                max = candidates[candidateAddresses[i]].voteCount;
                winnerAddress = candidateAddresses[i];
            }
        }
        return winnerAddress;
    }

    //this function returns the length of the candidateAddress array.

    function getTotalCandidates() public view returns(uint) {
        return candidateAddresses.length;
    }

    //this function returns the balance of the contract.

    function balanceOf() public view returns(uint) {
        return address(this).balance;
    }

    //this function transfers the funds from the contract to the owner.

    function withdrawRegistrationFunds() onlyOwner inState(State.Ended) payable public {
        require(address(this).balance > 0, "No funds to transfer");
        payable(owner).transfer(address(this).balance);
    }

    //this function returns the balance of the owner

    function getOwnerBalance() public view returns(uint) {
        return owner.balance;
    }

}