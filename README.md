<!--
Notes to CSC490:
tl;dr To read the README, go here instead: https://github.com/dabbler0/wigo

This document is written in Github-Flavored Markdown. It is human-readable as is, and you can read it, but it's really much more pleasant (especially because of tables and syntax highlighting) to see this compiled as gfm and using the gfm stylesheets. So go online.

Also, be aware that we're still changing the live demo source on https://dabbler0.github.io/wigo. The demo online may differ from what is described here. The README at https://github.com/dabbler0/wigo will always reflect the actual demo.
-->

Well-Informed Game Operator
===========================

This is an implementation of S.A.R.S'.A'.-Learning based on linear regression. It is designed to play, without prior knowledge, any game with discrete inputs and discrete outputs. It learns while playing, so will lose for a while at first, then start winning as it learns to play. For a demo with a bunch of different example games, see here: http://dabbler0.github.io/wigo.

Notes About the Demo
--------------------
The demo features a bunch of config settings for the agent:

Setting      |Recommended Value |Notes
-------------|------------------|--------
Bases        |"Degree 2 "and" combinations"; or "Simple linear" for very simple games | The basis functions (see below) to use for linear regression. "Degree 2 'and' combinations" gets `n^2` bases, with the "and" of each combination of two bits; "simple linear" is the set of `n` bases that is literally the input bits.
Learning Rate|1                 | The normalized "learning rate" for the linreg gradient descent. The actual learning rate (alpha in the gradient descent formula) is computed as `1/n`, where `n` is the number of bases.
Forward Mode |Softmax           | The SARSA learner needs to have a small probability of doing a non-"optimal" action, so that it can explore and learn about new, possibly better strategies. Softmax does this by doing a probabilistically-weighted selection of actions instead of choosing the best one; epsilon-greedy does this by having a fixed, small probability of choosing a uniformly random action.
Temperature  |0.1               | The temperature in the softmax computation. Softmax probability weights are proportional to `e^(x/t)` where `x` is the expected reward of the action and `t` is the temperature. Lower temperatures mean lower probabilities of choosing non-"optimal" actions.
Epsilon      |0.1 (or not set)  | The epsilon in the epsilon-greedy computation. The probability that a uniformly random action is taken, instead of the "optimal" one.

The demo also features a bunch of example games:

Game                 |Notes
---------------------|--------------
Treasure Hunt        | A simple game, but with a large set of inputs. The agent is in a 5x5 grid with some walls and a prize that rotates around the four corners, and must learn to get the prize and avoid the walls.
Simplified Blackjack | Another simple game. Standard 52-card deck. Each turn, the agent can choose to either hit or stay, as in blackjack; if it goes over 21, it loses. If it stays under 21, the dealer is assigned a uniformly random sum between 10 and 21, and if the agent beats the dealer, it wins.
Chase                | The agent is on a 5x5 grid, and must chase a moving prize. However, the prize always respawns at the same point -- ideally (and in most cases), the agent learns to sit on the spawn point and get lots of points.
Flee                 | There is one moving enemy, and the agent must learn to avoid it. **This is a complex game, and training can take over half an hour**. However, the agent does learn to avoid pretty well.
Snake                | The classic arcade game of Snake; the agent must try to make the longest non-self-intersecting snake possible, while avoiding some random walls. **This is a complex game, and training can take over an hour**. However, the agent can also learn to win this.
2048                 | The popular online numbers game. It's unclear if SARSA learning can successfully solve this game.

At first, the score graph will go down quickly (since most of these games are designed to be lost by a random player). If the agent learns successfully, you will see the graph level out, and, in games where it is possible to win, it will start to rise again.

API Usage
---------
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

Some simple basis function generators that are provided in the WIGO package:
```coffeescript
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

### Serializing Agent Data
You can dump your agent data to a dead JavaScript object by calling `agent.serialize()`; the `QLearner` and `Regressor` classes have analagous methods. **Make sure you remember your basis functions, because those can't be serialized.** There isn't currently away to load them back again from serialized form, but aside from basis functions there is enough information in the serialization to reconstruct the entire agent.

Contributing
============

WIGO is built with `bower`, `gulp`, and `browserify`.

Clone the repo. Get `node` and `npm`. Get gulp and bower:
```
npm install -g gulp
npm install -g bower
```

Get dependencies for the repo:
```
npm install
bower install
```

Then, to build:
```
gulp
```

There are two subtasks, `gulp browser` and `gulp demo`, to build WIGO core and to build the demo, respectively.

Directory Structure
-------------------
```
./
  ./src
    ./src/games
      # All the subclasses of Game
    # Core WIGO source files: gradient descent, Q/SARSA learning
  ./build
    ./demo/browser.js # The distribution file
  ./demo
    ./demo/src
      ./demo/src/demo.coffee # demo coffeescript
    ./demo/js
      ./demo/js/demo.js # built demo js; don't edit this by hand
    ./demo/index.html # the demo
```

Todo and Unfinished Experiments
-------------------------------

### Todo: True multiplayer games
  Right now all the games adversarial-ness is hard-coded in the game itself. There exists handles for turn changing in the game, because multiplayer was originally going to be supported by the WIGO environment; this should be implemented sometime. This would allow us to do experiments with self-play.

### Todo: Serializable basis functions
  Try requiring all basis functions to be serializable as dead JavaScript? Or even invent a mini-language for basis functions. This will allow us to have a more intuitive serialization/deserialization scheme.

### Experiment: Supervised vs. Unsupervised Training
  There is already a `compel` handle in the Agent class right now that allows supervised training. Try writing known-good AIs for games and training SARSA learning by compulsion, and seeing if it works better than SARSA learning by self-feedback.

### Experiment: Random/Genetic Basis Generation
  Cull any bases whose thetas are too close to zero, and randomly introduce new bases, to try to get a better basis pool than could be developed by hand. See the `random-regressors` branch for a prototype of this.

### Experiment: Internal State
  Try providing randomly-initialized "extra state" passed along each iteration, trained alongisde the action Q function (like estimation-maximization), and see if it helps with any games (2048 especially). Currently, the trained agent is stateless; this would change that, possibly for the better?

### More Fun Games To Implement
  - Battleship (agent should learn to shoot close to previous shot if it hit)
  - A simple platformer

