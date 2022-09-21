const { ethers } = require("hardhat")
const { expect, assert } = require("chai")

describe("Lending", function () {
    let lendingFactory, lending
    beforeEach(async function () {
        lendingFactory = await ethers.getContractFactory("Lending")
        lending = await lendingFactory.deploy()
    })

    it("Should start with an empty borrowers", async function () {
        const allBorrowers = await lending.getAllBorrowers()
        // console.log(`allBorrowers' length is: ${allBorrowers.length}`)
        assert.equal(allBorrowers.length, "0")
    })

    it("Should pass with borrow + accept + repay + repay_more", async function () {
        const [addr1, addr2, addr3] = await ethers.getSigners()
        await lending.sendBorrowLoanRequest("100000000000000000000")

        const addr1BorrowerReq = await lending.getBorrowerLoanByAddr(
            addr1.address
        )
        // console.log(`addr1BorrowerReq' is: ${addr1BorrowerReq}`)
        assert.equal(addr1BorrowerReq.amount, "100000000000000000000")

        const allBorrowerReqs1 = await lending.getAllBorrowerLoanRequests()
        assert.equal(
            allBorrowerReqs1[0].lenderAddr,
            "0x0000000000000000000000000000000000000000"
        )
        assert.equal(allBorrowerReqs1[0].amount, "100000000000000000000")
        assert.equal(allBorrowerReqs1[0].repaidAmount, "0")

        await lending.connect(addr2).acceptBorrowLoanRequest(addr1.address)
        const allBorrowerReqs2 = await lending.getAllBorrowerLoanRequests()
        assert.notEqual(
            allBorrowerReqs2[0].lenderAddr,
            "0x0000000000000000000000000000000000000000"
        )
        assert.equal(allBorrowerReqs2[0].amount, "100000000000000000000")
        assert.equal(allBorrowerReqs2[0].repaidAmount, "0")

        await lending.connect(addr1).repayment("20000000000000000000")
        const allBorrowerReqs3 = await lending.getAllBorrowerLoanRequests()
        assert.notEqual(
            allBorrowerReqs3[0].lenderAddr,
            "0x0000000000000000000000000000000000000000"
        )
        assert.equal(allBorrowerReqs3[0].amount, "100000000000000000000")
        assert.equal(allBorrowerReqs3[0].repaidAmount, "20000000000000000000")

        await lending.connect(addr1).repayment("90000000000000000000")
        const allBorrowerReqs4 = await lending.getAllBorrowerLoanRequests()
        assert.notEqual(
            allBorrowerReqs4[0].lenderAddr,
            "0x0000000000000000000000000000000000000000"
        )
        assert.equal(allBorrowerReqs4[0].amount, "100000000000000000000")
        assert.equal(allBorrowerReqs4[0].repaidAmount, "110000000000000000000")

        await expect(
            lending.connect(addr1).repayment("10000000000000000000")
        ).to.be.revertedWith("cannot repay more than (loan plus its interest)!")
    })
})
