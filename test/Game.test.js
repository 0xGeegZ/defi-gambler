// const { expectRevert, time } = require("@openzeppelin/test-helpers")
// const CakeToken = artifacts.require("CakeToken")
// const SyrupBar = artifacts.require("SyrupBar")
// const MasterChef = artifacts.require("MasterChef")
// const MockBEP20 = artifacts.require("libs/MockBEP20")

// contract("Game", ([alice, bob, carol, dev, minter]) => {
//   beforeEach(async () => {
//     this.cake = await CakeToken.new({ from: minter })
//     this.syrup = await SyrupBar.new(this.cake.address, { from: minter })
//     this.lp1 = await MockBEP20.new("LPToken", "LP1", "1000000", {
//       from: minter
//     })
//     this.lp2 = await MockBEP20.new("LPToken", "LP2", "1000000", {
//       from: minter
//     })
//     this.lp3 = await MockBEP20.new("LPToken", "LP3", "1000000", {
//       from: minter
//     })
//     this.chef = await MasterChef.new(
//       this.cake.address,
//       this.syrup.address,
//       dev,
//       "1000",
//       "100",
//       { from: minter }
//     )
//     await this.cake.transferOwnership(this.chef.address, { from: minter })
//     await this.syrup.transferOwnership(this.chef.address, { from: minter })

//     await this.lp1.transfer(bob, "2000", { from: minter })
//     await this.lp2.transfer(bob, "2000", { from: minter })
//     await this.lp3.transfer(bob, "2000", { from: minter })

//     await this.lp1.transfer(alice, "2000", { from: minter })
//     await this.lp2.transfer(alice, "2000", { from: minter })
//     await this.lp3.transfer(alice, "2000", { from: minter })
//   })

//   it("initializing game from factory", async () => {})

//   // it("deposit/withdraw", async () => {
//   //   await this.chef.add("1000", this.lp1.address, true, { from: minter })
//   //   await this.chef.add("1000", this.lp2.address, true, { from: minter })
//   //   await this.chef.add("1000", this.lp3.address, true, { from: minter })

//   //   await this.lp1.approve(this.chef.address, "100", { from: alice })
//   //   await this.chef.deposit(1, "20", { from: alice })
//   //   await this.chef.deposit(1, "0", { from: alice })
//   //   await this.chef.deposit(1, "40", { from: alice })
//   //   await this.chef.deposit(1, "0", { from: alice })
//   //   assert.equal((await this.lp1.balanceOf(alice)).toString(), "1940")
//   //   await this.chef.withdraw(1, "10", { from: alice })
//   //   assert.equal((await this.lp1.balanceOf(alice)).toString(), "1950")
//   //   assert.equal((await this.cake.balanceOf(alice)).toString(), "999")
//   //   assert.equal((await this.cake.balanceOf(dev)).toString(), "100")

//   //   await this.lp1.approve(this.chef.address, "100", { from: bob })
//   //   assert.equal((await this.lp1.balanceOf(bob)).toString(), "2000")
//   //   await this.chef.deposit(1, "50", { from: bob })
//   //   assert.equal((await this.lp1.balanceOf(bob)).toString(), "1950")
//   //   await this.chef.deposit(1, "0", { from: bob })
//   //   assert.equal((await this.cake.balanceOf(bob)).toString(), "125")
//   //   await this.chef.emergencyWithdraw(1, { from: bob })
//   //   assert.equal((await this.lp1.balanceOf(bob)).toString(), "2000")
//   // })

//   // it("staking/unstaking", async () => {
//   //   await this.chef.add("1000", this.lp1.address, true, { from: minter })
//   //   await this.chef.add("1000", this.lp2.address, true, { from: minter })
//   //   await this.chef.add("1000", this.lp3.address, true, { from: minter })

//   //   await this.lp1.approve(this.chef.address, "10", { from: alice })
//   //   await this.chef.deposit(1, "2", { from: alice }) //0
//   //   await this.chef.withdraw(1, "2", { from: alice }) //1

//   //   await this.cake.approve(this.chef.address, "250", { from: alice })
//   //   await this.chef.enterStaking("240", { from: alice }) //3
//   //   assert.equal((await this.syrup.balanceOf(alice)).toString(), "240")
//   //   assert.equal((await this.cake.balanceOf(alice)).toString(), "10")
//   //   await this.chef.enterStaking("10", { from: alice }) //4
//   //   assert.equal((await this.syrup.balanceOf(alice)).toString(), "250")
//   //   assert.equal((await this.cake.balanceOf(alice)).toString(), "249")
//   //   await this.chef.leaveStaking(250)
//   //   assert.equal((await this.syrup.balanceOf(alice)).toString(), "0")
//   //   assert.equal((await this.cake.balanceOf(alice)).toString(), "749")
//   // })
// })
