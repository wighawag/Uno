module.exports = async function ({ ethers, deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer, dev } = await getNamedAccounts()
    const signer = await ethers.getSigner(deployer);

    const RewardPool = await deployments.get("RewardPool")
    const token = await deployments.get("UnoToken")
    const mockBusd = await ethers.getContract("MockBUSD")
    const busd = new ethers.Contract(mockBusd.abi, mockBusd.address, signer)

    const factory = await deployments.get("PancakeFactory")
    const Factory = await ethers.getContract(factory.abi, factory.address, deployer)

    console.log(Factory.address)
    console.log(busd.address)
    console.log(token.address)

    const pair = await Factory.createPair(busd.address, token.address)

    console.log(pair)

    await deploy('UnoLPStaking', {
        from: deployer,
        args: [pair, token.address, RewardPool.address, "50000000", "600"],
        log: true,
    })
}

module.exports.tags = ["UnoLPStaking"]
module.exports.dependencies = ["UnoToken", "RewardPool"]

