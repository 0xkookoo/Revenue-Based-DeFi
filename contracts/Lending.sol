// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "hardhat/console.sol";

// limitations:
// - only support ETH now
// - no minimumRequiredUSD supported, now it's ok as long as it's positive
// - request array can be optmized
// - patially revoke is not allowed
// - after revoked, that zero-amount loan still exist&stored in the contract
// - lenders can borrow him/herself's loan
contract Lending {
    struct borrowRequest {
        address borrowerAddr;
        address lenderAddr;
        uint256 amount; // unit is 10**18
        uint256 repaidAmount;
    }

    mapping(address => borrowRequest) public addressToBorrowerLoanRequest;
    address[] borrowers;

    address public contract_owner;
    uint256 public constant INTEREST_RATE = 10;

    constructor() {
        contract_owner = msg.sender;
    }

    function sendBorrowLoanRequest(uint256 borrowAmount) public {
        require(
            addressToBorrowerLoanRequest[msg.sender].borrowerAddr ==
                address(0x0),
            "one address can only send one borrow loan!"
        );
        borrowRequest memory newBorrowReq = borrowRequest({
            borrowerAddr: msg.sender,
            lenderAddr: address(0x0),
            amount: borrowAmount,
            repaidAmount: 0
        });
        addressToBorrowerLoanRequest[msg.sender] = newBorrowReq;
        borrowers.push(msg.sender);
    }

    function repayment(uint256 repaymentAmount) public {
        require(
            addressToBorrowerLoanRequest[msg.sender].borrowerAddr == msg.sender,
            "can only repay self's loan, or self has a loan already!"
        );
        // console.log(
        //     "amount: %s, inter:%s, plusInterest: %s",
        //     addressToBorrowerLoanRequest[msg.sender].amount,
        //     1 + INTEREST_RATE / 100,
        //     ((addressToBorrowerLoanRequest[msg.sender].amount *
        //         (100 + INTEREST_RATE)) / 100)
        // );
        require(
            addressToBorrowerLoanRequest[msg.sender].repaidAmount +
                repaymentAmount <=
                ((addressToBorrowerLoanRequest[msg.sender].amount *
                    (100 + INTEREST_RATE)) / 100),
            "cannot repay more than (loan plus its interest)!"
        );
        addressToBorrowerLoanRequest[msg.sender]
            .repaidAmount += repaymentAmount;
    }

    function acceptBorrowLoanRequest(address borrowerAddr) public {
        require(
            addressToBorrowerLoanRequest[borrowerAddr].borrowerAddr !=
                address(0x0),
            "borrower must have a loan already!"
        );
        require(
            addressToBorrowerLoanRequest[borrowerAddr].lenderAddr ==
                address(0x0),
            "borrower's loan has been taken already!"
        );
        require(
            addressToBorrowerLoanRequest[borrowerAddr].borrowerAddr !=
                msg.sender,
            "cannot lend to self's loan!"
        );
        addressToBorrowerLoanRequest[borrowerAddr].lenderAddr = msg.sender;
        // transfer the money to borrower
        // mint NFT to both
    }

    function getAllBorrowers() public view returns (address[] memory) {
        return borrowers;
    }

    function getAllBorrowerLoanRequests()
        public
        view
        returns (borrowRequest[] memory)
    {
        borrowRequest[] memory borrowerReqs = new borrowRequest[](
            borrowers.length
        );
        for (uint256 idx = 0; idx < borrowers.length; idx++) {
            borrowerReqs[idx] = addressToBorrowerLoanRequest[borrowers[idx]];
        }
        return borrowerReqs;
    }

    function getBorrowerLoanByAddr(address borrowerAddr)
        public
        view
        returns (borrowRequest memory)
    {
        return addressToBorrowerLoanRequest[borrowerAddr];
    }

    // fallback() external payable {
    // }

    // receive() external payable {
    // }
}
