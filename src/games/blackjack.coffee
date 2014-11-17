###
WIGO Dumb game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###
{Game} = require '../game.coffee'
helper = require '../helper.coffee'

# # DumbGame
# An example game. It is dumb.
#
# You are given either [1, 0] (in which case you must output 0)
# or [0, 1] (in which case you must output 1). If you are correct,
# you get a point, otherwise you lose a point.
exports.Blackjack = class Blackjack extends Game
  constructor: ->
    super 52, 2, 1
    @remainingCards = 52

  reset: ->
    @state.eachBit (i, j) =>
      @state.layers[i][j] = 0
    @remainingCards = 52

  getSum: ->
    sum = 0
    for val, j in @state.layers[0] when val is 1
      sum += Math.ceil j / 4
    return sum

  advance: (action) ->
    if action is 0
      reward = @getSum()
      @reset()
      if reward > 10 #helper._rand 21
        return {reward: 1, turn: 0, terminated: true}
      else
        return {reward: -1, turn: 0, terminated: true}

    else
      target = helper._rand @remainingCards
      i = 0
      for val, j in @state.layers[0] when val is 0
        if i is target
          @state.layers[0][j] = 1
          break
        else
          i++
      if @getSum() > 21
        @reset()
        return {reward: -1, turn: 0, terminated: true}
      else
        return {reward: 0, turn: 0, terminated: false}

  render: ->
    str = ''
    for val,  j in @state.layers[0] when val is 1
      str += Math.ceil(j / 4) + ','

    return str
