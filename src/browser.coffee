###
###

helper = require './helper.coffee'
{Agent} = require './agent.coffee'

module.exports = {
  # Game types
  PathGame: require('./games/path.coffee').PathGame
  GridGame: require('./games/grid.coffee').GridGame
  DumbGame: require('./games/dumbGame.coffee').DumbGame
  ChaseGame: require('./games/chase.coffee').ChaseGame
  Blackjack: require('./games/blackjack.coffee').Blackjack
  NotGame: require('./games/2048.coffee').NotGame
  ChasedGame: require('./games/chase.coffee').ChasedGame
  FleeGame: require('./games/flee.coffee').FleeGame
  SnakeGame: require('./games/snake.coffee').SnakeGame

  # Agent class
  Agent: Agent
}
