###
WIGO Dumb game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###
{Game} = require '../game.coffee'
helper = require '../helper.coffee'

PRIZE_SPAWN_PROBABILITY = 0.05
WALL_DENSITY = 0.2

# # ChaseGame
# A treasure-hunting game.
exports.FleeGame = class FleeGame extends Game
  constructor: (@w = 5, @h = 5) ->
    super @w * @h, 4, 2

    # Place random walls
    #for i in @_corners() when i isnt 0
    @state.layers[1][@w - 1] = 1

    # Place player
    @state.layers[0][0] = 1

  _coord: (index) -> {x: index % @w, y: (index - (index % @w)) / @w}
  _index: (coord) -> coord.x + coord.y * @w
  _corners: -> [
      @_index {x: 0, y: 0}
      @_index {x: 0, y: @h - 1}
      @_index {x: @w - 1, y: 0}
      @_index {x: @w - 1, y: @h - 1}
    ]

  _dirs = [
    {x: 0, y: 1},
    {x: 1, y: 0},
    {x: 0, y: -1},
    {x: -1, y: 0}
  ]

  getRandPosition: (pos) ->
    possibilities = []
    for dir in _dirs
      newPos = {x: pos.x + dir.x, y: pos.y + dir.y}
      if 0 <= newPos.x < @w and
         0 <= newPos.y < @h and
         @state.layers[1][@_index newPos] is 0
        possibilities.push newPos
    if possibilities.length is 0
      return pos
    else
      return helper._rand possibilities

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
    prizeCoords = []
    for i in [0...@w * @h]
      if @state.layers[1][i] is 1
        prizeCoords.push @_coord i

    # Find new coordinate
    newCoord = {x: coord.x + dir.x, y: coord.y + dir.y}

    # Move the prize
    for prizeCoord in prizeCoords
      @state.layers[1][@_index(prizeCoord)] = 0
      @state.layers[1][@_index(@getRandPosition(prizeCoord))] = 1

    # If the new coordinate is a wall or out-of-bounds, return
    if not (0 <= newCoord.x < @w) or
       not (0 <= newCoord.y < @h)
      return {reward: -1, turn: 0}

    # Move the player
    @state.layers[0][@_index(coord)] = 0
    @state.layers[0][@_index(newCoord)] = 1

    if @state.layers[1][@_index(newCoord)] is 1
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
          str += 'X'
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
        ctx.fillStyle = '#FFF'
        ctx.fillRect cx, cy, fx, fy

        # Draw the player
        if @state.layers[0][i] is 1
          ctx.fillStyle = '#000'
          ctx.fillRect cx + fx / 3, cy + fy / 3, fx / 3, fy / 3

        # Draw the enemy
        if @state.layers[1][i] is 1
          ctx.fillStyle = '#F00'
          ctx.fillRect cx + fx / 3, cy + fy / 3, fx / 3, fy / 3
