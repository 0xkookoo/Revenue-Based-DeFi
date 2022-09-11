const { ethers } = require("hardhat")
const { expect, assert } = require("chai")

describe("Lending", function () {
    let lendingFactory, lending
    beforeEach(async function () {
        lendingFactory = await ethers.getContractFactory("Lending")
        lending = await lendingFactory.deploy()
    })

    it("Should start with an empty lenders", async function () {
        const allLenders = await lending.getAllLenders()
        const expectedValue = "0"
        // console.log(`allLenders' length is: ${allLenders.length}`)
        assert.equal(allLenders.length, expectedValue)
    })
})
