###
WIGO Dumb game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###
{Game} = require '../game.coffee'
helper = require '../helper.coffee'

PRIZE_SPAWN_PROBABILITY = 0.05
WALL_DENSITY = 1

# # GridGame
# A treasure-hunting game.
exports.PathGame = class PathGame extends Game
  constructor: (@w = 5, @h = 5) ->
    super @w * @h, 4, 3
    @buildMap()
    @reset()

  playerReplace: ->
    for i in [0...@w * @h]
      @state.layers[0][i] = 0
    @state.layers[0][0] = 1

  reset: ->
    @timeSinceReset = 0
    @buildMap()

    # Relace player
    @playerReplace()

  buildMap: ->
    # Clear the board
    @state.eachBit (i, j) =>
      @state.layers[i][j] = 0

    # Place random walls
    for i in [0...@w * @h] when i not in @_corners()
      if Math.random() < WALL_DENSITY
        @state.layers[1][i] = 1

    # Dig the guaranteed tunnel
    digger = {x: 0, y: 0}
    until digger.x is @w - 1 and digger.y is @h - 1
      dir = _dirs[helper._rand 2]
      digger.x += dir.x
      digger.y += dir.y
      if 0 <= digger.x < @w and 0 <= digger.y < @h
        @state.layers[1][@_index(digger)] = 0
      else
        digger.x -= dir.x
        digger.y -= dir.y

    @state.layers[1][@_index(digger)] = 0

    for i in [0...@w * @h] when @state.layers[1][i] is 0
      @state.layers[2][i] = 1

  _coord: (index) -> {x: index % @w, y: (index - (index % @w)) / @w}
  _index: (coord) -> coord.x + coord.y * @w
  _corners: -> [
      @_index {x: 0, y: 0}
      @_index {x: 0, y: @h - 1}
      @_index {x: @w - 1, y: 0}
      @_index {x: @w - 1, y: @h - 1}
    ]

  _dirs = {
    0: {x: 0, y: 1}
    1: {x: 1, y: 0}
    2: {x: 0, y: -1}
    3: {x: -1, y: 0}
  }

  advance: (action) ->
    @timeSinceReset++
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
       not (0 <= newCoord.y < @h)
      @playerReplace()
      return {reward: -1, turn: 0}

    # Move the player
    @state.layers[0][@_index(coord)] = 0
    @state.layers[0][@_index(newCoord)] = 1

    # If it is a prize, note so
    prize = false
    finish = false
    if @state.layers[2][@_index(newCoord)] is 1
      prize = true
      @state.layers[2][@_index(newCoord)] = 0
    if newCoord.x is @w - 1 and newCoord.y is @h - 1
      finish = true
      @reset()

    # Reset after a while randomly
    if @timeSinceReset > 300
      @reset()
      return {reward: -5, turn: 0}

    # Return reward
    if finish
      return {reward: 50, turn: 0}
    else if prize
      return {reward: 10, turn: 0}
    else if @state.layers[1][@_index(newCoord)] is 1
      @playerReplace()
      return {reward: -1, turn: 0}
    else
      return {reward: 0, turn: 0}

  render: ->
    str = ''
    for j in [0...@h]
      for i in [0...@w]
        if @state.layers[0][j * @w + i] is 1
          str += '@'
        else if @state.layers[1][j * @w + i] is 1
          str += '~'
        else
          str += ' '
      str += '\n'
    return str

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
        else if @state.layers[2][i] is 1
          ctx.fillStyle = '#FF0'
        else
          ctx.fillStyle = '#DEB877'
        ctx.fillRect cx, cy, fx, fy

        # Draw the player
        if @state.layers[0][i] is 1
          ctx.fillStyle = '#000'
          ctx.fillRect cx + fx / 3, cy + fy / 3, fx / 3, fy / 3
