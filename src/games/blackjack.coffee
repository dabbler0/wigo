###
WGO Simplified Blackjack Game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###
{Game} = require '../game.coffee'
helper = require '../helper.coffee'

# # Simplified Blackjack
#
# The player hits or stays as in blackjack. If the sum goes over 21,  it's instant loss;
# otherwise, the dealer gets a random number between 10 and 21, and if player is bigger than it,
# they win.

exports.Blackjack = class Blackjack extends Game
  constructor: ->
    super 52, 2, 1
    @remainingCards = 52
    @reshuffle()

  # ## reshuffle
  # Clear the player stack
  reshuffle: ->
    @state.eachBit (i, j) =>
      @state.layers[i][j] = 0
    @reminaingCards = 0

  # ## getValue
  # Get the numeric value of a card
  getValue: (i) -> Math.ceil i / 4

  # ## used
  # See if a card has been used. Refactored
  # for later use if more layers are added for other player stacks
  # or for the dealer stack.
  used: (i) ->
    for layer in @state.layers
      if layer[i] is 1
        return true
    return false

  # ## deal
  # Get a random unused card.
  deal: ->
    target = helper._rand @remainingCards
    j = 0
    for i in [0...52] when not @used i
      j++
      if j is target
        return j
    return 52

  # ## dealTo
  # Get a random unused card and add it to the given
  # layer.
  dealTo: (layer) ->
    card = @deal()
    @state.layers[layer][card] = 1

  # ## sum
  # Get the numeric sum of card values for a given layer.
  sum: (layer) ->
    sum = 0
    for i in [0...52] when @state.layers[layer][i] is 1
      sum += @getValue i
    return sum

  # ## advance
  advance: (action) ->
    # 0 means 'hit'
    if action is 0
      # Deal a new card
      @dealTo 0

      # Lose if the player has bust
      if @sum(0) > 21
        @reshuffle()
        return {reward: -1, turn: 0, terminated: true}

      # Otherwise be okay
      return {reward: 0, turn: 0}

    # 1 means 'stay'
    else

      # The dealer will be assigned a random value between 10 and 21.
      # If the player beats this value, they win
      if @sum(0) > 10 + helper._rand(11)
        @reshuffle()
        return {reward: 1, turn: 0, terminated: true}

      # Otherwise, they lose.
      else
        @reshuffle()
        return {reward: -1, turn: 0, terminated: true}

  # ## rendering constants
  # The characters to combine to make the strings for
  # rendering cards in a tty.
  _cardNames = 'A 2 3 4 5 6 7 8 9 10 J Q K'.split ' '
  _suits = '\u2660 \u2665 \u2666 \u2663'.split ' '

  # ## renderCard
  # Utility function for rendering a card in the tty.
  renderCard: (i) -> _cardNames[Math.floor i / 4] + _suits[i % 4]

  # ## render
  # Simply list out all the cards that the player has in front
  # of them.
  render: ->
    str = ''
    for i in [0...52] when @state.layers[0][i] is 1
      str += @renderCard(i) + ' '
    str += '\n'
    return str
