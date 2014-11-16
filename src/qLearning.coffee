###
WIGO Q-Learning/SARSA-Learning implementation
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###

helper = require './helper.coffee'
{Regressor} = require './regressor.coffee'

# # QLearner
# Linear combination regresssion Q-learning agent
exports.QLearner = class QLearner
  constructor: (@actions, @bases, opts) ->
    @rate = opts.rate ? 1
    @discount = opts.discount ? 0.5
    @forwardMode = opts.forwardMode ? 'epsilonGreedy'

    @epsilon = opts.epsilon ? 0.1
    @logEpsilon = Math.log @epsilon
    @minEpsilon = opts.minEpsilon ? 0.01
    @epsilonFade = opts.epsilonFade ? 0

    @temperature = opts.temperature ? 1

    # Add a bias term
    @bases.unshift (-> 1)

    @rate /= @bases.length

    # Init thetas to zero
    @regressors = (new Regressor(@bases, @rate) for [0...@actions])

  # ## estimate
  # Get linear regression prediction for reward
  # for given state and action
  estimate: (state, action) -> @regressors[action].estimate(state)

  # ## max
  # Get best action and associated predicted reward from given state
  max: (state) ->
    best = null; max = -Infinity
    for action in [0...@actions]
      estimate = @estimate state, action
      if estimate > max
        max = estimate; best = [action]
      else if estimate is max
        best.push action
    return {
      action: helper._rand best
      estimate: max
    }

  # ## softmax
  # Get a random action, weighted by the expected
  # reward of the actions (all made positive with e^x).
  softmax: (state) ->
    weights = (helper._pow(@estimate(state, action) / @temperature) for action in [0...@actions])
    action = helper._weightedRandom weights
    return {
      action: action
      estimate: @estimate state, action
    }

  # ## epsilonGreedy
  # Get best action, except with probability epsilon,
  # in which case get random action. This is important
  # so the agent keeps exploring and learning.
  epsilonGreedy: (state) ->
    if Math.random() < @epsilon
      return {
        action: action = helper._rand @actions
        estimate: @estimate state, action
      }
    else @max state

  # ## forward
  # Return the chosen action based on the strategy in the opts
  forward: (state) ->
    if @forwardMode is 'softmax'
      return @softmax state
    else
      @logEpsilon -= @epsilonFade
      @epsilon = Math.max @minEpsilon, Math.pow Math.E, @logEpsilon
      return @epsilonGreedy state

  # ## learn
  # Update linreg coefficients to learn
  # from given action/reward pair.
  backward: (state, action, newState, reward) ->
    @regressors[action].feed state, reward + if newState? then @discount * @forward(newState).estimate else 0
