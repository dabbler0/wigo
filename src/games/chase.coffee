###
WIGO Chase Game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###
{Game} = require '../game.coffee'
helper = require '../helper.coffee'

PRIZE_SPAWN_PROBABILITY = 0.05
WALL_DENSITY = 0.2

# # ChaseGame
# A treasure-hunting game.
exports.ChaseGame = class ChaseGame extends Game
  constructor: (@w = 5, @h = 5) ->
    super @w * @h, 4, 3

    # Place random walls
    for i in [0...@w * @h] when i not in @_corners()
      if Math.random() < WALL_DENSITY
        @state.layers[1][i] = 1

    # Place player
    @state.layers[0][0] = 1
    @state.layers[2][@w * @h - 1] = 1

  # ### Coordinate/index conversion
  # Convert between the indices in the state layers
  # and (x, y) coordinates
  _coord: (index) -> {x: index % @w, y: (index - (index % @w)) / @w}
  _index: (coord) -> coord.x + coord.y * @w

  # ### corners
  # Utility function to get the state indices
  # of the corners of the board
  _corners: -> [
      @_index {x: 0, y: 0}
      @_index {x: 0, y: @h - 1}
      @_index {x: @w - 1, y: 0}
      @_index {x: @w - 1, y: @h - 1}
    ]

  # ### dirs
  # The four cardinal directions
  _dirs = {
    0: {x: 0, y: 1}
    1: {x: 1, y: 0}
    2: {x: 0, y: -1}
    3: {x: -1, y: 0}
  }

  # ## advance
  advance: (action) ->
    # Get the wanted direction of motion
    dir = _dirs[action]

    # Get the current player coordinate
    coord = null
    for i in [0...@w * @h]
      if @state.layers[0][i] is 1
        coord = @_coord i
        break

    # Get the current prize coordinate
    prizeCoord = null
    for i in [0...@w * @h]
      if @state.layers[2][i] is 1
        prizeCoord = @_coord i
        break

    # Find new coordinate
    newCoord = {x: coord.x + dir.x, y: coord.y + dir.y}

    # If the new coordinate is a wall or out-of-bounds, return
    if not (0 <= newCoord.x < @w) or
       not (0 <= newCoord.y < @h) or
       @state.layers[1][@_index(newCoord)] is 1
      return {reward: -1, turn: 0}

    # If it the prize, note so
    prize = (@state.layers[2][@_index(newCoord)] is 1)

    # Move the prize
    oldIndex = @_index prizeCoord
    if prize
      prizeCoord.x = @w - 1
      prizeCoord.y = @h - 1
    else
      dir = _dirs[helper._rand 4]
      prizeCoord.x += dir.x
      prizeCoord.y += dir.y
    if 0 <= prizeCoord.x < @w and 0 <= prizeCoord.y < @h and @state.layers[1][@_index prizeCoord] is 0
      @state.layers[2][oldIndex] = 0
      @state.layers[2][@_index(prizeCoord)] = 1

    # Move the player
    @state.layers[0][@_index(coord)] = 0
    @state.layers[0][@_index(newCoord)] = 1

    # Return reward
    if prize
      return {reward: 10, turn: 0}
    else
      return {reward: 0, turn: 0}

  # ## render
  # Same as grid render, but with 'X' for prize.
  render: ->
    str = ''
    for j in [0...@h]
      for i in [0...@w]
        if @state.layers[0][j * @w + i] is 1
          str += '@'
        else if @state.layers[1][j * @w + i] is 1
          str += '#'
        else if @state.layers[2][j * @w + i] is 1
          str += 'X'
        else
          str += ' '
      str += '\n'
    return str

  # ## renderCanvas
  # Same as grid render.
  renderCanvas: (ctx, canvas) ->
    # Get scaling factor
    fx = canvas.width / @w
    fy = canvas.height / @h
    for y in [0...@h]
      for x in [0...@w]
        cx = x * fx
        cy = y * fy

        i = y * @w + x

        # Draw underlying terrain
        if @state.layers[1][i] is 1
          ctx.fillStyle = '#F00'
        else
          ctx.fillStyle = '#FFF'
        ctx.fillRect cx, cy, fx, fy

        # Draw the player
        if @state.layers[0][i] is 1
          ctx.fillStyle = '#000'
          ctx.fillRect cx + fx / 3, cy + fy / 3, fx / 3, fy / 3

        # Draw the prize
        if @state.layers[2][i] is 1
          ctx.fillStyle = '#FF0'
          ctx.fillRect cx + fx / 3, cy + fy / 3, fx / 3, fy / 3
