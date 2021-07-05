const { expectRevert, time, balance } = require("@openzeppelin/test-helpers")
const { BigNumber } = require("@ethersproject/bignumber")

const { assert } = require("chai")
const CakeToken = artifacts.require("CakeToken")
const SyrupBar = artifacts.require("SyrupBar")
// const MasterChef = artifacts.require("MasterChef")
const Game = artifacts.require("Game")

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
      this.game = await Game.new(ethers.utils.parseEther("1"), { from: minter })
    })

    it("Tests", async () => {
      try {
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
        // console.log(`${ethers.utils.formatEther(balanceAfter.toString())}`)
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
      } catch (error) {
        console.log("🚀 ~ file: Game.test.js ~ line 26 ~ it ~ error", error)
        assert(!error)
      }
    })

    it("should enter", async () => {
      const payable = { value: ethers.utils.parseEther("0.1") }
      await this.game.bet({
        from: alice,
        ...payable
      })

      const balanceAlice = await balance.current(alice)
      // console.log(
      //   `Alice Balance : ${ethers.utils.formatEther(
      //     balanceAlice.toString()
      //   )}`
      // )

      const balanceAliceContract = await this.game.getBalance(alice)
      // console.log(`${ethers.utils.formatEther(balanceAliceContract.toString())}`)

      assert.equal(
        ethers.utils.formatEther(balanceAliceContract.toString()),
        "0.091"
      )
      assert.isBelow(
        parseFloat(ethers.utils.formatEther(balanceAlice.toString())),
        9999.9
      )
    })

    it("should enter and increase investment", async () => {
      const payable = { value: ethers.utils.parseEther("0.1") }
      await this.game.bet({
        from: alice,
        ...payable
      })
      await this.game.increaseInvestment({
        from: alice,
        ...payable
      })

      const balanceAlice = await balance.current(alice)
      // console.log(
      //   `Alice Balance : ${ethers.utils.formatEther(balanceAlice.toString())}`
      // )

      const balanceAliceContract = await this.game.getBalance(alice)
      // console.log(
      //   `${ethers.utils.formatEther(balanceAliceContract.toString())}`
      // )

      assert.equal(
        ethers.utils.formatEther(balanceAliceContract.toString()),
        "0.191"
      )
      assert.isBelow(
        parseFloat(ethers.utils.formatEther(balanceAlice.toString())),
        9999.8
      )
    })

    it("should not enter multiple times", async () => {
      try {
        const payable = { value: ethers.utils.parseEther("0.1") }
        await this.game.bet({
          from: alice,
          ...payable
        })
        await this.game.bet({
          from: alice,
          ...payable
        })
        assert(false)
      } catch (error) {
        assert(error)
      }
    })

    //TODO getMinInvestment check update
  }
)
