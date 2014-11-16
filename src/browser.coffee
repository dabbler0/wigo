helper = require './helper.coffee'
{Agent} = require './agent.coffee'

module.exports = {
  # Game types
  PathGame: require('./games/path.coffee').PathGame
  GridGame: require('./games/grid.coffee').GridGame
  DumbGame: require('./games/dumbGame.coffee').DumbGame
  ChaseGame: require('./games/chase.coffee').ChaseGame

  # Also export the Agent class for tweaking
  Agent: Agent
}
