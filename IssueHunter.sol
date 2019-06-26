pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract IssueHunter is Ownable {
    using SafeMath for uint256;

    struct Issue {
        uint256 id;
        address owner;
        string repo;
        string title;
        string[] tags;
        uint256 price;
        bool solved;
        bool active;
    }

    mapping(address => string) id;
    mapping(address => uint256[]) issueBy;
    mapping(address => uint256[]) solvedIssueOf;
    Issue[] issues;
    IERC20 erc20;

    constructor(IERC20 default_erc20) public {
        erc20 = default_erc20;
    }

    function applyAccount(string github_id) public {
        id[msg.sender] = github_id;
    }

    function changeERC20(IERC20 new_erc20) public onlyOwner {
        erc20 = new_erc20;
    }

    function makeIssue(string repo, string title, string[] tags, uint256 price) public {
        require(msg.sender.balance >= price);
        Issue memory issue = Issue(
            issues.length, msg.sender, repo, title, tags, price, false, true
        );
        issues.push(issue);
        issueBy[msg.sender].push(issues.length - 1);
    }

    function editIssue(uint256 _id, string repo, string title, string[] tags, uint256 price, bool active) public {
        require(issues[_id].owner == msg.sender && issues[_id].solved == false);
        Issue memory issue = Issue(
            _id, msg.sender, repo, title, tags, price, issues[_id].solved, active
        );
        issues[_id] = issue;
    }
}
