_rand = (x) -> x[Math.floor Math.random() * x.length]
# ## QLearner
# Linear combination regresssion Q-learning agent
exports.QLearner = class QLearner
  constructor: (@stateSize, @actions, @rate = 0.5, @discount = 1, @bases = []) ->
    @epsilon = 0.1
    # Add a bias term
    @bases.unshift (-> 1)

    # Init thetas to zero
    @thetas = {}
    for action in @actions
      @thetas[action] =  (0 for basis in @bases)

  # Estimate: get linear regression prediction for reward
  # for given state and action
  estimate: (state, action) ->
    q = 0
    for basis, i in @bases
      console.log basis(state), @thetas[action][i], q
      q += @thetas[action][i] * basis(state)
    console.log q
    return q

  # Forward: get best action and associated predicted reward
  # from given state
  max: (state) ->
    best = null; max = -Infinity
    for action in @actions
      estimate = @estimate state, action
      console.log 'estimate', estimate
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
    thetas = []
    console.log @thetas[action]
    error = reward + 0 * @discount * @forward(newState).estimate - @estimate(state, action)
    for t, i in @thetas[action]
      thetas.push t + @rate * @bases[i](state) * (error - t)
    @thetas[action] = thetas

# ## LinearQLearner
# Simple linear regression Q-learning agent
exports.LinearQLearner = class LinearQLearner extends QLearner
  constructor: (@stateSize, @actions, @rate, @discount) ->
    # Generate the linear basis terms
    bases = []
    for i in [0...@stateSize] then do (i) =>
      bases.push (state) -> state[i]
      for j in [0...@stateSize] when j >= i then do (j) =>
        bases.push (state) -> state[i] * state[j]

    # Inherit
    super @stateSize, @actions, @rate, @discount, bases

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
