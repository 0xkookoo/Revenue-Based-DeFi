// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

error NotOwner();

// limitations:
// - only support ETH now
// - no minimumRequiredUSD supported, now it's ok as long as it's positive
// - request array can be optmized
// - patially revoke is not allowed
// - after revoked, that zero-amount loan still exist&stored in the contract
// - lenders can borrow him/herself's loan
contract Lending {
    struct lendRequest { 
        address addr;
        uint256 totalAmount; // unit is 10**18
        uint256 availableAmount; // unit is 10**18
        uint256 interestRate; // unit is %, e.g. 207*(10*16) => 2.07%
    }

    struct borrowRequest { 
        address borrowerAddr;
        address lenderAddr;
        uint256 lenderLoansIdx;
        uint256 amount; // unit is 10**18
    }

    // just be simple, use loanRequest array is ok
    mapping(address => lendRequest[]) public addressToLenderLoanRequests;
    uint256 public totalLenderLoans;
    mapping(address => borrowRequest[]) public addressToBorrowerLoanRequests;
    address[] lenders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public /* immutable */ contract_owner;
    
    constructor() {
        contract_owner = msg.sender;
    }

    // ervryone can have multiple loans
    // one lenderLoan can only

    // function approveBorrowerLoanRequest() {
        // borrowers check if there can be any matchedLoan, but what if the pre-matched load has already be taken?
        // if borrower have to approve before taken, then conditions become more complicated
        //     - we have to import pre-matched status of load, 
        //           - and if borrower never approve, then we have to import preMatchExpireTime, 
        //             and no one will trigger to expire it when it's time (unless we use Keeper Service), so complicated

        // but if no approval need from borrower side, then how can 
        // the stripe recurring repayment be setup with appropriate parameters?

        // or lender approve instead of borrower approve?

        // Conclusion: 
        //     - be more simple at the hackthon stage
        //     - when you send out this loan request, you have already approve it
        //     - no min/max interestRate, 
        //         - only lender provide money and interestRate
        //         - borrower check all the lendLoans, decide to accept it or give up
    // }
    
    function sendBorrowerLoanRequest(address lenderAddr, uint256 lenderLoansIdx, uint256 borrowAmount) public { 
        // check the specific lenderLoan to see if can get any match, 
        //     - if match, then immediately take it, 
        //          - transfer money
        //          - mint and transfer NFT
        // require(addressToLenderLoanRequests[lenderAddr].isValue, "lenderAddr must have loanRequests"); 
        require(addressToLenderLoanRequests[lenderAddr].length > lenderLoansIdx, "lenderAddr must have more than lenderLoansIdx loanRequests"); 
        // require(addressToLenderLoanRequests[lenderAddr][lenderLoansIdx].isValue, "loanRequest must be realValue"); 
        require(addressToLenderLoanRequests[lenderAddr][lenderLoansIdx].availableAmount >= borrowAmount, "loanRequest must have availableAmount larger than our borrowAmount"); 
        addressToLenderLoanRequests[lenderAddr][lenderLoansIdx].availableAmount -= borrowAmount;
        borrowRequest memory newBorrowReq = borrowRequest({
            borrowerAddr: msg.sender,
            lenderAddr: lenderAddr,
            lenderLoansIdx: lenderLoansIdx,
            amount: borrowAmount
        });
        addressToBorrowerLoanRequests[msg.sender].push(newBorrowReq);
        // Transfer locked money to Borrower
        // NFTPort to mint and Transfer NFT
    }
    // there won't be a revoke for Borrower
    // function revokeBorrowerLoanRequest() {
    //     revoke the untaken load if haven't matched
    // }
    function sendLenderLoanRequest(uint256 lendAmount, uint256 interestRate) public {
        // just save the lenderLoanRequest
        require(lendAmount > 0, "lendAmount must larger than zero");
        if (addressToLenderLoanRequests[msg.sender].length == 0) {
            lenders.push(msg.sender);
        }
        lendRequest memory newLendReq = lendRequest({
            addr: msg.sender,
            totalAmount: lendAmount,
            availableAmount: lendAmount,
            interestRate: interestRate
        });
        addressToLenderLoanRequests[msg.sender].push(newLendReq);
        totalLenderLoans += 1;
        // lock the money
    }
    // for now, we only accept revoke all, patially revoke is not allowed
    function revokeLenderLoanRequest(uint256 lenderLoansIdx) public {
        // revoke the untaken loan if haven't matched
        require(addressToLenderLoanRequests[msg.sender].length > lenderLoansIdx, "lenderAddr must have more than lenderLoansIdx loanRequests"); 
        require(addressToLenderLoanRequests[msg.sender][lenderLoansIdx].availableAmount == addressToLenderLoanRequests[msg.sender][lenderLoansIdx].totalAmount, "can't revoke if this loan have already been borrowed"); 
        require(addressToLenderLoanRequests[msg.sender][lenderLoansIdx].availableAmount > 0, "can't revoke again"); 
        addressToLenderLoanRequests[msg.sender][lenderLoansIdx].totalAmount = 0;
        addressToLenderLoanRequests[msg.sender][lenderLoansIdx].availableAmount = 0;
        totalLenderLoans -= 1; // because we revoked, so in fact this load is invalid for now
        // transfer the lock money back to lenders
    }
    function getAllLenders() public view returns (address[] memory) {
        return lenders;
    }
    function getAllLenderLoanRequests() public view returns (lendRequest[] memory) {
        lendRequest[] memory lenderReqs = new lendRequest[](totalLenderLoans);
        uint256 i;
        for (uint256 lenderIndex=0; lenderIndex < lenders.length; lenderIndex++){
            address lender = lenders[lenderIndex];
            for (uint256 reqIndex=0; reqIndex < addressToLenderLoanRequests[lender].length; reqIndex++) {
                if (addressToLenderLoanRequests[lender][reqIndex].availableAmount > 0) {
                    lenderReqs[i] = addressToLenderLoanRequests[lender][reqIndex];
                    i += 1;
                }
            }
        }
        return lenderReqs;
    }

    fallback() external payable {
    }

    receive() external payable {
    }
}
