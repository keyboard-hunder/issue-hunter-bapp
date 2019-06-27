pragma solidity ^0.4.24;
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
        string tags;
        uint256 price;
        bool solved;
        bool active;
    }

    mapping(address => string) public githubId;
    mapping(string => bool) usedId;
    mapping(address => uint256[]) public issueMadeBy;
    mapping(address => uint256[]) public issueSolvedBy;
    Issue[] public issues;
    IERC20 public erc20;

    constructor(IERC20 default_erc20) public {
        erc20 = default_erc20;
    }

    function applyAccount(string github_id) public {
        require(usedId[github_id] == false);
        githubId[msg.sender] = github_id;
        usedId[github_id] = true;
        erc20.transfer(msg.sender, 100);
    }

    function assignAccountToNewAddress(address new_address) public {
        githubId[new_address] = githubId[msg.sender];
        githubId[msg.sender] = "";
    }

    function changeERC20(IERC20 new_erc20) public onlyOwner {
        erc20 = new_erc20;
    }

    function makeIssue(string repo, string title, string tags, uint256 price) public {
        erc20.transferFrom(msg.sender, this, price);

        Issue memory issue = Issue(
            issues.length, msg.sender, repo, title, tags, price, false, true
        );
        issues.push(issue);
        issueMadeBy[msg.sender].push(issues.length.sub(1));
    }

    function editIssueContents(uint256 _id, string repo, string title, string tags, bool active) public {
        require(issues[_id].owner == msg.sender && issues[_id].solved == false);

        Issue memory issue = Issue(
            _id, msg.sender, repo, title, tags, issues[_id].price, issues[_id].solved, active
        );
        issues[_id] = issue;
    }

    function editIssuePrice(uint256 _id, uint256 price) public {
        require(issues[_id].owner == msg.sender && issues[_id].solved == false);

        if (issues[_id].price > price) {
            erc20.transfer(msg.sender, issues[_id].price.sub(price));
        }
        else if (issues[_id].price < price) {
            erc20.transferFrom(msg.sender, this, price.sub(issues[_id].price));
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
