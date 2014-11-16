###
WIGO Simple Agent wrapper for Q/SARSA-Learner
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###

{QLearner} = require './qLearning.coffee'

# # Agent
# Wrapper class on QLearner that knows how to handle the bureaucracy
# that has to do with Games.
exports.Agent = class Agent
  constructor: (@game, @bases, opts = {}) ->
    @learner = new QLearner @game.actions, @bases, opts

  # ## act
  # Will interact with the game state on its own. Make a move
  # and learn from the reward.
  act: ->
    oldState = @game.state.clone()

    # Get said action and act upon it
    {action, estimate} = @learner.forward @game.state
    {reward, turn, terminated} = @game.advance action

    # Learn from the reward
    @learner.backward oldState, action, (if terminated then null else @game.state), reward

    return reward

  # ## compel
  # Force an agent to do an action and learn from it.
  compel: (action) ->
    oldState = @game.state.clone()

    # Get said action and act upon it
    {reward, turn} = @game.advance action

    # Learn from the reward
    @learner.backward oldState, action, @game.state, reward

    return reward
