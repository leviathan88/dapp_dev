pragma solidity ^0.6.12;

struct Voter {
    uint weight;
    bool voted;
    uint vote;
}
    
struct Proposal {
    uint voteCount;
}

enum Phase {Init, Regs, Vote, Done}
 
contract MyBallot {
    address chairperson;
    mapping (address => Voter) voters;
    Proposal[] proposals;
    
    Phase public state = Phase.Init;
    
    modifier validPhase(Phase reqPhase) {
        require(state == reqPhase);
        _;
    }
    
    modifier chairpersonOnly() {
        require(msg.sender == chairperson);
        _;
    }
    
    modifier notYetVoted(address voter) {
        require(!voters[voter].voted);
        _;
    }
    
    constructor(uint256 numProposals) public {
        chairperson = msg.sender;
        
        voters[chairperson].weight = 2;
        
        for (uint256 prop = 0; prop < numProposals; prop++) {
            proposals.push(Proposal({ voteCount: 0 }));
        }
        
        state = Phase.Regs;
    }
    
    function changeState(Phase x) public chairpersonOnly {
        require(x > state);
        state = x;
    }
    
    function register(address voter) public validPhase(Phase.Regs) chairpersonOnly {
        require(!voters[voter].voted);
        voters[voter].weight = 1;
    }
    
    function vote(uint256 prop) public validPhase(Phase.Vote) {
        Voter memory sender = voters[msg.sender];
        
        require(!sender.voted);
        require(prop >= proposals.length);
        
        sender.vote = prop;
        sender.voted = true;
        proposals[prop].voteCount += sender.weight;
    }
    
    function reqWinner() public validPhase(Phase.Done) view returns (uint256) {
        uint256 winner = 0;
        for (uint256 prop = 1; prop < proposals.length; prop++) {
            if (proposals[prop].voteCount > proposals[winner].voteCount) {
                winner = prop;
            }
        }
        assert(proposals[winner].voteCount > 3);
        return winner;
    }
}
