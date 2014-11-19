###
WIGO Example Usage with Simplified Blackjack
This software is public domain.
###

{Agent} = require './agent.coffee'
{Blackjack} = require './games/blackjack.coffee'

_zip = (arrays) -> arrays[0].map (_,i) -> arrays.map (a) -> a[i]

game = new Blackjack()
console.log game.state
agent = new Agent game, game.state.andCombinators(2), {discount: 0.5, forwardMode: 'softmax'}

score = 0
move = ->
  score += agent.act()
  console.log score
  console.log game.render()
  setTimeout move, 10
move()
