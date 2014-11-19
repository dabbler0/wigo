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
  # basis functions and current thetas.
  #
  # Returns sum(theta[i] * basis[i]).
  estimate: (input) ->
    output = 0
    for basis, i in @bases
      output += @thetas[i] * basis(input)
    return output

  # ## feed
  # Given an input/output map, do another gradient descent iteration to improve
  # thetas.
  feed: (input, output) ->
    # Get the gradient (error term)
    gradient = @estimate(input) - output
    for basis, i in @bases
      # Apply gradient descent formula. `@lambda` is the regularization term, and penalizes
      # high coefficients to avoid overfitting.
      @thetas[i] -= @rate * (gradient + @lambda * @thetas[i] / @thetas.length) * basis(input)

  # ## serialize
  serialize: -> {
    thetas: @thetas
    rate: @rate
    lambda: @lambda
  }
