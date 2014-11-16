###
WIGO helper functions.
Public domain.
###

exports._rand = _rand = (x) ->
  if typeof x is 'number'
    return Math.floor Math.random() * x
  else if 'length' of x
    return x[_rand x.length]

exports._randBit = _randBit = -> if Math.random() < 0.5 then 1 else 0

exports._pow = _pow = (x) -> Math.pow 10, x

exports._sum = _sum = (list) ->
  s = 0
  s += x for x in list
  return s

exports._weightedRandom = (list) ->
  barrier = Math.random() * _sum list
  point = 0
  for el, i in list
    point += el
    if point > barrier
      return i
  return list.length
