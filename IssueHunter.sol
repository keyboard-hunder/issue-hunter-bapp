pragma solidity ^0.5.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract IssueHunter is Ownable {
    using SafeMath for uint256;

    struct Issue {
        uint256 id;
        address owner;
        string repoURL;
        uint256 issueNumber;
        string title;
        string tags;
        uint256 price;
        bool solved;
        bool active;
    }

    mapping(address => string) public addressToGithub;
    mapping(string => address) public githubToAddress;
    mapping(string => bool) isExistedGithub;
    mapping(address => uint256[]) public issueMadeBy;
    mapping(address => uint256[]) public issueSolvedBy;
    Issue[] public issues;
    IERC20 public erc20;

    constructor(IERC20 default_erc20) public {
        erc20 = default_erc20;
    }

    function matchedIssue(string memory repoURL, uint256 issueNumber) public view returns (uint256 id) {
        for(uint i=0; i<issues.length; ++i) {
            if(!issues[i].solved) {
                if(keccak256(abi.encodePacked(issues[i].repoURL)) == keccak256(abi.encodePacked(repoURL)) && 
                    issues[i].issueNumber == issueNumber) {
                    return issues[i].id;
                }
            }
        }

        return uint256(-1);
    }

    function getAddressByGithubId(string memory githubId) public view returns (address) {
        return githubToAddress[githubId];
    }

    function applyAccount(string memory github_id) public {
        require(isExistedGithub[github_id] == false);
        addressToGithub[msg.sender] = github_id;
        githubToAddress[github_id] = msg.sender;
        isExistedGithub[github_id] = true;
        erc20.transfer(msg.sender, 100);
    }

    function changeERC20(IERC20 new_erc20) public onlyOwner {
        erc20 = new_erc20;
    }

    function makeIssue(address who, string memory repo, uint256 issueNumber, string memory title, string memory tags, uint256 price) public onlyOwner {
        erc20.transferFrom(who, address(this), price);

        Issue memory issue = Issue(
            issues.length, who, repo, issueNumber, title, tags, price, false, true
        );
        issues.push(issue);
        issueMadeBy[who].push(issues.length.sub(1));
    }

    function editIssueContents(uint256 _id, string memory repo, uint256 issueNumber, string memory title, string memory tags, bool active) public onlyOwner {
        require(issues[_id].solved == false);

        Issue memory issue = Issue(
            _id, issues[_id].owner, repo, issueNumber, title, tags, issues[_id].price, issues[_id].solved, active
        );
        issues[_id] = issue;
    }

    function editIssuePrice(uint256 _id, uint256 price) public onlyOwner {
        require(issues[_id].solved == false);

        if (issues[_id].price > price) {
            erc20.transfer(issues[_id].owner, issues[_id].price.sub(price));
        }
        else if (issues[_id].price < price) {
            erc20.transferFrom(issues[_id].owner, address(this), price.sub(issues[_id].price));
        }

        issues[_id].price = price;
    }

    function _markSolvedIssue(uint256 _id, address by) internal onlyOwner {
        require(issues[_id].owner != address(0) && issues[_id].solved == false);
        issues[_id].solved = true;
        issueSolvedBy[by].push(_id);
    }

    function solve(uint256 _id, address by) public onlyOwner {
        _markSolvedIssue(_id, by);
        erc20.transfer(by, issues[_id].price);
    }
}
