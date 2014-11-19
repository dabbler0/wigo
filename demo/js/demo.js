(function() {
  var RollingGraph, agent, canvas, combinator, combinators, ctx, currentOptions, discountFactorInput, epsilonInput, epsilonOptions, fn, forwardMode, forwardModeSelector, gameSelector, games, getGame, getOptions, graph, kill, learningRateInput, playGame, render, rolling, scoreCanvas, scoreReport, sizeProper, softmaxOptions, speed, speedInput, tempInput;

  RollingGraph = (function() {
    function RollingGraph(canvas) {
      this.canvas = canvas;
      this.ctx = canvas.getContext('2d');
      this.history = [];
      this.max = this.min = 0;
    }

    RollingGraph.prototype.feed = function(data, channel) {
      if (channel == null) {
        channel = 0;
      }
      this.history.push(data);
      this.max = Math.max(data, this.max);
      return this.min = Math.min(data, this.min);
    };

    RollingGraph.prototype.scale = function(el) {
      return this.canvas.height * (1 - (el - this.min) / (this.max - this.min));
    };

    RollingGraph.prototype.render = function() {
      var el, i, step, _i, _len, _ref;
      this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
      this.ctx.strokeStyle = '#00F';
      this.ctx.beginPath();
      this.ctx.moveTo(0, this.scale(this.history[0]));
      step = Math.max(1, Math.floor(this.history.length / this.canvas.width));
      _ref = this.history;
      for ((step > 0 ? (i = _i = 0, _len = _ref.length) : i = _i = _ref.length - 1); step > 0 ? _i < _len : _i >= 0; i = _i += step) {
        el = _ref[i];
        this.ctx.lineTo(this.canvas.width * i / this.history.length, this.scale(el));
      }
      this.ctx.stroke();
      this.ctx.fillStyle = '#000';
      return this.ctx.fillRect(0, this.scale(0), this.canvas.width, 1);
    };

    return RollingGraph;

  })();

  sizeProper = function(el) {
    return el.width = el.height = el.style.height = el.offsetWidth;
  };

  scoreReport = document.querySelector('#score');

  canvas = document.querySelector('#render');

  scoreCanvas = document.querySelector('#graph');

  window.addEventListener('resize', fn = function() {
    sizeProper(canvas);
    return sizeProper(scoreCanvas);
  });

  fn();

  rolling = new RollingGraph(scoreCanvas, 1000);

  ctx = canvas.getContext('2d');

  speed = 100;

  speedInput = document.querySelector('#speed');

  speedInput.addEventListener('input', function() {
    var value;
    value = Number(this.value);
    return speed = 100 / Math.log(value + 1);
  });

  softmaxOptions = document.querySelector('#softmax-options');

  epsilonOptions = document.querySelector('#epsilon-options');

  currentOptions = softmaxOptions;

  forwardMode = 'softmax';

  forwardModeSelector = document.querySelector('#forward-mode');

  forwardModeSelector.addEventListener('change', function() {
    currentOptions.style.display = 'none';
    switch (this.value) {
      case 'softmax':
        forwardMode = 'softmax';
        return (currentOptions = softmaxOptions).style.display = 'block';
      case 'epsilon-greedy':
        forwardMode = 'epsilonGreedy';
        return (currentOptions = epsilonOptions).style.display = 'block';
    }
  });

  tempInput = document.querySelector('#softmax-temperature');

  epsilonInput = document.querySelector('#epsilon-epsilon');

  discountFactorInput = document.querySelector('#discount-factor');

  learningRateInput = document.querySelector('#learning-rate');

  getOptions = function() {
    return {
      rate: Number(learningRateInput.value),
      discount: Number(discountFactorInput.value),
      epsilon: Number(epsilonInput.value),
      temperature: Number(tempInput.value),
      forwardMode: forwardMode
    };
  };

  gameSelector = document.querySelector('#game');

  games = {
    'grid': wigo.GridGame,
    'path': wigo.PathGame,
    'chase': wigo.ChaseGame,
    'flee': wigo.FleeGame,
    'blackjack': wigo.Blackjack,
    'snake': wigo.SnakeGame
  };

  getGame = function() {
    return games[gameSelector.value];
  };

  kill = function() {};

  document.querySelector('#apply').addEventListener('click', function() {
    kill();
    return kill = playGame(getGame(), getOptions());
  });

  document.querySelector('#export-history').addEventListener('click', function() {
    return window.open('data:application/json,' + encodeURIComponent(JSON.stringify(rolling.history)));
  });

  document.querySelector('#export-params').addEventListener('click', function() {
    return window.open('data:application/json,' + encodeURIComponent(JSON.stringify(agent.serialize())));
  });

  agent = null;

  render = graph = true;

  document.querySelector('#render-board').addEventListener('click', function() {
    return render = !render;
  });

  document.querySelector('#show-history').addEventListener('click', function() {
    return graph = !graph;
  });

  combinators = [
    function(game) {
      return game.state.andCombinators(1);
    }, function(game) {
      return game.state.andCombinators(2);
    }
  ];

  combinator = combinators[0];

  document.querySelector('#bases').addEventListener('change', function() {
    if (this.value === 'strict-linear') {
      return combinator = combinators[0];
    } else if (this.value === 'degree-2') {
      return combinator = combinators[1];
    }
  });

  playGame = function(Game, options) {
    var game, killed, move, score;
    game = new Game(5, 5);
    agent = new wigo.Agent(game, combinator(game), options);
    killed = false;
    score = 0;
    move = function() {
      score += agent.act();
      rolling.feed(score);
      if (graph) {
        rolling.render();
      }
      if (render) {
        game.renderCanvas(ctx, canvas);
      }
      scoreReport.innerText = scoreReport.textContent = score;
      if (!killed) {
        return setTimeout(move, speed);
      }
    };
    move();
    return function() {
      return killed = true;
    };
  };

}).call(this);
