###
WIGO Grid Game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###
{Game} = require '../game.coffee'
helper = require '../helper.coffee'

WALL_DENSITY = 0.2

# # GridGame
#
# A treasure-hunting game.
exports.GridGame = class GridGame extends Game
  constructor: (@w = 5, @h = 5) ->
    super @w * @h, 4, 3

    # Place random walls
    for i in [0...@w * @h] when i not in @_corners()
      console.log i, @_corners()
      if Math.random() < WALL_DENSITY
        @state.layers[1][i] = 1

    # Place player
    @state.layers[0][0] = 1

    # Place initial prize
    @state.layers[2][0] = 1

    # Record our position in the prize rotation cycle
    @prizeIndex = 0

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

    # Find new coordinate
    newCoord = {x: coord.x + dir.x, y: coord.y + dir.y}

    # If the new coordinate is a wall or out-of-bounds, return
    if not (0 <= newCoord.x < @w) or
       not (0 <= newCoord.y < @h) or
       @state.layers[1][@_index(newCoord)] is 1
      return {reward: -1, turn: 0}

    # If it is a prize, note so and move the prize
    prize = false
    if @state.layers[2][@_index(newCoord)] is 1
      prize = true

      # Move the prize to the next corner
      @state.layers[2][@_index(newCoord)] = 0
      @state.layers[2][@_corners()[(@prizeIndex += 1) %% 4]] = 1

    # Move the player
    @state.layers[0][@_index(coord)] = 0
    @state.layers[0][@_index(newCoord)] = 1

    # Return reward
    if prize
      return {reward: 10, turn: 0}
    else
      return {reward: 0, turn: 0}

  # ## render
  # Simple text grid layout, with `@` representing the player,
  # `#` representing a wall, and `?` representing a prize.
  render: ->
    str = ''
    for j in [0...@h]
      for i in [0...@w]
        if @state.layers[0][j * @w + i] is 1
          str += '@'
        else if @state.layers[1][j * @w + i] is 1
          str += '#'
        else if @state.layers[2][j * @w + i] is 1
          str += '?'
        else
          str += ' '
      str += '\n'
    return str

  # ## renderCanvas
  # Render to fill the entire canvas, with
  # different colors for each type of square.
  #
  # Player and prizes are drawn like "items",
  # smaller squares on the larger "terrain".
  renderCanvas: (ctx, canvas) ->
    # Get scaling factor to fit canvas
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
          ctx.fillStyle = '#DEB877'
        ctx.fillRect cx, cy, fx, fy

        # Draw the player, if it is here
        if @state.layers[0][i] is 1
          ctx.fillStyle = '#000'
          ctx.fillRect cx + fx / 3, cy + fy / 3, fx / 3, fy / 3

        # Draw the prize, if it is here
        if @state.layers[2][i] is 1
          ctx.fillStyle = '#FF0'
          ctx.fillRect cx + fx / 3, cy + fy / 3, fx / 3, fy / 3
