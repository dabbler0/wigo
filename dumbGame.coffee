###
WIGO Dumb game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###
{Game} = require './game'

# # DumbGame
# An example game. It is dumb.
#
# You are given either [1, 0] (in which case you must output 0)
# or [0, 1] (in which case you must output 1). If you are correct,
# you get a point, otherwise you lose a point.
exports.DumbGame = class DumbGame extends Game
  constructor: ->
    super 2, 2
    @state.layers[0][0] = 1
    @state.layers[0][1] = 0

  advance: (action) ->
    if (@state.layers[0][0] > @state.layers[0][1]) is (action is 0)
      reward = 1
    else
      reward = -1
    @state.layers[0][0] = _randomBit()
    @state.layers[0][1] = 1 - @state.layers[0][0]
    return reward

  render: -> "#{@state.layers[0][0]},#{@state.layers[0][1]}"
