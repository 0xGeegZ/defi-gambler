const { expectRevert, time, balance } = require("@openzeppelin/test-helpers")
// const { BigNumber } = require("@ethersproject/bignumber")
const { BigNumber } = require("ethers")

const { assert } = require("chai")
const CakeToken = artifacts.require("CakeToken")
const SyrupBar = artifacts.require("SyrupBar")
const MasterChef = artifacts.require("MasterChef")
// const SousChef = artifacts.require("SousChef")
const GameCAKE = artifacts.require("GameCAKE")

const MAX_INVESTORS = 10
const ACCEPTED_MARGIN = 3
const PERCENT_WIN_DECIMALS = 90 / 100
const PERCENT_LOOSE_DECIMALS = 10 / 100
const MIN_TIME_TO_WITHDRAW = 60 * 60 * 60 * 24

contract("Game", ([dev, minter, ...players]) => {
  beforeEach(async () => {
    this.cake = await CakeToken.new({ from: minter })
    this.syrup = await SyrupBar.new(this.cake.address, { from: minter })

    // this.SousChef = await SousChef.new(this.syrup.address, "40", "100", "500", {
    //   from: minter
    // })

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

  it("[OK] should win a game", async () => {
    let isWinningBet = false
    let counter = 0
    let value = ethers.utils.parseEther("1")
    let player
    while (!isWinningBet) {
      player = players[counter]
      counter++
      await this.cake.approve(this.game.address, value, {
        from: player
      })

      await this.game.bet(value, {
        from: player
      })

      const getLastBet = await this.game.getLastBet({ from: player })
      isWinningBet = getLastBet["5"]
    }
    assert(isWinningBet)
  })

  it("[OK] should loose a game", async () => {
    const MAX_ITERATIONS = 50

    let minterParams = { from: minter }
    let value = ethers.utils.parseEther("1")
    let player, i, counter, wins, looses
    looses = wins = counter = 0

    for (i = 0; i < players.length; i++) {
      if (counter == MAX_ITERATIONS) {
        await this.game.pause(minterParams)
        await this.game.forceDivestOfAllInvestors(minterParams)
        await this.game.unpause(minterParams)
        break
      }

      if (i == MAX_INVESTORS) {
        //pause and divest all players
        await this.game.pause({
          from: minter
        })
        await this.game.forceDivestOfAllInvestors({
          from: minter
        })
        await this.game.unpause({
          from: minter
        })
        getInvestors = await this.game.getInvestors()
        i = 0
      }

      player = players[i]
      let playerParams = { from: player }

      await this.cake.approve(this.game.address, value, playerParams)

      await this.game.bet(value, playerParams)

      const getLastBet = await this.game.getLastBet(playerParams)

      if (!getLastBet["5"]) return assert(!getLastBet["5"])

      counter++
    }

    assert(
      false,
      `no players loosing during ${MAX_ITERATIONS} iteration with ${PERCENT_LOOSE_DECIMALS *
        100}% chances to loose`
    )
  })

  it("[OK] should claim bonus if win a game", async () => {
    const MAX_ITERATIONS = 50

    let minterParams = { from: minter }
    let value = ethers.utils.parseEther("1")
    let player, i, counter, wins, looses, playerParams
    looses = wins = counter = 0

    for (i = 0; i < players.length; i++) {
      if (counter == MAX_ITERATIONS) {
        await this.game.pause(minterParams)
        await this.game.forceDivestOfAllInvestors(minterParams)
        await this.game.unpause(minterParams)
        break
      }

      if (i == MAX_INVESTORS) {
        //       pause and divest all players
        await this.game.pause({
          from: minter
        })
        await this.game.forceDivestOfAllInvestors({
          from: minter
        })
        await this.game.unpause({
          from: minter
        })
        getInvestors = await this.game.getInvestors()
        i = 0
      }

      player = players[i]
      playerParams = { from: player }

      await this.cake.approve(this.game.address, value, playerParams)

      await this.game.bet(value, playerParams)

      const getLastBet = await this.game.getLastBet(playerParams)

      if (getLastBet["5"]) break

      counter++
    }
    await this.game.claimBonus(playerParams)
  })

  it("[OK] should not claim bonus if loose a game", async () => {
    const MAX_ITERATIONS = 50

    let minterParams = { from: minter }
    let value = ethers.utils.parseEther("1")
    let player, i, counter, wins, looses, playerParams
    looses = wins = counter = 0

    for (i = 0; i < players.length; i++) {
      if (counter == MAX_ITERATIONS) {
        await this.game.pause(minterParams)
        await this.game.forceDivestOfAllInvestors(minterParams)
        await this.game.unpause(minterParams)
        break
      }

      if (i == MAX_INVESTORS) {
        //pause and divest all players
        await this.game.pause({
          from: minter
        })
        await this.game.forceDivestOfAllInvestors({
          from: minter
        })
        await this.game.unpause({
          from: minter
        })
        getInvestors = await this.game.getInvestors()
        i = 0
      }

      player = players[i]
      playerParams = { from: player }

      await this.cake.approve(this.game.address, value, playerParams)

      await this.game.bet(value, playerParams)

      const getLastBet = await this.game.getLastBet(playerParams)

      if (!getLastBet["5"]) break

      counter++
    }
    try {
      await this.game.claimBonus(playerParams)
    } catch (error) {
      assert(error)
    }
  })

  it("[OK] should not claim bonus for player not in game", async () => {
    const MAX_ITERATIONS = 50

    let minterParams = { from: minter }
    let value = ethers.utils.parseEther("1")
    let player, i, counter, wins, looses, playerParams
    looses = wins = counter = 0

    for (i = 0; i < players.length; i++) {
      if (counter == MAX_ITERATIONS) {
        await this.game.pause(minterParams)
        await this.game.forceDivestOfAllInvestors(minterParams)
        await this.game.unpause(minterParams)
        break
      }

      if (i == MAX_INVESTORS) {
        //pause and divest all players
        await this.game.pause({
          from: minter
        })
        await this.game.forceDivestOfAllInvestors({
          from: minter
        })
        await this.game.unpause({
          from: minter
        })
        getInvestors = await this.game.getInvestors()
        i = 0
      }

      player = players[i]
      playerParams = { from: player }

      await this.cake.approve(this.game.address, value, playerParams)

      await this.game.bet(value, playerParams)

      const getLastBet = await this.game.getLastBet(playerParams)

      if (getLastBet["5"]) break
    }

    try {
      await this.game.claimBonus({ from: dev })
    } catch (error) {
      assert(error)
    }
  })

  it(`[OK] should bet and claim after waiting for timelock ${MIN_TIME_TO_WITHDRAW}ms`, async () => {
    const value = ethers.utils.parseEther("1")
    const player = players[0]
    const playerParams = { from: player }

    await this.cake.approve(this.game.address, value, playerParams)
    await this.game.bet(value, playerParams)

    // console.log(`advance block to ${MIN_TIME_TO_WITHDRAW}ms`)
    await time.increase(MIN_TIME_TO_WITHDRAW)

    await this.game.claimBet(playerParams)
  })

  it(`[OK] should throw error on bet and claim without waiting for timelock ${MIN_TIME_TO_WITHDRAW}ms`, async () => {
    try {
      const value = ethers.utils.parseEther("1")
      const player = players[0]
      const playerParams = { from: player }

      await this.cake.approve(this.game.address, value, playerParams)
      await this.game.bet(value, playerParams)

      await this.game.claimBet(playerParams)
    } catch (error) {
      assert(error)
    }
  })

  it(`[OK] should enter multiples players until maxplayers(${MAX_INVESTORS}) error thrown`, async () => {
    let value = ethers.utils.parseEther("1")
    let player, i, playerParams

    try {
      for (i = 0; i < players.length; i++) {
        player = players[i]
        playerParams = { from: player }

        await this.cake.approve(this.game.address, value, playerParams)
        await this.game.bet(value, playerParams)
      }
    } catch (error) {
      if (i == MAX_INVESTORS) {
        return assert(error)
      }
    }
    assert(false)
  })

  it("[OK] should enter multiples times in game and keep coherent Win/Loose ratio", async () => {
    const MAX_ITERATIONS = 200
    let minterParams = { from: minter }
    let value = ethers.utils.parseEther("1")
    let player, i, counter, wins, looses
    looses = wins = counter = 0

    for (i = 0; i < players.length; i++) {
      if (counter == MAX_ITERATIONS) {
        await this.game.pause(minterParams)
        await this.game.forceDivestOfAllInvestors(minterParams)
        await this.game.unpause(minterParams)
        break
      }

      if (i == MAX_INVESTORS) {
        //pause and divest all players
        await this.game.pause(minterParams)
        await this.game.forceDivestOfAllInvestors(minterParams)
        await this.game.unpause(minterParams)
        getInvestors = await this.game.getInvestors()
        i = 0
      }

      player = players[i]
      let playerParams = { from: player }

      await this.cake.approve(this.game.address, value, playerParams)

      await this.game.bet(value, playerParams)

      const getLastBet = await this.game.getLastBet(playerParams)

      if (getLastBet["5"]) wins++
      else looses++

      counter++
    }

    // console.log(`**********************************`)
    // console.log(
    //   `🚀 END : iterations : ${counter} - win ratio ${wins} - loose ratio ${looses}`
    // )
    // console.log(`**********************************`)

    assert.equal(
      counter,
      MAX_ITERATIONS,
      `Counter should be equal to ${MAX_ITERATIONS} - Have ${counter}`
    )

    var percentWin = PERCENT_WIN_DECIMALS * counter

    const winsCondition =
      wins >= percentWin - ACCEPTED_MARGIN &&
      wins <= percentWin + ACCEPTED_MARGIN
    assert(winsCondition, `Win ratio seem's not good : ${wins}`)

    var percentLoose = PERCENT_LOOSE_DECIMALS * counter
    const loosesCondition =
      looses >= percentLoose - ACCEPTED_MARGIN &&
      looses <= percentLoose + ACCEPTED_MARGIN
    assert(loosesCondition, `Loose ratio seem's not good : ${looses}`)
  })

  it(`[OK] admin should divest all players`, async () => {
    assert(
      players.length > MAX_INVESTORS,
      "need more players to launch this test"
    )

    let minterParams = { from: minter }
    let value = ethers.utils.parseEther("1")
    let player, i
    for (i = 0; i < players.length; i++) {
      if (i == MAX_INVESTORS) {
        await this.game.pause(minterParams)
        await this.game.forceDivestOfAllInvestors(minterParams)
        await this.game.unpause(minterParams)
        break
      }

      player = players[i]
      let playerParams = { from: player }

      await this.cake.approve(this.game.address, value, playerParams)
      await this.game.bet(value, playerParams)
    }
  })

  it(`[OK] player should not divest all players`, async () => {
    assert(
      players.length > MAX_INVESTORS,
      "need more players to launch this test"
    )

    let minterParams = { from: minter }
    let value = ethers.utils.parseEther("1")
    let player, i
    try {
      for (i = 0; i < players.length; i++) {
        if (i == MAX_INVESTORS) {
          await this.game.pause(minterParams)
          await this.game.forceDivestOfAllInvestors({ from: player })
          await this.game.unpause(minterParams)
          break
        }

        player = players[i]
        let playerParams = { from: player }

        await this.cake.approve(this.game.address, value, playerParams)
        await this.game.bet(value, playerParams)
      }
    } catch (error) {
      assert(error)
    }
  })

  ///
  /// EMERGENCY
  ///
  it(`[OK] admin should unstakeAll`, async () => {
    assert(
      players.length > MAX_INVESTORS,
      "need more players to launch this test"
    )
    let minterParams = { from: minter }
    let value = ethers.utils.parseEther("1")
    let player, i
    for (i = 0; i < players.length; i++) {
      if (i == MAX_INVESTORS) {
        await this.game.unstakeAll(minterParams)
        break
      }

      player = players[i]
      let playerParams = { from: player }

      await this.cake.approve(this.game.address, value, playerParams)
      await this.game.bet(value, playerParams)
    }
  })

  it(`[OK] not admin should not unstakeAll`, async () => {
    assert(
      players.length > MAX_INVESTORS,
      "need more players to launch this test"
    )
    let value = ethers.utils.parseEther("1")
    let player, i

    try {
      for (i = 0; i < players.length; i++) {
        if (i == MAX_INVESTORS) {
          await this.game.unstakeAll({ from: dev })
          break
        }

        player = players[i]
        let playerParams = { from: player }

        await this.cake.approve(this.game.address, value, playerParams)
        await this.game.bet(value, playerParams)
      }
    } catch (error) {
      assert(error)
    }
  })

  it(`[OK] admin should emergencyWithdrawal`, async () => {
    assert(
      players.length > MAX_INVESTORS,
      "need more players to launch this test"
    )
    let minterParams = { from: minter }
    let value = ethers.utils.parseEther("1")
    let player, i
    for (i = 0; i < players.length; i++) {
      if (i == MAX_INVESTORS) {
        await this.game.pause(minterParams)
        await this.game.emergencyWithdrawal(minterParams)
        await this.game.unpause(minterParams)
        break
      }

      player = players[i]
      let playerParams = { from: player }

      await this.cake.approve(this.game.address, value, playerParams)
      await this.game.bet(value, playerParams)
    }
  })

  it(`[OK] not admin should not emergencyWithdrawal`, async () => {
    assert(
      players.length > MAX_INVESTORS,
      "need more players to launch this test"
    )
    let minterParams = { from: minter }
    let value = ethers.utils.parseEther("1")
    let player, i

    try {
      for (i = 0; i < players.length; i++) {
        if (i == MAX_INVESTORS) {
          await this.game.pause(minterParams)
          await this.game.emergencyWithdrawal({ from: dev })
          await this.game.unpause(minterParams)
          break
        }

        player = players[i]
        let playerParams = { from: player }

        await this.cake.approve(this.game.address, value, playerParams)
        await this.game.bet(value, playerParams)
      }
    } catch (error) {
      assert(error)
    }
  })

  it(`[OK] admin should remburseStartedBankroll`, async () => {
    assert(
      players.length > MAX_INVESTORS,
      "need more players to launch this test"
    )
    let minterParams = { from: minter }
    let value = ethers.utils.parseEther("1")
    let player, i
    for (i = 0; i < players.length; i++) {
      if (i == MAX_INVESTORS) {
        await this.game.remburseStartedBankroll(minterParams)
        break
      }

      player = players[i]
      let playerParams = { from: player }

      await this.cake.approve(this.game.address, value, playerParams)
      await this.game.bet(value, playerParams)
    }
  })

  it(`[OK] not admin should not remburseStartedBankroll`, async () => {
    assert(
      players.length > MAX_INVESTORS,
      "need more players to launch this test"
    )
    let value = ethers.utils.parseEther("1")
    let player, i

    try {
      for (i = 0; i < players.length; i++) {
        if (i == MAX_INVESTORS) {
          await this.game.remburseStartedBankroll({ from: dev })
          break
        }

        player = players[i]
        let playerParams = { from: player }

        await this.cake.approve(this.game.address, value, playerParams)
        await this.game.bet(value, playerParams)
      }
    } catch (error) {
      assert(error)
    }
  })
})
