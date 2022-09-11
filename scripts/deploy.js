// imports
const { ethers, run, network } = require("hardhat")

// async main
async function main() {
    const LendingFactoryFactory = await ethers.getContractFactory("Lending")
    console.log("Deploying contract...")
    const lending = await LendingFactoryFactory.deploy()
    await lending.deployed()
    console.log(`Deployed contract to: ${lending.address}`)
    // what happens when we deploy to our hardhat network?
    if (network.config.chainId === 4 && process.env.ETHERSCAN_API_KEY) {
        console.log("Waiting for block confirmations...")
        await lending.deployTransaction.wait(6)
        await verify(lending.address, [])
    }

    const allLenders = await lending.getAllLenders()
    console.log(`All Lenders are: ${allLenders}`)

    // Update the current value
    const transactionResponse = await lending.sendLenderLoanRequest(
        100,
        2070000000000
    )
    await transactionResponse.wait(1)
    const updatedAllLenders = await lending.getAllLenders()
    console.log(`Updated all lenders are: ${updatedAllLenders}`)
}

// async function verify(contractAddress, args) {
const verify = async (contractAddress, args) => {
    console.log("Verifying contract...")
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
        })
    } catch (e) {
        if (e.message.toLowerCase().includes("already verified")) {
            console.log("Already Verified!")
        } else {
            console.log(e)
        }
    }
}

// main
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
