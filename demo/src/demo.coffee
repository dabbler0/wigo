# Rolling graph dependency
class RollingGraph
  constructor: (@canvas) ->
    @ctx = canvas.getContext '2d'
    @history = []
    @max = @min = 0

  feed: (data, channel = 0) ->
    @history.push data
    @max = Math.max data, @max
    @min = Math.min data, @min

  scale: (el) -> @canvas.height * (1 - (el - @min) / (@max - @min))

  render: ->
    @ctx.clearRect 0, 0, @canvas.width, @canvas.height

    @ctx.strokeStyle = '#00F'
    @ctx.beginPath()
    @ctx.moveTo 0, @scale @history[0]
    step = Math.max 1, Math.floor @history.length / @canvas.width
    for el, i in @history by step
      @ctx.lineTo @canvas.width * i / @history.length, @scale el

    @ctx.stroke()

    @ctx.fillStyle = '#000'
    @ctx.fillRect 0, @scale(0), @canvas.width, 1
# UI stuff
sizeProper = (el) ->
  el.width = el.height = el.style.height = el.offsetWidth

scoreReport = document.querySelector '#score'
canvas = document.querySelector '#render'
scoreCanvas = document.querySelector '#graph'
window.addEventListener 'resize', fn = ->
  sizeProper canvas
  sizeProper scoreCanvas
fn()

rolling = new RollingGraph scoreCanvas, 1000

ctx = canvas.getContext '2d'

speed = 10
speedInput = document.querySelector '#speed'
speedInput.addEventListener 'input', ->
  value = Number @value
  speed = 1000 /  value

softmaxOptions = document.querySelector '#softmax-options'
epsilonOptions = document.querySelector '#epsilon-options'

currentOptions = softmaxOptions

forwardMode = 'softmax'

forwardModeSelector = document.querySelector '#forward-mode'
forwardModeSelector.addEventListener 'change', ->
  currentOptions.style.display = 'none'
  switch @value
    when 'softmax'
      forwardMode = 'softmax'
      (currentOptions = softmaxOptions).style.display = 'block'
    when 'epsilon-greedy'
      forwardMode = 'epsilonGreedy'
      (currentOptions = epsilonOptions).style.display = 'block'

tempInput = document.querySelector '#softmax-temperature'
epsilonInput = document.querySelector '#epsilon-epsilon'
discountFactorInput = document.querySelector '#discount-factor'
learningRateInput = document.querySelector '#learning-rate'
getOptions = -> {
  rate: Number learningRateInput.value
  discount: Number discountFactorInput.value
  epsilon: Number epsilonInput.value
  temperature: Number tempInput.value
  forwardMode: forwardMode
}

gameSelector = document.querySelector '#game'
games = {
  'grid': wigo.GridGame
  'chase': wigo.ChaseGame
  'chased': wigo.ChasedGame
  'flee': wigo.FleeGame
  'blackjack': wigo.Blackjack
  'snake': wigo.SnakeGame
  '2048': wigo.GameNot
}
getGame = -> games[gameSelector.value]

kill = ->
document.querySelector('#apply').addEventListener 'click', ->
  kill()
  rolling.history = []; rolling.min = rolling.max = 0
  kill = playGame getGame(), getOptions()

document.querySelector('#export-history').addEventListener 'click', ->
  window.open 'data:application/json,' + encodeURIComponent JSON.stringify rolling.history

document.querySelector('#export-params').addEventListener 'click', ->
  window.open 'data:application/json,' + encodeURIComponent JSON.stringify agent.serialize()

agent = null
render = graph = true

document.querySelector('#render-board').addEventListener 'click', ->
  render = not render
document.querySelector('#show-history').addEventListener 'click', ->
  graph = not graph

combinators = [
  (game) -> game.state.andCombinators(1)
  (game) -> game.state.andCombinators(2)
]

combinator = combinators[1]

document.querySelector('#bases').addEventListener 'change', ->
  if @value is 'strict-linear'
    combinator = combinators[0]
  else if @value is 'degree-2'
    combinator = combinators[1]

# Game stuff

playGame = (Game, options) ->
  game = new Game 5, 5
  agent = new wigo.Agent game, combinator(game), options
  killed = false; timeout = null

  score = 0
  move = ->
    score += agent.act()
    rolling.feed score
    if graph
      rolling.render()
    if render
      game.renderCanvas ctx, canvas
    scoreReport.innerText = scoreReport.textContent = score
    unless killed
      timeout = setTimeout move, speed

  move()
  return -> killed = true: clearTimeout timeout
