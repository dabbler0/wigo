###
WIGO game definition schema
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###

# # State
# Generic representation of a game state.
exports.State = class State
  constructor: (@size, nLayers = 1) ->
    @layers = (new Uint8Array(@size) for [0...nLayers])

  # ## clone
  clone: ->
    clone = new State @size, @layers.length
    for layer, i in @layers
      for bit, j in layer
        clone.layers[i][j] = bit
    return clone

  # ## eachBit
  # Iterate over all the possible i, j coordinates
  # and call fn on each
  eachBit: (fn) ->
    for layer, i in @layers
      for bit, j in layer
        fn i, j

  # ## combinators
  # Get all possible sets of coordinates of size (degree)
  combinators: (degree) ->
    if degree > 1
      subcombinators = @combinators degree - 1
    else
      subcombinators = [[]]

    combinators = []

    @eachBit (i, j) =>
      for combinator in subcombinators
        combinators.push combinator.concat [[i, j]]

    return combinators

  # ## andCombinators
  # Return a set of functions that (and) all of the bits
  # at all possible sets of coordinates of size (degree)
  andCombinators: (degree) ->
    return @combinators(degree).map (combination) =>
      return (state) =>
        for coordinate in combination
          if state.layers[coordinate[0]][coordinate[1]] is 0
            return 0
        return 1

  # ## orCombinators
  # The "or" analogue to andCombinators
  orCombinators: (degree) ->
    return @combinators(degree).map (combination) =>
      return (state) =>
        for coordinate in combination
          if state.layers[coordinate[0]][coordinate[1]] is 1
            return 1
        return 0

# # Game
# A single game, including a persistent state.
exports.Game = class Game
  constructor: (@size, @actions, @nLayers = 1, @players = 1) ->
    @state = new State @size, @nLayers

  # ## advance
  # Should mutate @state and return object with reward and the turn.
  advance: (action) -> {reward: 0, turn: 0}

  # ## render
  # Return a logging string graphically representing the string.
  render: -> ''
