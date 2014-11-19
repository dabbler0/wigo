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
  constructor: (@actions, @bases, @opts) ->
    # Fill in option defaults
    opts = @opts
    @rate = opts.rate ? 1
    @discount = opts.discount ? 0.5
    @forwardMode = opts.forwardMode ? 'epsilonGreedy'

    @epsilon = opts.epsilon ? 0.1

    @temperature = opts.temperature ? 1

    # Add a bias term
    @bases.unshift (-> 1)

    # Normalize the learning rate
    @rate /= @bases.length

    # Initialize regressors
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

      # Update `best` and `max` if we are better than them
      if estimate > max
        max = estimate; best = [action]
      else if estimate is max
        # If there are ties, we will choose randomly.
        best.push action

    # Choose randomly from among ties
    return {
      action: helper._rand best
      estimate: max
    }

  # ## softmax
  # Get a random action, weighted by the expected
  # reward of the actions (all made positive with e^x).
  softmax: (state) ->
    # Compute the exponential weights from the estimated rewards
    weights = (helper._pow(@estimate(state, action) / @temperature) for action in [0...@actions])

    # Get the weighted random action
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
    # With probability @epsilon, pick a random action
    if Math.random() < @epsilon
      return {
        action: action = helper._rand @actions
        estimate: @estimate state, action
      }

    # Otherwise, return true maximum expectation action.
    else @max state

  # ## forward
  # Return the chosen action based on the strategy in the opts
  forward: (state) ->
    if @forwardMode is 'softmax'
      return @softmax state
    else
      return @epsilonGreedy state

  # ## backward
  # Update linreg coefficients to learn
  # from given action/reward pair.
  backward: (state, action, newState, reward) ->
    @regressors[action].feed state, reward + if newState? then @discount * @forward(newState).estimate else 0

  # ## serialize
  serialize: -> {
    regressors: (regressor.serialize() for regressor in @regressors)
    opts: @opts
  }
