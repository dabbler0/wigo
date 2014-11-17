{Agent} = require './agent.coffee'
{DumbGame} = require './games/dumbGame.coffee'
{Blackjack} = require './games/blackjack.coffee'

_zip = (arrays) -> arrays[0].map (_,i) -> arrays.map (a) -> a[i]

game = new Blackjack()#5, 5
console.log game.state
agent = new Agent game, game.state.andCombinators(1), {discount: 0.5, forwardMode: 'softmax'}
score = 0
move = ->
  score += agent.act()
  process.stdout.write("\u001b[2J\u001b[0;0H")
  console.log score
  console.log game.render()
  #console.log _zip([agent.learner.regressors[0].thetas, agent.learner.regressors[1].thetas]).map((x) -> x.join('\t')).join('\n')
  setTimeout move, 10
move()
