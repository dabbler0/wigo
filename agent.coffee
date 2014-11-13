fs = require 'fs'
brain = require 'brain'
qLearning = require './qLearning'

###
EXAMPLE GAME: 2048
###

ROWS_2048 = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
ROWS_2048_REVERSE = (k.slice(0).reverse() for k in ROWS_2048)
COLUMNS_2048 = [[0, 4, 8, 12], [1, 5, 9, 13], [2, 6, 10, 14], [3, 7, 11, 15]]
COLUMNS_2048_REVERSE = (k.slice(0).reverse() for k in COLUMNS_2048)

QUEUES_2048 = [ROWS_2048, ROWS_2048_REVERSE, COLUMNS_2048, COLUMNS_2048_REVERSE]

# Float64Array utility functions
_copy = (arr) -> new Float64Array arr.buffer.slice 0
_eq = (a, b) ->
  eq = true
  eq and= b[i] is k for k, i in a
  return eq

# Random number utility function
# If a, b ints, returns int between a and b
# If a int, b undefined, returns int between 0 and a
# if a array, b undefined, returns random element of a
_rand = (a, b) ->
  if b?
    return Math.floor a + Math.random() * (b - a)
  else if a instanceof Array
    return a[Math.floor Math.random() * a.length]
  else
    return Math.floor Math.random() * a

# Log base 2 utility function
_log2 = (x) ->
  if x is 0
    return 0
  return Math.log(x) / Math.log(2)

class Game
  constructor: ({inputs: @inputs, outputs: @outputs, advance: @_advance, render: @render, init: @init}) ->

  advance: (state, action) ->
    state = _copy state
    return @_advance state, action

  playRandom: (render = false) ->
    state = new Float64Array @inputs
    legal = [0...@outputs]

    @init state

    history = [state]

    if render
      step = =>
        move = _rand legal
        results = @advance state, move

        state = results.state
        legal = results.actions

        history.push state

        console.log @render state

        if results.over
          console.log results.score
        else
          setTimeout step, 60
      step()
    else
      while true
        move = _rand legal
        results = @advance state, move

        state = results.state
        legal = results.actions

        history.push state

        if results.over
          return {
            history: history
            score: results.score
          }

_addRandom = (state) ->
  freeSquares = 0
  freeSquares++ for square in state when square is 0
  if freeSquares > 0
    j = _rand freeSquares
    for square, i in state when square is 0
      if j is 0
        state[i] = if Math.random() < 0.9 then 2 else 4
        break
      else
        j--

game2048 = new Game {
  inputs: 16
  outputs: 4
  init: (state) ->
    _addRandom state for [1..2]

  advance: (state, action) ->
    old = _copy state
    merged = false

    # Perform the swipe action
    queues = QUEUES_2048[action]
    for queue in queues
      for el, i in queue by -1 when state[el] isnt 0
        val = state[el]
        state[el] = 0

        j = i + 1
        j++ until state[queue[j]] isnt 0

        if j < 4 and state[queue[j]] is val
          merged = true
          state[queue[j]] *= 2
        else
          state[queue[j - 1]] = val

    # Add two tiles at random locations
    unless _eq old, state
      _addRandom state for [1..2]

    # Test game end
    lost = true
    won = false
    for square in state
      if square is 2048
        won = true
        break
      else if square is 0
        lost = false
        break

    # If the board is full (ergo we might have lost), check to
    # see if we really have lost
    if lost
      for row in ROWS_2048
        for el, i in row
          if row[i - 1]? and state[row[i - 1]] is state[el]
            lost = false
            break
      for col in COLUMNS_2048
        for el, i in col
          if col[i - 1]? and state[col[i - 1]] is state[el]
            lost = false
            break

    # If the game is over, compute score
    if won or lost
      return {
        over: true
        reward: -100
        state: state
        actions: []
      }

    # Otherwise, return the new state
    score = 0
    for square in state
      score += _log2(square) ** 2
    return {
      over: false
      reward: if merged then 1 else -1
      state: state
      actions: [0, 1, 2, 3]
    }

  render: (state) ->
    str = ''
    for el, i in state
      str += el
      if i %% 4 is 3
        str += '\n'
      else
        str += '\t'
    return str
}

_getCoord = (n) -> {
  x: n % 5
  y: (n - (n % 5)) / 5
}

_toIndex = (coord) -> coord.x + coord.y * 5

