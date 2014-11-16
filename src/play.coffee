{Agent} = require './agent.coffee'
{DumbGame} = require './games/dumbGame.coffee'

game = new DumbGame()#5, 5
console.log game.state
agent = new Agent game, game.state.andCombinators(1), {discount: 0.9}
score = 0
move = ->
  score += agent.act()
  #process.stdout.write("\u001b[2J\u001b[0;0H")
  console.log score
  console.log game.render()
  console.log agent.learner.regressors[0].thetas
  setTimeout move, 100
move()
