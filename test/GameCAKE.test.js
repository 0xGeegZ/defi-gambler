const { expectRevert, time, balance } = require("@openzeppelin/test-helpers")
// const { BigNumber } = require("@ethersproject/bignumber")
const { BigNumber } = require("ethers")

const { assert } = require("chai")
const CakeToken = artifacts.require("CakeToken")
const SyrupBar = artifacts.require("SyrupBar")
const MasterChef = artifacts.require("MasterChef")
const GameCAKE = artifacts.require("GameCAKE")

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
      this.cake = await CakeToken.new({ from: minter })
      this.syrup = await SyrupBar.new(this.cake.address, { from: minter })

      this.chef = await MasterChef.new(
        this.cake.address,
        this.syrup.address,
        dev,
        "1000",
        "100",
        { from: minter }
      )

      this.game = await GameCAKE.new(this.cake.address, this.chef.address, {
        from: minter
      })

      let value = ethers.utils.parseEther("100")

      // TODO is that better for cake token ? let value = ethers.utils.parseUnits("100", 18)

      await this.cake.mint(alice, value, { from: minter })

      await this.cake.transferOwnership(this.chef.address, { from: minter })
      await this.syrup.transferOwnership(this.chef.address, { from: minter })
    })

    it("Tests", async () => {
      let balanceAlice = await this.cake.balanceOf(alice)
      console.log(
        "🚀 starting balance - Alice",
        ethers.utils.formatEther(balanceAlice.toString())
      )

      // token.increaseAllowance(receiver.address, 1000)
      // await this.cake.approve(this.chef.address, "100", { from: alice })

      await this.cake.approve(
        this.game.address,
        ethers.utils.parseEther("10"),
        { from: alice }
      )

      console.log("🚀 betting 10 Cakes ")

      let value = ethers.utils.parseUnits("1", 18)

      const numerator = await this.game.numerator(value)
      const denominator = await this.game.denominator()
      const getBankroll = await this.game.getBankroll()

      console.log("===============================")
      console.log(
        "🚀 get Contract Bankroll",
        ethers.utils.formatEther(getBankroll.toString())
      )
      console.log(
        `${ethers.utils.formatEther(
          numerator.toString()
        )} <= ${ethers.utils.formatEther(denominator.toString())}`
      )
      console.log(numerator <= denominator)
      console.log("===============================")

      await this.game.bet(value, {
        from: alice
      })
      balanceAlice = await this.cake.balanceOf(alice)
      console.log(
        "🚀 balance - Alice",
        ethers.utils.formatEther(balanceAlice.toString())
      )

      const getLastBet = await this.game.getLastBet({ from: alice })
      console.log(`🚀 getLastBet : 
      playerAddress : ${getLastBet["0"]}
      amountBetted : ${getLastBet["1"]}
      numberRolled : ${getLastBet["2"]}
      winAmount : ${ethers.utils.formatEther(getLastBet["3"].toString())}
      isClaimed : ${getLastBet["4"]}
      isWinned : ${getLastBet["5"]}`)

      //TODO manage loose case
      await this.game.claim({ from: alice })
      balanceAlice = await this.cake.balanceOf(alice)
      console.log(
        "🚀 ending balance - Alice",
        ethers.utils.formatEther(balanceAlice.toString())
      )
    })

    // it("Tests", async () => {
    //   let balanceAlice = await this.cake.balanceOf(alice)
    //   console.log("🚀 starting balance - Alice", balanceAlice.toString())

    //   // token.increaseAllowance(receiver.address, 1000)
    //   // await this.cake.approve(this.chef.address, "100", { from: alice })
    //   await this.cake.approve(this.game.address, "10", { from: alice })

    //   console.log("🚀 betting 10 Cakes ")

    //   await this.game.bet(10, {
    //     from: alice
    //   })

    //   balanceAlice = await this.cake.balanceOf(alice)
    //   console.log("🚀 balance - Alice", balanceAlice.toString())

    //   const getContractBalance = await this.game.getContractBalance()
    //   console.log("🚀 balance - Contract", getContractBalance.toString())
    //   //TODO Should be equals to zero

    //   balanceSirup = await this.syrup.balanceOf(this.game.address)
    //   console.log("🚀 balance Staking - Game", balanceSirup.toString())

    //   // const balanceInGame = await this.game.getBalance(alice)
    //   // console.log("🚀 balance Game - Alice", balanceInGame.toString())

    //   const getTotalBalance = await this.game.getTotalBalance()
    //   console.log("🚀 getTotalBalance", getTotalBalance.toString())
    //   //TODO SgetTotalBalance sould = balanceSirup
    // })

    // it("Tests", async () => {
    //   let balanceAlice = await this.cake.balanceOf(alice)
    //   console.log("🚀 balanceAlice", balanceAlice.toString())

    //   await this.cake.approve(this.chef.address, "100", { from: alice })

    //   console.log("enterStaking - 25")

    //   await this.chef.enterStaking("25", { from: alice })

    //   let balanceSirup = await this.syrup.balanceOf(alice)
    //   console.log("🚀 balanceSirup", balanceSirup.toString())

    //   balanceAlice = await this.cake.balanceOf(alice)
    //   console.log("🚀 balanceAlice", balanceAlice.toString())

    //   //https://docs.openzeppelin.com/test-helpers/0.5/api#time
    //   // console.log("advanceBlockTo - 10")
    //   // await time.advanceBlockTo("1")
    //   // balanceAlice = await this.cake.balanceOf(alice)
    //   // console.log("🚀 balanceAlice", balanceAlice.toString())

    //   console.log("leaveStaking - 25")

    //   await this.chef.leaveStaking("25", { from: alice })
    //   balanceSirup = await this.syrup.balanceOf(alice)
    //   console.log("🚀 balanceSirup", balanceSirup.toString())

    //   balanceAlice = await this.cake.balanceOf(alice)
    //   console.log("🚀 balanceAlice", balanceAlice.toString())
    // })

    //     it('staking/unstaking', async () => {
    //       await this.chef.add('1000', this.lp1.address, true, { from: minter });
    //       await this.chef.add('1000', this.lp2.address, true, { from: minter });
    //       await this.chef.add('1000', this.lp3.address, true, { from: minter });

    //       await this.lp1.approve(this.chef.address, '10', { from: alice });
    //       await this.chef.deposit(1, '2', { from: alice }); //0
    //       await this.chef.withdraw(1, '2', { from: alice }); //1

    //       await this.cake.approve(this.chef.address, '250', { from: alice });
    //       await this.chef.enterStaking('240', { from: alice }); //3
    //       assert.equal((await this.syrup.balanceOf(alice)).toString(), '240');
    //       assert.equal((await this.cake.balanceOf(alice)).toString(), '10');
    //       await this.chef.enterStaking('10', { from: alice }); //4
    //       assert.equal((await this.syrup.balanceOf(alice)).toString(), '250');
    //       assert.equal((await this.cake.balanceOf(alice)).toString(), '249');
    //       await this.chef.leaveStaking(250);
    //       assert.equal((await this.syrup.balanceOf(alice)).toString(), '0');
    //       assert.equal((await this.cake.balanceOf(alice)).toString(), '749');

    //     });
  }
)
