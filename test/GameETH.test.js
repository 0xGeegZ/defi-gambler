const { expectRevert, time, balance } = require("@openzeppelin/test-helpers")
const { BigNumber } = require("@ethersproject/bignumber")

const { assert } = require("chai")
const CakeToken = artifacts.require("CakeToken")
const SyrupBar = artifacts.require("SyrupBar")
// const MasterChef = artifacts.require("MasterChef")
const Game = artifacts.require("GameETH")

contract(
  "Game",
  ([
    alice,
    bob,
    carol,
    jean,
    peter,
    wiliam,
    julie,
    maurice,
    francis,
    elena,
    miranda,
    dev,
    minter
  ]) => {
    beforeEach(async () => {
      this.game = await Game.new(ethers.utils.parseEther("10"), {
        from: minter
      })
    })

    it("Tests", async () => {
      // await this.game.bet({ from: minter })
      // await this.game.bet({ from: alice })
      // await this.game.newInvestor({
      //   from: alice,
      //   value: ethers.utils.parseEther("0.5")
      // })
      // const numerator =
      // const numeratorTx = await this.game.numerator({
      //   from: alice,
      //   value: ethers.utils.parseEther("0.3")
      // })
      // const numerator = await numeratorTx.wait()
      // const numerator = await this.game.numerator({
      //   value: ethers.utils.parseEther("0.3")
      // })
      // const numerator = await this.game.numerator(
      //   ethers.utils.parseEther("0.1")
      // )
      // const denominator = await this.game.denominator()
      // console.log("===============================")
      // console.log(`${numerator} <= ${denominator}`)
      // console.log(numerator <= denominator)
      // console.log("===============================")
      // assert(numerator <= denominator)
      // alice, bob, carol, jean, peter, wiliam, julie, maurice, francis, elena, miranda
      // const balanceBefore = await this.game.getBalance(alice)
      // const balanceInitial = await balance.current(alice)
      // console.log(
      //   `Alice Initial Balance : ${ethers.utils.formatEther(
      //     balanceInitial.toString()
      //   )}`
      // )
      // const payable = { value: ethers.utils.parseEther("0.1") }
      // await this.game.bet({
      //   from: alice,
      //   ...payable
      // })
      // const balanceAfter = await this.game.getBalance(alice)
      // // console.log(`${ethers.utils.formatEther(balanceAfter.toString())}`)
      // const bet = await this.game.getBet(0)
      // console.log(`${JSON.stringify(bet)}`)
      // const bet2 = await this.game.getLastBet({ from: alice })
      // console.log(`${JSON.stringify(bet2)}`)
      // const claim = await this.game.claim({ from: alice })
      // console.log(`${claim.toString()}`)
      // await this.game.claim({ from: alice })
      // console.log(`${ethers.utils.formatEther(bet2[1].toString())}`)
      // assert.equal(ethers.utils.formatEther(balanceAfter.toString()), "0.091")
      // await this.game.bet({
      //   from: alice,
      //   ...payable
      // })
      // await this.game.bet({
      //   from: bob,
      //   ...payable
      // })
      // await this.game.bet({
      //   from: carol,
      //   ...payable
      // })
      // await this.game.bet({
      //   from: jean,
      //   ...payable
      // })
      // await this.game.bet({
      //   from: peter,
      //   ...payable
      // })
      // await this.game.bet({
      //   from: wiliam,
      //   ...payable
      // })
      // await this.game.bet({
      //   from: julie,
      //   ...payable
      // })
      // await this.game.bet({
      //   from: maurice,
      //   ...payable
      // })
      // await this.game.bet({
      //   from: francis,
      //   ...payable
      // })
      // await this.game.bet({
      //   from: elena,
      //   ...payable
      // })
      // await this.game.bet({
      //   from: miranda,
      //   ...payable
      // })
    })

    // it("should enter", async () => {
    //   const payable = { value: ethers.utils.parseEther("0.1") }
    //   await this.game.bet({
    //     from: alice,
    //     ...payable
    //   })

    //   const balanceAlice = await balance.current(alice)
    //   // console.log(
    //   //   `Alice Balance : ${ethers.utils.formatEther(
    //   //     balanceAlice.toString()
    //   //   )}`
    //   // )

    //   const balanceAliceContract = await this.game.getBalance(alice)
    //   // console.log(`${ethers.utils.formatEther(balanceAliceContract.toString())}`)

    //   assert.equal(
    //     ethers.utils.formatEther(balanceAliceContract.toString()),
    //     "0.091"
    //   )
    //   assert.isBelow(
    //     parseFloat(ethers.utils.formatEther(balanceAlice.toString())),
    //     9999.9
    //   )
    // })

    // it("should enter and increase investment", async () => {
    //   const payable = { value: ethers.utils.parseEther("0.1") }
    //   await this.game.bet({
    //     from: alice,
    //     ...payable
    //   })
    //   await this.game.increaseInvestment({
    //     from: alice,
    //     ...payable
    //   })

    //   const balanceAlice = await balance.current(alice)
    //   // console.log(
    //   //   `Alice Balance : ${ethers.utils.formatEther(balanceAlice.toString())}`
    //   // )

    //   const balanceAliceContract = await this.game.getBalance(alice)
    //   // console.log(
    //   //   `${ethers.utils.formatEther(balanceAliceContract.toString())}`
    //   // )

    //   assert.equal(
    //     ethers.utils.formatEther(balanceAliceContract.toString()),
    //     "0.191"
    //   )
    //   assert.isBelow(
    //     parseFloat(ethers.utils.formatEther(balanceAlice.toString())),
    //     9999.8
    //   )
    // })

    // it("should claim if win", async () => {
    // const numeratorTx = await this.game.numerator({
    //   from: alice,
    //   value: ethers.utils.parseEther("0.3")
    // })
    // const numerator = await numeratorTx.wait()
    // const numerator = await this.game.numerator({
    //   value: ethers.utils.parseEther("0.3")
    // })
    // const numerator = await this.game.numerator(ethers.utils.parseEther("1"))
    // const denominator = await this.game.denominator()
    // console.log("===============================")
    // console.log(`${numerator} <= ${denominator}`)
    // console.log(
    //   BigNumber.from(numerator.toString()) <
    //     BigNumber.from(denominator.toString())
    // )
    // console.log("===============================")
    // assert(numerator <= denominator)
    // assert(
    //   BigNumber.from(numerator.toString()) <
    //     BigNumber.from(denominator.toString())
    // )
    //   const payable = { value: ethers.utils.parseEther("1") }
    //   await this.game.bet({
    //     from: alice,
    //     ...payable
    //   })

    //   const bet = await this.game.getLastBet({ from: alice })

    //   if (!bet[4]) assert(false, "not win")
    //   const balanceBefore = await this.game.getBalance(alice)
    //   console.log(`${ethers.utils.formatEther(balanceBefore.toString())}`)

    //   const balanceInitial = await balance.current(alice)
    //   console.log(
    //     `Alice Initial Balance : ${ethers.utils.formatEther(
    //       balanceInitial.toString()
    //     )}`
    //   )
    //   await this.game.claim({ from: alice })

    //   const balanceAfter = await this.game.getBalance(alice)
    //   console.log(`${ethers.utils.formatEther(balanceAfter.toString())}`)

    //   const balanceUpdated = await balance.current(alice)
    //   console.log(
    //     `Alice Updated Balance : ${ethers.utils.formatEther(
    //       balanceUpdated.toString()
    //     )}`

    //     // getContractBalance
    //   )
    // })

    // it("should not enter multiple times", async () => {
    //   try {
    //     const payable = { value: ethers.utils.parseEther("0.1") }
    //     await this.game.bet({
    //       from: alice,
    //       ...payable
    //     })
    //     await this.game.bet({
    //       from: alice,
    //       ...payable
    //     })
    //     assert(false)
    //   } catch (error) {
    //     assert(error)
    //   }
    // })

    // it("should not claim twice", async () => {
    //   try {
    //     const payable = { value: ethers.utils.parseEther("0.1") }
    //     await this.game.bet({
    //       from: alice,
    //       ...payable
    //     })

    //     const bet = await this.game.getLastBet({ from: alice })
    //     // console.log(`${JSON.stringify(bet)}`)

    //     if (!bet[4]) assert(false, "not win")

    //     await this.game.claim({ from: alice })
    //     await this.game.claim({ from: alice })
    //     assert(false)
    //   } catch (error) {
    //     assert(error)
    //   }
    // })

    //TODO getMinInvestment check update
  }
)
