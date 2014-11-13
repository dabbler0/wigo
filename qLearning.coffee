class Regressor
  constructor: (@bases, @rate = 0.1, @lambda = 0.1) ->
    @thetas = (0 for basis in @bases)

  estimate: (input) ->
    output = 0
    for basis, i in @bases
      output += @thetas[i] * basis(input)
    return output

  feed: (input, output) ->
    gradient = @estimate(input) - output
    for basis, i in @bases
      @thetas[i] -= @rate * (gradient + @lambda * @thetas[i] / @thetas.length) * basis(input)

_rand = (x) -> x[Math.floor Math.random() * x.length]
# ## QLearner
# Linear combination regresssion Q-learning agent
exports.QLearner = class QLearner
  constructor: (@stateSize, @actions, @rate = 0.5, @discount = 0.5, @epsilon = 0.1, @bases = []) ->
    @epsilon = 0.1
    # Add a bias term
    #@bases.unshift (-> 1)

    # Init thetas to zero
    @regressors = {}
    for action in @actions
      @regressors[action] = new Regressor @bases, @rate

  # Estimate: get linear regression prediction for reward
  # for given state and action
  estimate: (state, action) -> @regressors[action].estimate(state)

  # Forward: get best action and associated predicted reward
  # from given state
  max: (state) ->
    best = null; max = -Infinity
    for action in @actions
      estimate = @estimate state, action
      if estimate > max
        max = estimate; best = [action]
      else if estimate is max
        best.push action
    return {
      action: _rand best
      estimate: max
    }

  forward: (state) ->
    if Math.random() < @epsilon
      return {
        action: action = _rand @actions
        estimate: @estimate state, action
      }
    else @max state

  # Learn: update linreg coefficients to learn
  # from given action/reward pair.
  learn: (state, action, newState, reward) ->
    @regressors[action].feed state, reward + @discount * @forward(newState).estimate

# ## LinearQLearner
# Simple linear regression Q-learning agent
exports.LinearQLearner = class LinearQLearner extends QLearner
  constructor: (@stateSize, @actions, @rate, @discount) ->
    # Generate the linear basis terms
    @bases = []
    for i in [0...@stateSize] then do (i) =>
      @bases.push (state) -> state[i] * state[i]
      for j in [0...@stateSize] when j >= i then do (j) =>
        @bases.push (state) -> state[i] * state[j]

    # Inherit
    super @stateSize, @actions, @rate, @discount, 0.1, @bases

exports.PolynomialQLearner = class PolynomialQLearner extends QLearner
  _getBasisFunctions = (n, p) ->
    if n is 0
      return [(x) -> 1]
    else
      bases = _getBasisFunctions n - 1, p
      newBases = []
      for power in [0..p] then do (power) ->
        for base in bases then do (base) ->
          newBases.push (x) -> Math.pow(x[n - 1], power) * base(x)
      return newBases

  constructor: (@stateSize, @actions, @rate, @discount, @degree) ->
    super @stateSize, @actions, @rate, @discount, _getBasisFunctions @stateSize, @degree
