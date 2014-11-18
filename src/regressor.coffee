###
WIGO stochastic regularized gradient descent linear regression implementation
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###

# # Regressor
# Keeps a running record of thetas; given new input/output maps,
# performs gradient descent linear regression on given basis functions.
exports.Regressor = class Regressor
  constructor: (@bases, @rate = 0.1, @lambda = 0.1) ->
    @thetas = (0 for basis in @bases)

  # ## estimate
  # Get the predicted output for the given input using
  # basis functions and current thetas
  estimate: (input) ->
    output = 0
    for basis, i in @bases
      output += @thetas[i] * basis(input)
    return output

  # ## feed
  # Given an input/output map, do another gradient descent iteration to improve
  # thetas.
  feed: (input, output) ->
    gradient = @estimate(input) - output
    for basis, i in @bases
      @thetas[i] -= @rate * (gradient + @lambda * @thetas[i] / @thetas.length) * basis(input)

  serialize: -> {
    thetas: @thetas
    rate: @rate
    lambda: @lambda
  }

# # RandomRegressor
exports.RandomRegressor = class RandomRegressor extends Regressor
  constructor: (@baseGenerator, @features, @rate = 0.1, @lambda = 0.1, @epsilon = 0.005) ->
    baseObjs = (@baseGenerator() for [0...@features])
    @bases = {}
    for base in baseObjs
      @bases[base.key] = base.base
      @thetas[base.key] = 0

    super @bases, @rate, @lambda

  # ## estimate
  # Get the predicted output for the given input using
  # basis functions and current thetas
  estimate: (input) ->
    output = 0
    for i, basis of @bases
      output += @thetas[i] * basis(input)
    return output

  addBase: ->
    base = @baseGenerator()
    @bases[base.key] = base.base
    @thetas[base.key] = 0

  # ## feed
  # Given an input/output map, do another gradient descent iteration to improve
  # thetas.
  feed: (input, output) ->
    gradient = @estimate(input) - output
    for i, basis of @bases
      @thetas[i] -= @rate * (gradient + @lambda * @thetas[i] / @thetas.length) * basis(input)

    # Prune thetas that are too small
    sum = 0
    for i, theta of @thetas
      sum += theta
    for i, theta of @thetas
      if Math.abs(theta / sum) < @epsilon
        delete @bases[i]
        delete @thetas[i]
        @addBase()
