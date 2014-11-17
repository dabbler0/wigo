Well-Informed Game Operator
===========================

This is an implementation of S.A.R.S'.A'.-Learning based on linear regression.

Usage
-----
WIGO is a Browserify package, so can be included in any number of ways (via browserify, amd, nodejs, or as a browser global).

Example usage with Blackjack:
```coffeescript
blackjack = new wigo.Blackjack()
agent = new wigo.Agent(
  blackjack, # Game to play
  blackjack.state.andCombinators(1), # Bases to use in linear regression; see below
  { # Options for SARSA Learning:
    rate: 1 # N * learning rate; maximum 1
    discount: 0.9 # Discount factor; strictly less than one
    forwardMode: 'softmax' # Either 'softmax' or 'epsilonGreedy'
    temperature: 0.1 # Temperature in exponential softmax
    epsilon: 0.1 # If we were using epsilonGreedy, we would provide epsilon instead of temperature
  }
)

# Tell the agent to make a move
agent.act()
```

### Linear Regression Bases
The agent will learn by estimating a function approximator based on a linear combination of the basis functions that you give it. That is, it will come up with a set of parameters `thetas[]` and compute the expected reward as:
```
bases[0](state) * thetas[0] + bases[1](state) * thetas[1] ...
```

Some simple basis function generatirs that are provided in the WIGO package:
```
game.state.andCombinators(n) # Return a set of basis functions that are every possible set of `n` bits,
                             # "and"ed together. Returns (|state| choose n) functions.
game.state.orCombinators(n) # The "or" analogue of `andCombinators`.
# game.state.andCombinators(1) or game.state.orCombinators(1) are just the state bits themselves.
```

Making a WIGO Game
------------------
To make a WIGO game, extend the wigo.Game class. Every WIGO game state consists of a certain number of equally-sized arrays.

Every game must implement the `advance(action)` function, which update its state and returns a reward.

In this example we will implement a game where the agent must move right and left on a one-dimensional world to reach a randomly-placed prize.
```coffeescript
class MyGame extends wigo.Game
  constructor: ->
    super(
      10, # Number of squares per layer. Our 1D world will be 10 squares long
      2, # Number of possible actions. 2: mover right or move left
      2 # Number of layers; usually the number of different types of "pieces"
        # We have two: the player piece and the prize piece(s)
    )
    
    @state.layers[0][0] = 1 # Say that there is a player piece in the 0th square
    @state.layers[1][9] = 1 # Say that there is a prize piece in the 9th square
    
    @currentPlayerPosition = 0

  advance: (action) -> # Action will be guaranteed to be in the range [0...n], where n is the number of actions
                       # we specified in our super() call in the constructor. So in this case, either 0 or 1.
    if action is 0 # We will have this mean "go left"
      if @currentPlayerPosition > 0 # Make sure we don't go off the board
        @state.layers[0][@currentPlayerPosition] = 0 # Remove the player piece from the current position
        @currentPlayerPosition--
        @state.layers[0][@currentPlayerPosition] = 1 # Place the player piece in the new position
    if action is 1 # "Go right"
      if @currentPlayerPosition < 9
        @state.layers[0][@currentPlayerPosition] = 0
        @currentPlayerPosition++
        @state.layers[0][@currentPlayerPosition] = 1
    
    reward = 0
    
    # Check to see if there is a prize piece on our current location
    if @state.layers[1][@currentPlayerPosition] is 1
      reward = 1
    
    return {
      reward: reward # What was the reward for that action?
      turn: 0 # Whose turn is it (in this case, we are a one player game, so always 0)
      terminated: false # Did we end an episode? This means to signal to the SARSA learner
                        # not to consider this next state to be a result of the action taken
                        # from the previous state. This game never ends (has only one episode)
                        # so here this will always be false.
    }
```
