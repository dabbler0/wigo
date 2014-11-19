###
WIGO Dumb Game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###
{Game} = require '../game.coffee'
helper = require '../helper.coffee'

# # DumbGame
# An example game. It is dumb. This is just to test to make sure linear regression works at all.
#
# You are given either [1, 0] (in which case you must output 0)
# or [0, 1] (in which case you must output 1). If you are correct,
# you get a point, otherwise you lose a point.
exports.DumbGame = class DumbGame extends Game
  constructor: ->
    super 2, 2, 1

  # ## advance
  advance: (action) ->
    # See if the agent was correct
    if (@state.layers[0][0] > @state.layers[0][1]) is (action is 0)
      reward = 1
    else
      reward = -1

    # Pick new random numbers
    @state.layers[0][0] = helper._randBit()
    @state.layers[0][1] = 1 - @state.layers[0][0]

    return {reward: reward, turn: 0}

  # ## render
  render: -> "#{@state.layers[0][0]},#{@state.layers[0][1]}"
