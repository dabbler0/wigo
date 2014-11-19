###
WIGO helper functions.
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
###

# # _rand
# If `x` is a number, return a random integer between `0` and `x - 1`, inclusive.
# If `x` is an array, return a random element of `x`.
exports._rand = _rand = (x) ->
  if typeof x is 'number'
    return Math.floor Math.random() * x
  else if 'length' of x
    return x[_rand x.length]

# # _randBit
# Return with equal probability 0 or 1
exports._randBit = _randBit = -> _rand 2

# # _pow
# Return `e^x`.
exports._pow = _pow = (x) -> Math.pow Math.E, x

# # _sum
# Return the sum of all the elements in a list.
exports._sum = _sum = (list) ->
  s = 0
  s += x for x in list
  return s

# # _weightedRandom
# Return a random index of a list, weighted
# by the elements of the list. For instance, given `[1, 2, 1]`,
# would have an `0.25` probability of returning `0`, and `0.5` probability of
# returning `1`, and an `0.25` probability of returning `2`.
exports._weightedRandom = (list) ->
  barrier = Math.random() * _sum list
  point = 0
  for el, i in list
    point += el
    if point > barrier
      return i
  return list.length
