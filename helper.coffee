exports._rand = (x) ->
  if typeof x is 'number'
    return Math.floor Math.random() * x
  else if 'length' of x
    return x[_rand x.length]

exports._randBit = -> if Math.random() < 0.5 then 1 else 0
