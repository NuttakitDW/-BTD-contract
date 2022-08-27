// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBitToonDAO.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SaleBTD is Ownable, ReentrancyGuard {

    IBitToonDAO public bitToonDAO;
    bytes32 public merkleRoot;

    bool public isPrivate = false;
    bool public isPublic = false;

    mapping(address => uint256) public _privateUserMintedAmount;

    constructor(IBitToonDAO _bitToonDAO) {
        setbitToonDAO(_bitToonDAO);
    }

    function setPublicMint(bool _bool) public onlyOwner {
        isPublic = _bool;
    }

    function setPrivateMint(bool _bool) public onlyOwner {
        isPrivate = _bool;
    }

    function setBitToonDAO(IBTD _bitToonDAO) public onlyOwner {
        address oldbitToonDAO = address(bitToonDAO);
        bitToonDAO = _bitToonDAO;
        address newbitToonDAO = address(_bitToonDAO);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        bytes32 _oldMerkleRoot = merkleRoot;
        merkleRoot = _merkleRoot;
    }

    function privateMint(bytes32[] calldata _proof,uint256 _maxAmount, uint256 _amount) public payable nonReentrant {
        // This is payable function.
        // You can tip BitToonDAO Team if you want.

        require(isPrivate == true, "Private mint is not open.");
        require(getTotalSupply() + _amount <= getMaxSupply(), "Over supply amount.");
        require(privateUserMintedAmount(msg.sender) + _amount <= _maxAmount, "Exceed Whitelist Limit");
        require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, _amount))), "Unauthorized user.");

        _privateUserMintedAmount[msg.sender] += _amount;
        bitToonDAO.safeMint(msg.sender,_amount);
    }

    function publicMint(uint256 _amount) public payable nonReentrant {
        // This is payable function.
        // You can tip BitToonDAO Team if you want.
        
        require(isPublic == true, "Public mint is not open.");
        require(tx.origin == msg.sender, "haha Contract can't call me");
        require(_amount <= 10, "Only 10 BTD per tx.");
        require(getTotalSupply() + _amount <= getMaxSupply(), "Over supply amount.");

        bitToonDAO.safeMint(msg.sender, _amount);
    }

    function withdraw(address _to) public onlyOwner {
        uint balanceOFContract = address(this).balance;
        require(balanceOFContract > 0, "Insufficient balance");
        (bool status,) = _to.call{value: balanceOFContract }("");
        require(status);
    }

    function withdrawToken(address _to, address _token) public onlyOwner {
        uint balanceOfContract = IERC20(_token).balanceOf(address(this));
        require(balanceOfContract > 0, "Insufficient balance");
        IERC20(_token).transfer(_to, balanceOfContract);
    }

    function privateUserMintedAmount(address _user) public view returns(uint256) {
        return _privateUserMintedAmount[_user];
    }

    function getTotalSupply() public view returns (uint256) {
        return bitToonDAO.totalSupply();
    }

    function getMaxSupply() public view returns (uint256) {
        return bitToonDAO.maxSupply();
    }
}