gameGrid = new Game {
  inputs: 25
  outputs: 4

  init: (state) ->
    for val, i in state
      if Math.random() < 7 / 25
        state[i] = -1
      #if Math.random() < 7 / 25
      #  state[i] = 2
    state[0] = 1
    return state

  render: (state) ->
    str = ''
    for el, i in state
      if i % 5 is 0
        str += '\n'
      if el is -1
        str += '#'
      else if el is 1
        str += '@'
      else if el is 2
        str += '$'
      else
        str += ' '
    return str

  advance: (state, action) ->
    state = _copy state
    oldState = _copy state
    playerCoord = null

    for val, i in state when val isnt 1
      if Math.random() < 0.05
        if val is 0
          oldState[i] = -1
        if val is -1
          oldState[i] = 0

    for val, i in state
      if val is 1
        playerCoord = _getCoord i
        state[i] = 0
        break

    #console.log playerCoord, action

    switch action
      when 0 then playerCoord.x -= 1
      when 1 then playerCoord.y -= 1
      when 2 then playerCoord.x += 1
      when 3 then playerCoord.y += 1

    #console.log playerCoord

    reward = 0

    unless 0 <= playerCoord.x < 5 and 0 <= playerCoord.y < 5
      return {
        state: oldState
        reward: -1
      }
    switch state[_toIndex playerCoord]
      when -1
        return {
          state: oldState
          reward: -1
        }
      when 2
        reward = 10
    ###
    if Math.random() < 0.1
      state[0] = 2
    if Math.random() < 0.1
      state[_toIndex {x: 4, y: 0}] = 2
    if Math.random() < 0.1
      state[_toIndex {x: 0, y: 4}] = 2
    if Math.random() < 0.1
      state[_toIndex {x: 4, y: 4}] = 2
    ###

    for val, i in state when val isnt 1
      if Math.random() < 0.001
        if val is 0
          state[i] = -1
        if val is -1
          state[i] = 0

    state[_toIndex playerCoord] = 1
    return {
      state: state
      reward: reward
    }
}

gameDumb = new Game {
  inputs: 2
  outputs: 2
  advance: (state, action) ->
    state = _copy state
    if (state[0] > state[1]) is (action is 0)
      reward = 1
    else
      reward = -1
    state[0] = Math.random()
    state[1] = Math.random()
    return {
      state: state
      reward: reward
    }

  init: (state) ->
    state[0] = Math.random()
    state[1] = Math.random()

  render: (state) -> state[0].toPrecision(2) + '|' + state[1].toPrecision(2)
}

gameNot = new Game {
  inputs: 2
  outputs: 1
  advance: (state, action) ->
    reward = if state[0] > state[1] then 1 else 0
    state[0] = Math.random()
    state[1] = Math.random()
    return {
      state: state
      reward: reward
    }

  init: (state) -> state[0] = Math.random(); state[1] = Math.random()
  render: (state) -> state[0].toString() + '|' + state[1].toString()
}

class Agent
  constructor: (@game) ->
    @qLearner = new qLearning.LinearQLearner @game.inputs, [0...@game.outputs], 0.01, 0.1, 0.1
    #@qLearner = new qLearning.LinearQLearner @game.inputs, [0...@game.outputs], 0.1, 0, 1

  step: (state) ->
    {action, estimate} = @qLearner.forward state
    {state: newState, reward} = obj = @game.advance state, action
    obj.action = action
    obj.reward = reward
    if state[0] is 1 and action in [2, 3]
      console.log 'ACTION', action, 'REWARD', reward
    @qLearner.learn state, action, newState, reward
    return obj

game = gameGrid

agent = new Agent game
state = new Float64Array game.inputs
exampleState = new Float64Array 25
exampleState[0] = 2
game.init state
randomState = _copy state
randomScore = 0
score = 0
go = ->
  console.log agent.qLearner.regressors[0].estimate exampleState
  console.log agent.qLearner.regressors[1].estimate exampleState
  console.log agent.qLearner.regressors[2].estimate exampleState
  console.log agent.qLearner.regressors[3].estimate exampleState
  {state, done, action, reward} = agent.step state
  {state: randomState, reward: randomReward} = game.advance randomState, _rand [0...game.outputs]
  randomScore += randomReward
  score += reward
  console.log score
  console.log game.render state
  console.log randomScore
  console.log game.render randomState
  setTimeout go, 1000 / 60
go()
