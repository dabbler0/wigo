###
WIGO 2048 Game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###
{Game} = require '../game.coffee'

SPAWN_FOUR_PROBABILITY = 0.1

exports.NotGame = class NotGame extends Game
  
  dirs = {
    0: [0, -1] # Left
    1: [1, 0] # Down
    2: [0, 1] # Right
    3: [-1, 0] # Up
  }

  constructor: ->
    super 16, 4, 12
    for i in [0...16]
      @state.layers[0][i] = true
    # Add two random initial tiles
    @addRandom()
    @addRandom()

  # Convert coordinates to index in state
  convert: (i, j) ->
    return i * 4 + j

  # Add a random tile
  addRandom: ->
    free = []
    for i in [0...4]
      for j in [0...4]
        if @value(@convert(i, j)) is 0
          free.push @convert(i, j)
    if free.length > 0
      n = free[Math.floor(Math.random() * free.length)]
      @state.layers[if Math.random() > (1 - SPAWN_FOUR_PROBABILITY) then 2 else 1][n] = 1
      @state.layers[0][n] = 0

  # Returns the log base 2 value of a tile at pos
  value: (pos) ->
    for l in [0...12]
      if @state.layers[l][pos]
        return l
    return 0

  # Determine whether a coordinate is valid
  valid: (x, y) ->
    return x >= 0 and x < 4 and y >= 0 and y < 4

  getNext: (x, y, dir) ->
    prev = [x, y]
    cur = [x + dirs[dir][0], y + dirs[dir][1]]
    while @valid(cur[0], cur[1]) and @value(@convert(cur[0], cur[1])) is 0
      prev[0] = cur[0]
      prev[1] = cur[1]
      cur = [cur[0] + dirs[dir][0], cur[1] + dirs[dir][1]]
    return {
      farthest: prev
      next: @convert(cur[0], cur[1])
    }
  
  lost: ->
    for i in [0...16]
      if @value(i) is 0
        return false
    for i in [0...4]
      for j in [0...4]
        val = @value(@convert(i, j))
        if val isnt 0
          for d in [0...4]
            other = [i + dirs[d][0], j + dirs[d][1]]
            if @valid(other[0], other[1])
              if @value(@convert(other[0], other[1])) is val
                return false
    return true

  advance: (action) ->
    console.log 'action is ' + action
    merged = (false for [0...16])
    x = []
    y = []
    for i in [0...4]
      x.push i
      y.push i
    if dirs[action][0] is 1
      x = x.reverse()
    if dirs[action][1] is 1
      y = y.reverse()
    reward = 0
    moved = false
    terminated = false
    for i in [0...4]
      for j in [0...4]
        val = @value(@convert(x[i], y[j]))
        if val isnt 0
          ret = @getNext(x[i], y[j], action)
          next = ret.next
          if @value(next) is val and not merged[next]
            @state.layers[val + 1][next] = 1
            @state.layers[val][@convert(x[i], y[j])] = 0
            @state.layers[val][next] = 0
            reward += 2 ** (val + 1)
            moved = true
            if val is 10
              terminated = true
              break
            merged[@convert(x[i], y[j])] = true
          else if x[i] isnt ret.farthest[0] or y[j] isnt ret.farthest[1]
            @state.layers[val][@convert(x[i], y[j])] = 0
            @state.layers[val][@convert(ret.farthest[0], ret.farthest[1])] = 1
            moved = true
    if moved
      @addRandom()
    else
      reward = -32
    if @lost()
      terminated = true
      reward = -2048
    if terminated
      for l in [1...12]
        for p in [0...16]
          @state.layers[l][p] = 0
      for i in [0...16]
        @state.layers[0][i] = true
      @addRandom()
      @addRandom()
    return {
      reward: reward
      turn: 0
      terminated: terminated
    }

  render: ->
    str = ''
    for i in [0...4]
      for j in [0...4]
        str += @value(@convert(i, j)) + (if j isnt 3 then '\t' else '')
      str += '\n'
    return str
