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

