###
WIGO Q-Learning/SARSA-Learning implementation
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###

helper = require './helper'
{Regressor} = require './regressor'

# # QLearner
# Linear combination regresssion Q-learning agent
exports.QLearner = class QLearner
  constructor: (@stateSize, @actions, @rate = 0.5, @discount = 0.5, @epsilon = 0.1, @bases = []) ->
    @epsilon = 0.1
    # Add a bias term
    #@bases.unshift (-> 1)

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
    for action in @actions
      estimate = @estimate state, action
      if estimate > max
        max = estimate; best = [action]
      else if estimate is max
        best.push action
    return {
      action: helper._rand best
      estimate: max
    }

  # ## forward
  # Get best action, except with probability epsilon,
  # in which case get random action. This is important
  # so the agent keeps exploring and learning.
  forward: (state) ->
    if Math.random() < @epsilon
      return {
        action: action = _rand @actions
        estimate: @estimate state, action
      }
    else @max state

  # ## learn
  # Update linreg coefficients to learn
  # from given action/reward pair.
  learn: (state, action, newState, reward) ->
    @regressors[action].feed state, reward + @discount * @forward(newState).estimate
