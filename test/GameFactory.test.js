const { expectRevert, time } = require("@openzeppelin/test-helpers")
const CakeToken = artifacts.require("CakeToken")
const SyrupBar = artifacts.require("SyrupBar")
const MasterChef = artifacts.require("MasterChef")
const GameFactory = artifacts.require("GameFactory")

contract("GameFactory", ([alice, bob, carol, dev, minter]) => {
  beforeEach(async () => {
    const GameFactory = await ethers.getContractFactory("GameFactory")
    const gameFactory = await GameFactory.deploy()
    await gameFactory.deployed()

    await gameFactory.createGame()

    let deployedGamesAddresses = await gameFactory.getDeployedGamesAdresses()

    // wait until the transaction is mined
    // await deployedGamesAddresses.wait()
    console.log(
      "🚀 ~ file: GameFactory.test.js ~ line 16 ~ beforeEach ~ deployedGamesAddresses",
      deployedGamesAddresses
    )

    // this.game1 = await GameFactory.createGame({ from: minter })
    // console.log(
    //   "🚀 ~ file: GameFactory.test.js ~ line 11 ~ beforeEach ~ this.game1",
    //   this.game1
    // )
  })

  it("initializing game from factory", async () => {})

  // it("deposit/withdraw", async () => {
  //   await this.chef.add("1000", this.lp1.address, true, { from: minter })
  //   await this.chef.add("1000", this.lp2.address, true, { from: minter })
  //   await this.chef.add("1000", this.lp3.address, true, { from: minter })

  //   await this.lp1.approve(this.chef.address, "100", { from: alice })
  //   await this.chef.deposit(1, "20", { from: alice })
  //   await this.chef.deposit(1, "0", { from: alice })
  //   await this.chef.deposit(1, "40", { from: alice })
  //   await this.chef.deposit(1, "0", { from: alice })
  //   assert.equal((await this.lp1.balanceOf(alice)).toString(), "1940")
  //   await this.chef.withdraw(1, "10", { from: alice })
  //   assert.equal((await this.lp1.balanceOf(alice)).toString(), "1950")
  //   assert.equal((await this.cake.balanceOf(alice)).toString(), "999")
  //   assert.equal((await this.cake.balanceOf(dev)).toString(), "100")

  //   await this.lp1.approve(this.chef.address, "100", { from: bob })
  //   assert.equal((await this.lp1.balanceOf(bob)).toString(), "2000")
  //   await this.chef.deposit(1, "50", { from: bob })
  //   assert.equal((await this.lp1.balanceOf(bob)).toString(), "1950")
  //   await this.chef.deposit(1, "0", { from: bob })
  //   assert.equal((await this.cake.balanceOf(bob)).toString(), "125")
  //   await this.chef.emergencyWithdraw(1, { from: bob })
  //   assert.equal((await this.lp1.balanceOf(bob)).toString(), "2000")
  // })

  // it("staking/unstaking", async () => {
  //   await this.chef.add("1000", this.lp1.address, true, { from: minter })
  //   await this.chef.add("1000", this.lp2.address, true, { from: minter })
  //   await this.chef.add("1000", this.lp3.address, true, { from: minter })

  //   await this.lp1.approve(this.chef.address, "10", { from: alice })
  //   await this.chef.deposit(1, "2", { from: alice }) //0
  //   await this.chef.withdraw(1, "2", { from: alice }) //1

  //   await this.cake.approve(this.chef.address, "250", { from: alice })
  //   await this.chef.enterStaking("240", { from: alice }) //3
  //   assert.equal((await this.syrup.balanceOf(alice)).toString(), "240")
  //   assert.equal((await this.cake.balanceOf(alice)).toString(), "10")
  //   await this.chef.enterStaking("10", { from: alice }) //4
  //   assert.equal((await this.syrup.balanceOf(alice)).toString(), "250")
  //   assert.equal((await this.cake.balanceOf(alice)).toString(), "249")
  //   await this.chef.leaveStaking(250)
  //   assert.equal((await this.syrup.balanceOf(alice)).toString(), "0")
  //   assert.equal((await this.cake.balanceOf(alice)).toString(), "749")
  // })
})
