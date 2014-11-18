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
    super 52, 2, 2
    @remainingCards = 52
    @reshuffle()

  reshuffle: ->
    @state.eachBit (i, j) =>
      @state.layers[i][j] = 0
    @reminaingCards = 0

    # Deal face-up dealer card
    @dealTo 1

  getValue: (i) -> Math.ceil i / 4

  used: (i) ->
    for layer in @state.layers
      if layer[i] is 1
        return true
    return false

  deal: ->
    target = helper._rand @remainingCards
    j = 0
    for i in [0...52] when not @used i
      j++
      if j is target
        return j
    return 52

  dealTo: (layer) ->
    card = @deal()
    @state.layers[layer][card] = 1

  sum: (layer) ->
    sum = 0
    for i in [0...52] when @state.layers[layer][i] is 1
      sum += @getValue i
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

    else
      ###
      until (sum = @sum(1)) > 15
        @dealTo 1

      if sum > 21
        @reshuffle()
        return {reward: 11, turn: 0}
      else if @sum(0) > sum
        @reshuffle()
        return {reward: 11, turn: 0}
      else
        @reshuffle()
        return {reward: -10, turn: 0}
      ###
      if @sum(0) > 15
        @reshuffle()
        return {reward: 1, turn: 0}
      else
        @reshuffle()
        return {reward: -1, turn: 0}

  _cardNames = 'A 2 3 4 5 6 7 8 9 10 J Q K'.split ' '
  _suits = '\u2660 \u2665 \u2666 \u2663'.split ' '

  renderCard: (i) -> _cardNames[Math.floor i / 4] + _suits[i % 4]

  render: ->
    str = ''
    for layer in [1..0]
      for i in [0...52] when @state.layers[layer][i] is 1
        str += @renderCard(i) + ' '
      str += '\n'
    return str
