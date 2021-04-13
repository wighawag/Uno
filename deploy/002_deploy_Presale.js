module.exports = async function ({ ethers, deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer, dev } = await getNamedAccounts()

    //const mockbusd = await ethers.getContractAt('0xA8E0f600624739d34F7569971dE7F1fCb0F9c5B6', mockBUSD)

    const mockBusd = await deployments.getArtifact("MockBUSD");
    const busd = new ethers.Contract('0xA8E0f600624739d34F7569971dE7F1fCb0F9c5B6', mockBusd.abi)

    const token = await deployments.get("UnoToken")

    await deploy('UnoPresale', {
        from: deployer,
        args: [busd.address, token.address],
        log: true,
    })
}

module.exports.tags = ["UnoPresale"]
module.exports.dependencies = ["UnoToken"]
