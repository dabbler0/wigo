###
WIGO Dumb game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###
{Game} = require '../game.coffee'
helper = require '../helper.coffee'

# # TicTacToe
# An example game of tic-tac-toe.
exports.TicTacToeGame = class TicTacToeGame extends Game
  constructor: ->
    super 2, 2

  clearBoard: ->
    @state.eachBit (i, j) =>
      @state.layers[i][j] = 0

  advance: (action) ->
    # Punish illegal moves severely.
    if @state.layers[@turn][action] is 1
      @clearBoard()
      return {reward: -100, turn: 0}

    # Otherwise
    @state.layers[@turn][action] = 1
    if @checkRows @state.layers[@turn], action
      return {reward: 1, turn: 0}

  render: -> "#{@state.layers[0][0]},#{@state.layers[0][1]}"
