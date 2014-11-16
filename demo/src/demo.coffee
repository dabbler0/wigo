game = new wigo.GridGame 5, 5
agent = new wigo.Agent game, game.state.andCombinators(2), {discount: 0.9, forwardMode: 'epsilonGreedy'}

scoreReport = document.querySelector '#score'
canvas = document.querySelector '#render'
ctx = canvas.getContext '2d'

speed = 100
slider = document.querySelector '#speed'
slider.addEventListener 'input', ->
  value = Number @value
  speed = 100 /  Math.log value + 1

score = 0
move = ->
  score += agent.act()
  game.renderCanvas ctx, canvas
  scoreReport.innerText = scoreReport.textContent = score
  setTimeout move, speed

move()
