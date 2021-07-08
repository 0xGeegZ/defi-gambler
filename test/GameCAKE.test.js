const { expectRevert, time, balance } = require("@openzeppelin/test-helpers")
// const { BigNumber } = require("@ethersproject/bignumber")
const { BigNumber } = require("ethers")

const { assert } = require("chai")
const CakeToken = artifacts.require("CakeToken")
const SyrupBar = artifacts.require("SyrupBar")
const MasterChef = artifacts.require("MasterChef")
const GameCAKE = artifacts.require("GameCAKE")

contract("Game", ([dev, minter, ...players]) => {
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
    for (let i = 0; i < players.length; i++) {
      // TODO is that better for cake token ? let value = ethers.utils.parseUnits("100", 18)
      await this.cake.mint(players[i], value, { from: minter })
    }

    value = ethers.utils.parseEther("10")
    await this.cake.mint(this.game.address, value, { from: minter })

    await this.cake.transferOwnership(this.chef.address, { from: minter })
    await this.syrup.transferOwnership(this.chef.address, { from: minter })
  })

  // it("should divest pool if needed", async () => {
  //   const MAX_INVESTORS = 10
  //   let value = ethers.utils.parseEther("1")
  //   // value = ethers.utils.parseUnits("1", 18)

  //   let player
  //   for (let i = 0; i < players.length; i++) {
  //     if (i == MAX_INVESTORS) {
  //       console.log("HOHOHOHOHO")
  //       //todo divest all plaeyrs
  //     }
  //     player = players[i]
  //     console.log(`🚀 launching game for player ${i} : ${player}`)

  //     await this.cake.approve(this.game.address, value, {
  //       from: player
  //     })

  //     await this.game.bet(value, {
  //       from: player
  //     })

  //     const getLastBet = await this.game.getLastBet({ from: player })

  //     console.log(`🚀 winned game for player ${i} : ${getLastBet["5"]}`)
  //   }
  //   // players.forEach(async player => {
  //   //   console.log(
  //   //     "🚀 ~ file: GameCAKE.test.js ~ line 74 ~ it ~ player",
  //   //     player
  //   //   )
  //   //   await this.cake.approve(this.game.address, value, {
  //   //     from: player
  //   //   })

  //   //   await this.game.bet(value, {
  //   //     from: player
  //   //   })

  //   //   const getLastBet = await this.game.getLastBet({ from: player })

  //   //   console.log(`🚀 winned game for player ${counter} : ${getLastBet["5"]}`)
  //   // })
  //   console.log(`🚀 starting winning Gamer for ${players.length} players`)

  //   assert(true)
  // })

  // it("should enter multiples players until maxplayers", async () => {
  //   const MAX_INVESTORS = 10
  //   let value = ethers.utils.parseEther("1")
  //   // value = ethers.utils.parseUnits("1", 18)

  //   let player
  //   for (let i = 0; i < players.length; i++) {
  //     if (i == MAX_INVESTORS) {
  //       console.log("HOHOHOHOHO")
  //       //todo divest all plaeyrs
  //     }
  //     player = players[i]
  //     console.log(`🚀 launching game for player ${i} : ${player}`)

  //     await this.cake.approve(this.game.address, value, {
  //       from: player
  //     })

  //     await this.game.bet(value, {
  //       from: player
  //     })

  //     const getLastBet = await this.game.getLastBet({ from: player })

  //     console.log(`🚀 winned game for player ${i} : ${getLastBet["5"]}`)
  //   }

  //   console.log(`🚀 starting winning Gamer for ${players.length} players`)

  //   assert(true)
  // })

  // it("should wait for player win to launch", async () => {
  //   const players = [
  //     alice,
  //     bob,
  //     carol,
  //     jean,
  //     peter,
  //     wiliam,
  //     julie,
  //     maurice,
  //     francis,
  //     elena,
  //     miranda
  //   ]
  //   let isWinningBet = false
  //   let counter = 0
  //   let value = ethers.utils.parseUnits("1", 18)
  //   let player
  //   while (!isWinningBet) {
  //     player = players[counter]
  //     counter++
  //     await this.cake.approve(this.game.address, value, {
  //       from: player
  //     })

  //     await this.game.bet(value, {
  //       from: player
  //     })

  //     const getLastBet = await this.game.getLastBet({ from: player })

  //     console.log(`🚀 winned game for player ${counter} : ${getLastBet["5"]}`)

  //     isWinningBet = getLastBet["5"]
  //   }
  //   console.log(`🚀 starting winning Gamer for player ${counter} : ${player}`)

  //   assert(true)
  // })

  it("LOG BASE", async () => {
    const alice = players[0]
    // **********
    // LOG BASE
    // **********
    let balanceAlice = await this.cake.balanceOf(alice)
    console.log(
      "🚀 starting balance - Alice",
      ethers.utils.formatEther(balanceAlice.toString())
    )

    // token.increaseAllowance(receiver.address, 1000)
    // await this.cake.approve(this.chef.address, "100", { from: alice })

    await this.cake.approve(this.game.address, ethers.utils.parseEther("1"), {
      from: alice
    })

    value = ethers.utils.parseUnits("1", 18)

    let numerator = await this.game.numerator(value)
    numerator = ethers.utils.formatEther(numerator.toString())

    let denominator = await this.game.denominator()
    denominator = ethers.utils.formatEther(denominator.toString())

    let getInvested = await this.game.getInvested()
    getInvested = ethers.utils.formatEther(getInvested.toString())

    let getTotalBalance = await this.game.getTotalBalance()
    getTotalBalance = ethers.utils.formatEther(getTotalBalance.toString())

    let balanceSirup = await this.syrup.balanceOf(this.game.address)
    balanceSirup = ethers.utils.formatEther(balanceSirup.toString())

    let balanceCake = await this.cake.balanceOf(this.game.address)
    balanceCake = ethers.utils.formatEther(balanceCake.toString())

    console.log("===============================")
    console.log("🚀 get Contract Invested", getInvested)
    console.log("🚀 get Contract Total Balance", getTotalBalance)
    console.log("🚀 get Contract Syrup Balance", balanceSirup.toString())
    console.log("🚀 get Contract Cake Balance", balanceCake.toString())

    console.log(`${numerator} <= ${denominator} : ${numerator <= denominator}`)
    console.log("===============================")

    console.log("🚀 betting 1 Cakes ")

    await this.game.bet(value, {
      from: alice
    })
    balanceAlice = await this.cake.balanceOf(alice)
    console.log(
      "🚀 balance - Alice",
      ethers.utils.formatEther(balanceAlice.toString())
    )

    getInvested = await this.game.getInvested()
    getInvested = ethers.utils.formatEther(getInvested.toString())

    getTotalBalance = await this.game.getTotalBalance()
    getTotalBalance = ethers.utils.formatEther(getTotalBalance.toString())

    balanceSirup = await this.syrup.balanceOf(this.game.address)
    balanceSirup = ethers.utils.formatEther(balanceSirup.toString())

    balanceCake = await this.cake.balanceOf(this.game.address)
    balanceCake = ethers.utils.formatEther(balanceCake.toString())

    console.log("===============================")
    console.log("🚀 get Contract Invested", getInvested)
    console.log("🚀 get Contract Total Balance", getTotalBalance)
    console.log("🚀 get Contract Syrup Balance", balanceSirup.toString())
    console.log("🚀 get Contract Cake Balance", balanceCake.toString())
    console.log("===============================")

    const getLastBet = await this.game.getLastBet({ from: alice })
    console.log(`🚀 getLastBet :
    playerAddress : ${getLastBet["0"]}
    amountBetted : ${getLastBet["1"]}
    numberRolled : ${getLastBet["2"]}
    winAmount : ${ethers.utils.formatEther(getLastBet["3"].toString())}
    isClaimed : ${getLastBet["4"]}
    isWinned : ${getLastBet["5"]}
    timelock : ${getLastBet["6"]} `)
    // from : ${getLastBet["7"]}
    // to :${ethers.utils.formatEther(getLastBet["8"].toString())}
    // bonus : ${ethers.utils.formatEther(getLastBet["9"].toString())}
    // bonus : ${getLastBet["9"]}

    // to : ${getLastBet["8"]}
    //TODO manage loose case
    await this.game.claimBonus({ from: alice })
    balanceAlice = await this.cake.balanceOf(alice)
    console.log(
      "🚀 balance after claim winned amount - Alice",
      ethers.utils.formatEther(balanceAlice.toString())
    )
    console.log("advanceBlockTo - 1 minutes")
    //TODO create getter & setter for minTimeToWithdraw = 604800
    await time.increase(60 * 60 * 24 * 10)

    //claimBet
    await this.game.claimBet({ from: alice })
    // divest = ethers.utils.formatEther(divest.toString())
    // console.log("🚀 divest amount - Alice", JSON.stringify(divest))

    balanceAlice = await this.cake.balanceOf(alice)
    balanceAlice = ethers.utils.formatEther(balanceAlice.toString())

    console.log("🚀 balance after unstacking bet amount - Alice", balanceAlice)

    //check contract bankroll
    getInvested = await this.game.getInvested()
    getInvested = ethers.utils.formatEther(getInvested.toString())
    console.log("🚀 get Contract Invested", getInvested)

    getTotalBalance = await this.game.getTotalBalance()
    getTotalBalance = ethers.utils.formatEther(getTotalBalance.toString())
    console.log("🚀 get Contract Total Balance", getTotalBalance)

    //TODO ERROR
    let getHouseProfit = await this.game.getHouseProfit()
    console.log(
      "🚀 get Contract Total Total Profit",
      JSON.stringify(getHouseProfit)
    )
    getHouseProfit = ethers.utils.formatEther(getHouseProfit.toString())
    console.log("🚀 get Contract Total Total Profit", getHouseProfit)

    // **********
    // ENDLOG BASE
    // **********
  })

  // it("should bet one cake and wait to claim back bet", async () => {
  //   let balanceAlice = await this.cake.balanceOf(alice)
  //   console.log(
  //     "🚀 starting balance - Alice",
  //     ethers.utils.formatEther(balanceAlice.toString())
  //   )

  //   // token.increaseAllowance(receiver.address, 1000)
  //   // await this.cake.approve(this.chef.address, "100", { from: alice })

  //   await this.cake.approve(this.game.address, ethers.utils.parseEther("1"), {
  //     from: alice
  //   })

  //   console.log("🚀 betting 1 Cakes ")

  //   let value = ethers.utils.parseUnits("1", 18)

  //   let numerator = await this.game.numerator(value)
  //   numerator = ethers.utils.formatEther(numerator.toString())

  //   let denominator = await this.game.denominator()
  //   denominator = ethers.utils.formatEther(denominator.toString())

  //   // let getInvested = await this.game.getInvested()
  //   // getInvested = ethers.utils.formatEther(getInvested.toString())

  //   let getTotalBalance = await this.game.getTotalBalance()
  //   getTotalBalance = ethers.utils.formatEther(getTotalBalance.toString())

  //   console.log("===============================")
  //   // console.log("🚀 get Contract Bankroll", getInvested)
  //   console.log("🚀 get Contract Total Balance", getTotalBalance)
  //   console.log(
  //     `${numerator} <= ${denominator} : ${numerator <= denominator}`
  //   )
  //   console.log("===============================")

  //   await this.game.bet(value, {
  //     from: alice
  //   })
  //   balanceAlice = await this.cake.balanceOf(alice)
  //   console.log(
  //     "🚀 balance - Alice",
  //     ethers.utils.formatEther(balanceAlice.toString())
  //   )

  //   const getLastBet = await this.game.getLastBet({ from: alice })
  //   console.log(`🚀 getLastBet :
  //   playerAddress : ${getLastBet["0"]}
  //   amountBetted : ${getLastBet["1"]}
  //   numberRolled : ${getLastBet["2"]}
  //   winAmount : ${ethers.utils.formatEther(getLastBet["3"].toString())}
  //   isClaimed : ${getLastBet["4"]}
  //   isWinned : ${getLastBet["5"]}`)

  //   //TODO manage loose case
  //   await this.game.claimBonus({ from: alice })
  //   balanceAlice = await this.cake.balanceOf(alice)
  //   console.log(
  //     "🚀 balance after claim winned amount - Alice",
  //     ethers.utils.formatEther(balanceAlice.toString())
  //   )
  //   console.log("advanceBlockTo - 1 minutes")
  //   //TODO create getter & setter for minTimeToWithdraw = 604800
  //   await time.increase(60)

  //   //divest
  //   await this.game.claimBet({ from: alice })
  //   // divest = ethers.utils.formatEther(divest.toString())
  //   // console.log("🚀 divest amount - Alice", JSON.stringify(divest))

  //   balanceAlice = await this.cake.balanceOf(alice)
  //   balanceAlice = ethers.utils.formatEther(balanceAlice.toString())

  //   console.log(
  //     "🚀 balance after unstacking bet amount - Alice",
  //     balanceAlice
  //   )

  //   //check contract bankroll
  //   // getInvested = await this.game.getInvested()
  //   // getInvested = ethers.utils.formatEther(getInvested.toString())
  //   // console.log("🚀 get Contract Bankroll", getInvested)

  //   getTotalBalance = await this.game.getTotalBalance()
  //   getTotalBalance = ethers.utils.formatEther(getTotalBalance.toString())
  //   console.log("🚀 get Contract Total Balance", getTotalBalance)
  // })

  // it("SHould be locked by timelock", async () => {
  //   //TODO add try catch
  //   let balanceAlice = await this.cake.balanceOf(alice)
  //   console.log(
  //     "🚀 starting balance - Alice",
  //     ethers.utils.formatEther(balanceAlice.toString())
  //   )

  //   await this.cake.approve(
  //     this.game.address,
  //     ethers.utils.parseEther("10"),
  //     { from: alice }
  //   )

  //   console.log("🚀 betting 10 Cakes ")

  //   let value = ethers.utils.parseUnits("1", 18)

  //   let numerator = await this.game.numerator(value)
  //   numerator = ethers.utils.formatEther(numerator.toString())

  //   let denominator = await this.game.denominator()
  //   denominator = ethers.utils.formatEther(denominator.toString())

  //   let getInvested = await this.game.getInvested()
  //   getInvested = ethers.utils.formatEther(getInvested.toString())

  //   console.log("===============================")
  //   console.log("🚀 get Contract Bankroll", getInvested)
  //   console.log(
  //     `${numerator} <= ${denominator} : ${numerator <= denominator}`
  //   )
  //   console.log("===============================")

  //   await this.game.bet(value, {
  //     from: alice
  //   })
  //   balanceAlice = await this.cake.balanceOf(alice)
  //   console.log(
  //     "🚀 balance - Alice",
  //     ethers.utils.formatEther(balanceAlice.toString())
  //   )

  //   const getLastBet = await this.game.getLastBet({ from: alice })
  //   console.log(`🚀 getLastBet :
  //   playerAddress : ${getLastBet["0"]}
  //   amountBetted : ${getLastBet["1"]}
  //   numberRolled : ${getLastBet["2"]}
  //   winAmount : ${ethers.utils.formatEther(getLastBet["3"].toString())}
  //   isClaimed : ${getLastBet["4"]}
  //   isWinned : ${getLastBet["5"]}`)

  //   console.log("advanceBlockTo - 1 minutes")
  //   //TODO create getter & setter for minTimeToWithdraw = 604800
  //   await time.increase(30)

  //   //TODO manage loose case
  //   await this.game.claimBonus({ from: alice })
  //   balanceAlice = await this.cake.balanceOf(alice)
  //   console.log(
  //     "🚀 ending balance - Alice",
  //     ethers.utils.formatEther(balanceAlice.toString())
  //   )

  //   getInvested = await this.game.getInvested()
  //   getInvested = ethers.utils.formatEther(getInvested.toString())
  //   console.log("🚀 get Contract Bankroll", getInvested)
  // })

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
})
