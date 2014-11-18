!function(e){if("object"==typeof exports&&"undefined"!=typeof module)module.exports=e();else if("function"==typeof define&&define.amd)define([],e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),f.wigo=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){

/*
WIGO Simple Agent wrapper for Q/SARSA-Learner
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
 */
var Agent, QLearner;

QLearner = require('./qLearning.coffee').QLearner;

exports.Agent = Agent = (function() {
  function Agent(game, bases, opts) {
    this.game = game;
    this.bases = bases;
    if (opts == null) {
      opts = {};
    }
    this.learner = new QLearner(this.game.actions, this.bases, opts);
  }

  Agent.prototype.act = function() {
    var action, estimate, oldState, reward, terminated, turn, _ref, _ref1;
    oldState = this.game.state.clone();
    _ref = this.learner.forward(this.game.state), action = _ref.action, estimate = _ref.estimate;
    _ref1 = this.game.advance(action), reward = _ref1.reward, turn = _ref1.turn, terminated = _ref1.terminated;
    this.learner.backward(oldState, action, (terminated ? null : this.game.state), reward);
    return reward;
  };

  Agent.prototype.compel = function(action) {
    var oldState, reward, turn, _ref;
    oldState = this.game.state.clone();
    _ref = this.game.advance(action), reward = _ref.reward, turn = _ref.turn;
    this.learner.backward(oldState, action, this.game.state, reward);
    return reward;
  };

  Agent.prototype.serialize = function() {
    return this.learner.serialize();
  };

  return Agent;

})();

Agent.fromSerialization = function(game, bases, serialized) {
  var agent;
  agent = new Agent(game, bases);
  agent.learner = QLearner.fromSerialization(serialized);
  return agent;
};


},{"./qLearning.coffee":10}],2:[function(require,module,exports){
var Agent, helper;

helper = require('./helper.coffee');

Agent = require('./agent.coffee').Agent;

module.exports = {
  PathGame: require('./games/path.coffee').PathGame,
  GridGame: require('./games/grid.coffee').GridGame,
  DumbGame: require('./games/dumbGame.coffee').DumbGame,
  ChaseGame: require('./games/chase.coffee').ChaseGame,
  NotGame: require('./games/2048.coffee').NotGame,
  Agent: Agent
};


},{"./agent.coffee":1,"./games/2048.coffee":4,"./games/chase.coffee":5,"./games/dumbGame.coffee":6,"./games/grid.coffee":7,"./games/path.coffee":8,"./helper.coffee":9}],3:[function(require,module,exports){

/*
WIGO game definition schema
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
 */
var Game, State;

exports.State = State = (function() {
  function State(size, nLayers) {
    this.size = size;
    if (nLayers == null) {
      nLayers = 1;
    }
    this.layers = (function() {
      var _i, _results;
      _results = [];
      for (_i = 0; 0 <= nLayers ? _i < nLayers : _i > nLayers; 0 <= nLayers ? _i++ : _i--) {
        _results.push(new Uint8Array(this.size));
      }
      return _results;
    }).call(this);
  }

  State.prototype.clone = function() {
    var bit, clone, i, j, layer, _i, _j, _len, _len1, _ref;
    clone = new State(this.size, this.layers.length);
    _ref = this.layers;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      layer = _ref[i];
      for (j = _j = 0, _len1 = layer.length; _j < _len1; j = ++_j) {
        bit = layer[j];
        clone.layers[i][j] = bit;
      }
    }
    return clone;
  };

  State.prototype.eachBit = function(fn) {
    var bit, i, j, layer, _i, _len, _ref, _results;
    _ref = this.layers;
    _results = [];
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      layer = _ref[i];
      _results.push((function() {
        var _j, _len1, _results1;
        _results1 = [];
        for (j = _j = 0, _len1 = layer.length; _j < _len1; j = ++_j) {
          bit = layer[j];
          _results1.push(fn(i, j));
        }
        return _results1;
      })());
    }
    return _results;
  };

  State.prototype.combinators = function(degree) {
    var combinators, subcombinators;
    if (degree > 1) {
      subcombinators = this.combinators(degree - 1);
    } else {
      subcombinators = [[]];
    }
    combinators = [];
    this.eachBit((function(_this) {
      return function(i, j) {
        var combinator, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = subcombinators.length; _i < _len; _i++) {
          combinator = subcombinators[_i];
          _results.push(combinators.push(combinator.concat([[i, j]])));
        }
        return _results;
      };
    })(this));
    return combinators;
  };

  State.prototype.andCombinators = function(degree) {
    return this.combinators(degree).map((function(_this) {
      return function(combination) {
        return function(state) {
          var coordinate, _i, _len;
          for (_i = 0, _len = combination.length; _i < _len; _i++) {
            coordinate = combination[_i];
            if (state.layers[coordinate[0]][coordinate[1]] === 0) {
              return 0;
            }
          }
          return 1;
        };
      };
    })(this));
  };

  State.prototype.orCombinators = function(degree) {
    return this.combinators(degree).map((function(_this) {
      return function(combination) {
        return function(state) {
          var coordinate, _i, _len;
          for (_i = 0, _len = combination.length; _i < _len; _i++) {
            coordinate = combination[_i];
            if (state.layers[coordinate[0]][coordinate[1]] === 1) {
              return 1;
            }
          }
          return 0;
        };
      };
    })(this));
  };

  return State;

})();

exports.Game = Game = (function() {
  function Game(size, actions, nLayers, players) {
    this.size = size;
    this.actions = actions;
    this.nLayers = nLayers != null ? nLayers : 1;
    this.players = players != null ? players : 1;
    this.state = new State(this.size, this.nLayers);
  }

  Game.prototype.advance = function(action) {
    return {
      reward: 0,
      turn: 0
    };
  };

  Game.prototype.render = function() {
    return '';
  };

  Game.prototype.renderCanvas = function(canvas, ctx) {};

  return Game;

})();


},{}],4:[function(require,module,exports){

/*
WIGO 2048 game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
 */
var Game, NotGame, SPAWN_FOUR_PROBABILITY,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Game = require('../game.coffee').Game;

SPAWN_FOUR_PROBABILITY = 0.1;

exports.NotGame = NotGame = (function(_super) {
  var dirs;

  __extends(NotGame, _super);

  dirs = {
    0: [0, -1],
    1: [1, 0],
    2: [0, 1],
    3: [-1, 0]
  };

  function NotGame() {
    NotGame.__super__.constructor.call(this, 16, 4, 12);
    this.addRandom();
    this.addRandom();
  }

  NotGame.prototype.convert = function(i, j) {
    return i * 4 + j;
  };

  NotGame.prototype.addRandom = function() {
    var free, i, j, n, _i, _j;
    free = [];
    for (i = _i = 0; _i < 4; i = ++_i) {
      for (j = _j = 0; _j < 4; j = ++_j) {
        if (this.value(this.convert(i, j)) === 0) {
          free.push(this.convert(i, j));
        }
      }
    }
    if (free.length > 0) {
      n = free[Math.floor(Math.random() * free.length)];
      return this.state.layers[Math.random() > (1 - SPAWN_FOUR_PROBABILITY) ? 2 : 1][n] = 1;
    }
  };

  NotGame.prototype.value = function(pos) {
    var l, _i;
    for (l = _i = 0; _i < 12; l = ++_i) {
      if (this.state.layers[l][pos]) {
        return l;
      }
    }
    return 0;
  };

  NotGame.prototype.valid = function(x, y) {
    return x >= 0 && x < 4 && y >= 0 && y < 4;
  };

  NotGame.prototype.getNext = function(x, y, dir) {
    var cur, prev;
    prev = [x, y];
    cur = [x + dirs[dir][0], y + dirs[dir][1]];
    while (this.valid(cur[0], cur[1]) && this.value(this.convert(cur[0], cur[1])) === 0) {
      prev[0] = cur[0];
      prev[1] = cur[1];
      cur = [cur[0] + dirs[dir][0], cur[1] + dirs[dir][1]];
    }
    return {
      farthest: prev,
      next: this.convert(cur[0], cur[1])
    };
  };

  NotGame.prototype.lost = function() {
    var d, i, j, other, val, _i, _j, _k, _l;
    for (i = _i = 0; _i < 16; i = ++_i) {
      if (this.value(i) === 0) {
        return false;
      }
    }
    for (i = _j = 0; _j < 4; i = ++_j) {
      for (j = _k = 0; _k < 4; j = ++_k) {
        val = this.value(this.convert(i, j));
        if (val !== 0) {
          for (d = _l = 0; _l < 4; d = ++_l) {
            other = [i + dirs[d][0], j + dirs[d][1]];
            if (this.valid(other[0], other[1])) {
              if (this.value(this.convert(other[0], other[1])) === val) {
                return false;
              }
            }
          }
        }
      }
    }
    return true;
  };

  NotGame.prototype.advance = function(action) {
    var i, j, l, merged, moved, next, p, ret, reward, terminated, val, x, y, _i, _j, _k, _l, _m;
    console.log('action is ' + action);
    merged = (function() {
      var _i, _results;
      _results = [];
      for (_i = 0; _i < 16; _i++) {
        _results.push(false);
      }
      return _results;
    })();
    x = [];
    y = [];
    for (i = _i = 0; _i < 4; i = ++_i) {
      x.push(i);
      y.push(i);
    }
    if (dirs[action][0] === 1) {
      x = x.reverse();
    }
    if (dirs[action][1] === 1) {
      y = y.reverse();
    }
    reward = 0;
    moved = false;
    terminated = false;
    for (i = _j = 0; _j < 4; i = ++_j) {
      for (j = _k = 0; _k < 4; j = ++_k) {
        val = this.value(this.convert(x[i], y[j]));
        if (val !== 0) {
          ret = this.getNext(x[i], y[j], action);
          next = ret.next;
          if (this.value(next) === val && !merged[next]) {
            this.state.layers[val + 1][next] = 1;
            this.state.layers[val][this.convert(x[i], y[j])] = 0;
            this.state.layers[val][next] = 0;
            reward += Math.pow(2, val + 1);
            moved = true;
            if (val === 10) {
              terminated = true;
              break;
            }
            merged[this.convert(x[i], y[j])] = true;
          } else if (x[i] !== ret.farthest[0] || y[j] !== ret.farthest[1]) {
            this.state.layers[val][this.convert(x[i], y[j])] = 0;
            this.state.layers[val][this.convert(ret.farthest[0], ret.farthest[1])] = 1;
            moved = true;
          }
        }
      }
    }
    if (moved) {
      this.addRandom();
    } else {
      reward = -32;
    }
    if (this.lost()) {
      terminated = true;
      reward = -2048;
    }
    if (terminated) {
      for (l = _l = 0; _l < 12; l = ++_l) {
        for (p = _m = 0; _m < 16; p = ++_m) {
          this.state.layers[l][p] = 0;
        }
      }
      this.addRandom();
      this.addRandom();
    }
    return {
      reward: reward,
      turn: 0,
      terminated: terminated
    };
  };

  NotGame.prototype.render = function() {
    var i, j, str, _i, _j;
    str = '';
    for (i = _i = 0; _i < 4; i = ++_i) {
      for (j = _j = 0; _j < 4; j = ++_j) {
        str += (Math.pow(2, this.value(this.convert(i, j))) & 2046) + (j !== 3 ? '\t' : '');
      }
      str += '\n';
    }
    return str;
  };

  return NotGame;

})(Game);


},{"../game.coffee":3}],5:[function(require,module,exports){

/*
WIGO Dumb game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
 */
var ChaseGame, Game, PRIZE_SPAWN_PROBABILITY, WALL_DENSITY, helper,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Game = require('../game.coffee').Game;

helper = require('../helper.coffee');

PRIZE_SPAWN_PROBABILITY = 0.05;

WALL_DENSITY = 0.2;

exports.ChaseGame = ChaseGame = (function(_super) {
  var _dirs;

  __extends(ChaseGame, _super);

  function ChaseGame(w, h) {
    var i, _i, _ref;
    this.w = w != null ? w : 5;
    this.h = h != null ? h : 5;
    ChaseGame.__super__.constructor.call(this, this.w * this.h, 4, 3);
    for (i = _i = 0, _ref = this.w * this.h; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      if (__indexOf.call(this._corners(), i) < 0) {
        if (Math.random() < WALL_DENSITY) {
          this.state.layers[1][i] = 1;
        }
      }
    }
    this.state.layers[0][0] = 1;
    this.state.layers[2][this.w * this.h - 1] = 1;
  }

  ChaseGame.prototype._coord = function(index) {
    return {
      x: index % this.w,
      y: (index - (index % this.w)) / this.w
    };
  };

  ChaseGame.prototype._index = function(coord) {
    return coord.x + coord.y * this.w;
  };

  ChaseGame.prototype._corners = function() {
    return [
      this._index({
        x: 0,
        y: 0
      }), this._index({
        x: 0,
        y: this.h - 1
      }), this._index({
        x: this.w - 1,
        y: 0
      }), this._index({
        x: this.w - 1,
        y: this.h - 1
      })
    ];
  };

  _dirs = {
    0: {
      x: 0,
      y: 1
    },
    1: {
      x: 1,
      y: 0
    },
    2: {
      x: 0,
      y: -1
    },
    3: {
      x: -1,
      y: 0
    }
  };

  ChaseGame.prototype.advance = function(action) {
    var coord, dir, i, newCoord, oldIndex, prize, prizeCoord, _i, _j, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
    dir = _dirs[action];
    coord = null;
    for (i = _i = 0, _ref = this.w * this.h; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      if (this.state.layers[0][i] === 1) {
        coord = this._coord(i);
        break;
      }
    }
    prizeCoord = null;
    for (i = _j = 0, _ref1 = this.w * this.h; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
      if (this.state.layers[2][i] === 1) {
        prizeCoord = this._coord(i);
        break;
      }
    }
    newCoord = {
      x: coord.x + dir.x,
      y: coord.y + dir.y
    };
    if (!((0 <= (_ref2 = newCoord.x) && _ref2 < this.w)) || !((0 <= (_ref3 = newCoord.y) && _ref3 < this.h)) || this.state.layers[1][this._index(newCoord)] === 1) {
      return {
        reward: -1,
        turn: 0
      };
    }
    prize = this.state.layers[2][this._index(newCoord)] === 1;
    oldIndex = this._index(prizeCoord);
    if (prize) {
      prizeCoord.x = this.w - 1;
      prizeCoord.y = this.h - 1;
    } else {
      dir = _dirs[helper._rand(4)];
      prizeCoord.x += dir.x;
      prizeCoord.y += dir.y;
    }
    if ((0 <= (_ref4 = prizeCoord.x) && _ref4 < this.w) && (0 <= (_ref5 = prizeCoord.y) && _ref5 < this.h) && this.state.layers[1][this._index(prizeCoord)] === 0) {
      this.state.layers[2][oldIndex] = 0;
      this.state.layers[2][this._index(prizeCoord)] = 1;
    }
    this.state.layers[0][this._index(coord)] = 0;
    this.state.layers[0][this._index(newCoord)] = 1;
    if (prize) {
      return {
        reward: 10,
        turn: 0
      };
    } else {
      return {
        reward: 0,
        turn: 0
      };
    }
  };

  ChaseGame.prototype.render = function() {
    var i, j, str, _i, _j, _ref, _ref1;
    str = '';
    for (j = _i = 0, _ref = this.h; 0 <= _ref ? _i < _ref : _i > _ref; j = 0 <= _ref ? ++_i : --_i) {
      for (i = _j = 0, _ref1 = this.w; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
        if (this.state.layers[0][j * this.w + i] === 1) {
          str += '@';
        } else if (this.state.layers[1][j * this.w + i] === 1) {
          str += '#';
        } else if (this.state.layers[2][j * this.w + i] === 1) {
          str += 'X';
        } else {
          str += ' ';
        }
      }
      str += '\n';
    }
    return str;
  };

  ChaseGame.prototype.renderCanvas = function(ctx, canvas) {
    var cx, cy, fx, fy, i, x, y, _i, _ref, _results;
    fx = canvas.width / this.w;
    fy = canvas.height / this.h;
    _results = [];
    for (y = _i = 0, _ref = this.h; 0 <= _ref ? _i < _ref : _i > _ref; y = 0 <= _ref ? ++_i : --_i) {
      _results.push((function() {
        var _j, _ref1, _results1;
        _results1 = [];
        for (x = _j = 0, _ref1 = this.w; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; x = 0 <= _ref1 ? ++_j : --_j) {
          cx = x * fx;
          cy = y * fy;
          i = y * this.w + x;
          if (this.state.layers[1][i] === 1) {
            ctx.fillStyle = '#F00';
          } else {
            ctx.fillStyle = '#FFF';
          }
          ctx.fillRect(cx, cy, fx, fy);
          if (this.state.layers[0][i] === 1) {
            ctx.fillStyle = '#000';
            ctx.fillRect(cx + fx / 3, cy + fy / 3, fx / 3, fy / 3);
          }
          if (this.state.layers[2][i] === 1) {
            ctx.fillStyle = '#FF0';
            _results1.push(ctx.fillRect(cx + fx / 3, cy + fy / 3, fx / 3, fy / 3));
          } else {
            _results1.push(void 0);
          }
        }
        return _results1;
      }).call(this));
    }
    return _results;
  };

  return ChaseGame;

})(Game);


},{"../game.coffee":3,"../helper.coffee":9}],6:[function(require,module,exports){

/*
WIGO Dumb game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
 */
var DumbGame, Game, helper,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Game = require('../game.coffee').Game;

helper = require('../helper.coffee');

exports.DumbGame = DumbGame = (function(_super) {
  __extends(DumbGame, _super);

  function DumbGame() {
    DumbGame.__super__.constructor.call(this, 2, 2, 1);
  }

  DumbGame.prototype.advance = function(action) {
    var reward;
    if ((this.state.layers[0][0] > this.state.layers[0][1]) === (action === 0)) {
      reward = 1;
    } else {
      reward = -1;
    }
    this.state.layers[0][0] = helper._randBit();
    this.state.layers[0][1] = 1 - this.state.layers[0][0];
    return {
      reward: reward,
      turn: 0
    };
  };

  DumbGame.prototype.render = function() {
    return "" + this.state.layers[0][0] + "," + this.state.layers[0][1];
  };

  return DumbGame;

})(Game);


},{"../game.coffee":3,"../helper.coffee":9}],7:[function(require,module,exports){

/*
WIGO Dumb game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
 */
var Game, GridGame, PRIZE_SPAWN_PROBABILITY, WALL_DENSITY, helper,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __modulo = function(a, b) { return (a % b + +b) % b; };

Game = require('../game.coffee').Game;

helper = require('../helper.coffee');

PRIZE_SPAWN_PROBABILITY = 0.05;

WALL_DENSITY = 0.2;

exports.GridGame = GridGame = (function(_super) {
  var _dirs;

  __extends(GridGame, _super);

  function GridGame(w, h) {
    var i, _i, _ref;
    this.w = w != null ? w : 5;
    this.h = h != null ? h : 5;
    GridGame.__super__.constructor.call(this, this.w * this.h, 4, 3);
    for (i = _i = 0, _ref = this.w * this.h; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      if (!(__indexOf.call(this._corners(), i) < 0)) {
        continue;
      }
      console.log(i, this._corners());
      if (Math.random() < WALL_DENSITY) {
        this.state.layers[1][i] = 1;
      }
    }
    this.state.layers[0][0] = 1;
    this.state.layers[2][0] = 1;
    this.prizeIndex = 0;
  }

  GridGame.prototype._coord = function(index) {
    return {
      x: index % this.w,
      y: (index - (index % this.w)) / this.w
    };
  };

  GridGame.prototype._index = function(coord) {
    return coord.x + coord.y * this.w;
  };

  GridGame.prototype._corners = function() {
    return [
      this._index({
        x: 0,
        y: 0
      }), this._index({
        x: 0,
        y: this.h - 1
      }), this._index({
        x: this.w - 1,
        y: 0
      }), this._index({
        x: this.w - 1,
        y: this.h - 1
      })
    ];
  };

  _dirs = {
    0: {
      x: 0,
      y: 1
    },
    1: {
      x: 1,
      y: 0
    },
    2: {
      x: 0,
      y: -1
    },
    3: {
      x: -1,
      y: 0
    }
  };

  GridGame.prototype.advance = function(action) {
    var coord, dir, i, newCoord, prize, _i, _ref, _ref1, _ref2;
    dir = _dirs[action];
    coord = null;
    for (i = _i = 0, _ref = this.w * this.h; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      if (this.state.layers[0][i] === 1) {
        coord = this._coord(i);
        break;
      }
    }
    newCoord = {
      x: coord.x + dir.x,
      y: coord.y + dir.y
    };
    if (!((0 <= (_ref1 = newCoord.x) && _ref1 < this.w)) || !((0 <= (_ref2 = newCoord.y) && _ref2 < this.h)) || this.state.layers[1][this._index(newCoord)] === 1) {
      return {
        reward: -1,
        turn: 0
      };
    }
    prize = false;
    if (this.state.layers[2][this._index(newCoord)] === 1) {
      prize = true;
      this.state.layers[2][this._index(newCoord)] = 0;
      this.state.layers[2][this._corners()[__modulo((this.prizeIndex += 1), 4)]] = 1;
    }
    this.state.layers[0][this._index(coord)] = 0;
    this.state.layers[0][this._index(newCoord)] = 1;
    if (prize) {
      return {
        reward: 10,
        turn: 0
      };
    } else {
      return {
        reward: 0,
        turn: 0
      };
    }
  };

  GridGame.prototype.render = function() {
    var i, j, str, _i, _j, _ref, _ref1;
    str = '';
    for (j = _i = 0, _ref = this.h; 0 <= _ref ? _i < _ref : _i > _ref; j = 0 <= _ref ? ++_i : --_i) {
      for (i = _j = 0, _ref1 = this.w; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
        if (this.state.layers[0][j * this.w + i] === 1) {
          str += '@';
        } else if (this.state.layers[1][j * this.w + i] === 1) {
          str += '#';
        } else if (this.state.layers[2][j * this.w + i] === 1) {
          str += '?';
        } else {
          str += ' ';
        }
      }
      str += '\n';
    }
    return str;
  };

  GridGame.prototype.renderCanvas = function(ctx, canvas) {
    var cx, cy, fx, fy, i, x, y, _i, _ref, _results;
    fx = canvas.width / this.w;
    fy = canvas.height / this.h;
    _results = [];
    for (y = _i = 0, _ref = this.h; 0 <= _ref ? _i < _ref : _i > _ref; y = 0 <= _ref ? ++_i : --_i) {
      _results.push((function() {
        var _j, _ref1, _results1;
        _results1 = [];
        for (x = _j = 0, _ref1 = this.w; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; x = 0 <= _ref1 ? ++_j : --_j) {
          cx = x * fx;
          cy = y * fy;
          i = y * this.w + x;
          if (this.state.layers[1][i] === 1) {
            ctx.fillStyle = '#F00';
          } else {
            ctx.fillStyle = '#DEB877';
          }
          ctx.fillRect(cx, cy, fx, fy);
          if (this.state.layers[0][i] === 1) {
            ctx.fillStyle = '#000';
            ctx.fillRect(cx + fx / 3, cy + fy / 3, fx / 3, fy / 3);
          }
          if (this.state.layers[2][i] === 1) {
            ctx.fillStyle = '#FF0';
            _results1.push(ctx.fillRect(cx + fx / 3, cy + fy / 3, fx / 3, fy / 3));
          } else {
            _results1.push(void 0);
          }
        }
        return _results1;
      }).call(this));
    }
    return _results;
  };

  return GridGame;

})(Game);


},{"../game.coffee":3,"../helper.coffee":9}],8:[function(require,module,exports){

/*
WIGO Dumb game
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
 */
var Game, PRIZE_SPAWN_PROBABILITY, PathGame, WALL_DENSITY, helper,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Game = require('../game.coffee').Game;

helper = require('../helper.coffee');

PRIZE_SPAWN_PROBABILITY = 0.05;

WALL_DENSITY = 1;

exports.PathGame = PathGame = (function(_super) {
  var _dirs;

  __extends(PathGame, _super);

  function PathGame(w, h) {
    this.w = w != null ? w : 5;
    this.h = h != null ? h : 5;
    PathGame.__super__.constructor.call(this, this.w * this.h, 4, 3);
    this.buildMap();
    this.reset();
  }

  PathGame.prototype.playerReplace = function() {
    var i, _i, _ref;
    for (i = _i = 0, _ref = this.w * this.h; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      this.state.layers[0][i] = 0;
    }
    return this.state.layers[0][0] = 1;
  };

  PathGame.prototype.reset = function() {
    this.timeSinceReset = 0;
    this.buildMap();
    return this.playerReplace();
  };

  PathGame.prototype.buildMap = function() {
    var digger, dir, i, _i, _j, _ref, _ref1, _ref2, _ref3, _results;
    this.state.eachBit((function(_this) {
      return function(i, j) {
        return _this.state.layers[i][j] = 0;
      };
    })(this));
    for (i = _i = 0, _ref = this.w * this.h; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      if (__indexOf.call(this._corners(), i) < 0) {
        if (Math.random() < WALL_DENSITY) {
          this.state.layers[1][i] = 1;
        }
      }
    }
    digger = {
      x: 0,
      y: 0
    };
    while (!(digger.x === this.w - 1 && digger.y === this.h - 1)) {
      dir = _dirs[helper._rand(2)];
      digger.x += dir.x;
      digger.y += dir.y;
      if ((0 <= (_ref1 = digger.x) && _ref1 < this.w) && (0 <= (_ref2 = digger.y) && _ref2 < this.h)) {
        this.state.layers[1][this._index(digger)] = 0;
      } else {
        digger.x -= dir.x;
        digger.y -= dir.y;
      }
    }
    this.state.layers[1][this._index(digger)] = 0;
    _results = [];
    for (i = _j = 0, _ref3 = this.w * this.h; 0 <= _ref3 ? _j < _ref3 : _j > _ref3; i = 0 <= _ref3 ? ++_j : --_j) {
      if (this.state.layers[1][i] === 0) {
        _results.push(this.state.layers[2][i] = 1);
      }
    }
    return _results;
  };

  PathGame.prototype._coord = function(index) {
    return {
      x: index % this.w,
      y: (index - (index % this.w)) / this.w
    };
  };

  PathGame.prototype._index = function(coord) {
    return coord.x + coord.y * this.w;
  };

  PathGame.prototype._corners = function() {
    return [
      this._index({
        x: 0,
        y: 0
      }), this._index({
        x: 0,
        y: this.h - 1
      }), this._index({
        x: this.w - 1,
        y: 0
      }), this._index({
        x: this.w - 1,
        y: this.h - 1
      })
    ];
  };

  _dirs = {
    0: {
      x: 0,
      y: 1
    },
    1: {
      x: 1,
      y: 0
    },
    2: {
      x: 0,
      y: -1
    },
    3: {
      x: -1,
      y: 0
    }
  };

  PathGame.prototype.advance = function(action) {
    var coord, dir, finish, i, newCoord, prize, _i, _ref, _ref1, _ref2;
    this.timeSinceReset++;
    dir = _dirs[action];
    coord = null;
    for (i = _i = 0, _ref = this.w * this.h; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      if (this.state.layers[0][i] === 1) {
        coord = this._coord(i);
        break;
      }
    }
    newCoord = {
      x: coord.x + dir.x,
      y: coord.y + dir.y
    };
    if (!((0 <= (_ref1 = newCoord.x) && _ref1 < this.w)) || !((0 <= (_ref2 = newCoord.y) && _ref2 < this.h))) {
      this.playerReplace();
      return {
        reward: -1,
        turn: 0
      };
    }
    this.state.layers[0][this._index(coord)] = 0;
    this.state.layers[0][this._index(newCoord)] = 1;
    prize = false;
    finish = false;
    if (this.state.layers[2][this._index(newCoord)] === 1) {
      prize = true;
      this.state.layers[2][this._index(newCoord)] = 0;
    }
    if (newCoord.x === this.w - 1 && newCoord.y === this.h - 1) {
      finish = true;
      this.reset();
    }
    if (this.timeSinceReset > 300) {
      this.reset();
      return {
        reward: -5,
        turn: 0
      };
    }
    if (finish) {
      return {
        reward: 50,
        turn: 0
      };
    } else if (prize) {
      return {
        reward: 10,
        turn: 0
      };
    } else if (this.state.layers[1][this._index(newCoord)] === 1) {
      this.playerReplace();
      return {
        reward: -1,
        turn: 0
      };
    } else {
      return {
        reward: 0,
        turn: 0
      };
    }
  };

  PathGame.prototype.render = function() {
    var i, j, str, _i, _j, _ref, _ref1;
    str = '';
    for (j = _i = 0, _ref = this.h; 0 <= _ref ? _i < _ref : _i > _ref; j = 0 <= _ref ? ++_i : --_i) {
      for (i = _j = 0, _ref1 = this.w; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
        if (this.state.layers[0][j * this.w + i] === 1) {
          str += '@';
        } else if (this.state.layers[1][j * this.w + i] === 1) {
          str += '~';
        } else {
          str += ' ';
        }
      }
      str += '\n';
    }
    return str;
  };

  PathGame.prototype.renderCanvas = function(ctx, canvas) {
    var cx, cy, fx, fy, i, x, y, _i, _ref, _results;
    fx = canvas.width / this.w;
    fy = canvas.height / this.h;
    _results = [];
    for (y = _i = 0, _ref = this.h; 0 <= _ref ? _i < _ref : _i > _ref; y = 0 <= _ref ? ++_i : --_i) {
      _results.push((function() {
        var _j, _ref1, _results1;
        _results1 = [];
        for (x = _j = 0, _ref1 = this.w; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; x = 0 <= _ref1 ? ++_j : --_j) {
          cx = x * fx;
          cy = y * fy;
          i = y * this.w + x;
          if (this.state.layers[1][i] === 1) {
            ctx.fillStyle = '#F00';
          } else if (this.state.layers[2][i] === 1) {
            ctx.fillStyle = '#FF0';
          } else {
            ctx.fillStyle = '#DEB877';
          }
          ctx.fillRect(cx, cy, fx, fy);
          if (this.state.layers[0][i] === 1) {
            ctx.fillStyle = '#000';
            _results1.push(ctx.fillRect(cx + fx / 3, cy + fy / 3, fx / 3, fy / 3));
          } else {
            _results1.push(void 0);
          }
        }
        return _results1;
      }).call(this));
    }
    return _results;
  };

  return PathGame;

})(Game);


},{"../game.coffee":3,"../helper.coffee":9}],9:[function(require,module,exports){

/*
WIGO helper functions.
Public domain.
 */
var _pow, _rand, _randBit, _sum;

exports._rand = _rand = function(x) {
  if (typeof x === 'number') {
    return Math.floor(Math.random() * x);
  } else if ('length' in x) {
    return x[_rand(x.length)];
  }
};

exports._randBit = _randBit = function() {
  if (Math.random() < 0.5) {
    return 1;
  } else {
    return 0;
  }
};

exports._pow = _pow = function(x) {
  return Math.pow(Math.E, x);
};

exports._sum = _sum = function(list) {
  var s, x, _i, _len;
  s = 0;
  for (_i = 0, _len = list.length; _i < _len; _i++) {
    x = list[_i];
    s += x;
  }
  return s;
};

exports._weightedRandom = function(list) {
  var barrier, el, i, point, _i, _len;
  barrier = Math.random() * _sum(list);
  point = 0;
  for (i = _i = 0, _len = list.length; _i < _len; i = ++_i) {
    el = list[i];
    point += el;
    if (point > barrier) {
      return i;
    }
  }
  return list.length;
};


},{}],10:[function(require,module,exports){

/*
WIGO Q-Learning/SARSA-Learning implementation
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
 */
var QLearner, Regressor, helper;

helper = require('./helper.coffee');

Regressor = require('./regressor.coffee').Regressor;

exports.QLearner = QLearner = (function() {
  function QLearner(actions, bases, opts) {
    var _ref, _ref1, _ref2, _ref3, _ref4;
    this.actions = actions;
    this.bases = bases;
    this.opts = opts;
    opts = this.opts;
    this.rate = (_ref = opts.rate) != null ? _ref : 1;
    this.discount = (_ref1 = opts.discount) != null ? _ref1 : 0.5;
    this.forwardMode = (_ref2 = opts.forwardMode) != null ? _ref2 : 'epsilonGreedy';
    this.epsilon = (_ref3 = opts.epsilon) != null ? _ref3 : 0.1;
    this.temperature = (_ref4 = opts.temperature) != null ? _ref4 : 1;
    this.bases.unshift((function() {
      return 1;
    }));
    this.rate /= this.bases.length;
    this.regressors = (function() {
      var _i, _ref5, _results;
      _results = [];
      for (_i = 0, _ref5 = this.actions; 0 <= _ref5 ? _i < _ref5 : _i > _ref5; 0 <= _ref5 ? _i++ : _i--) {
        _results.push(new Regressor(this.bases, this.rate));
      }
      return _results;
    }).call(this);
  }

  QLearner.prototype.estimate = function(state, action) {
    return this.regressors[action].estimate(state);
  };

  QLearner.prototype.max = function(state) {
    var action, best, estimate, max, _i, _ref;
    best = null;
    max = -Infinity;
    for (action = _i = 0, _ref = this.actions; 0 <= _ref ? _i < _ref : _i > _ref; action = 0 <= _ref ? ++_i : --_i) {
      estimate = this.estimate(state, action);
      if (estimate > max) {
        max = estimate;
        best = [action];
      } else if (estimate === max) {
        best.push(action);
      }
    }
    return {
      action: helper._rand(best),
      estimate: max
    };
  };

  QLearner.prototype.softmax = function(state) {
    var action, weights;
    weights = (function() {
      var _i, _ref, _results;
      _results = [];
      for (action = _i = 0, _ref = this.actions; 0 <= _ref ? _i < _ref : _i > _ref; action = 0 <= _ref ? ++_i : --_i) {
        _results.push(helper._pow(this.estimate(state, action) / this.temperature));
      }
      return _results;
    }).call(this);
    action = helper._weightedRandom(weights);
    return {
      action: action,
      estimate: this.estimate(state, action)
    };
  };

  QLearner.prototype.epsilonGreedy = function(state) {
    var action;
    if (Math.random() < this.epsilon) {
      return {
        action: action = helper._rand(this.actions),
        estimate: this.estimate(state, action)
      };
    } else {
      return this.max(state);
    }
  };

  QLearner.prototype.forward = function(state) {
    if (this.forwardMode === 'softmax') {
      return this.softmax(state);
    } else {
      return this.epsilonGreedy(state);
    }
  };

  QLearner.prototype.backward = function(state, action, newState, reward) {
    return this.regressors[action].feed(state, reward + (newState != null ? this.discount * this.forward(newState).estimate : 0));
  };

  QLearner.prototype.serialize = function() {
    var regressor;
    return {
      regressors: (function() {
        var _i, _len, _ref, _results;
        _ref = this.regressors;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          regressor = _ref[_i];
          _results.push(regressor.serialize());
        }
        return _results;
      }).call(this),
      opts: this.opts
    };
  };

  return QLearner;

})();

QLearner.fromSerialized = function(action, bases, serialization) {
  var i, k, learner, _i, _len;
  learner = new QLearner(action, bases, serialization.opts);
  for (i = _i = 0, _len = serialization.length; _i < _len; i = ++_i) {
    k = serialization[i];
    learner.regressors[i] = Regressor.fromSerialized(k);
  }
  return learner;
};


},{"./helper.coffee":9,"./regressor.coffee":11}],11:[function(require,module,exports){

/*
WIGO stochastic regularized gradient descent linear regression implementation
Copyright (c) 2014 Anthony Bau, Weihang Fan, Calvin Luo, and Steven Price
MIT License.
 */
var Regressor;

exports.Regressor = Regressor = (function() {
  function Regressor(bases, rate, lambda) {
    var basis;
    this.bases = bases;
    this.rate = rate != null ? rate : 0.1;
    this.lambda = lambda != null ? lambda : 0.1;
    this.thetas = (function() {
      var _i, _len, _ref, _results;
      _ref = this.bases;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        basis = _ref[_i];
        _results.push(0);
      }
      return _results;
    }).call(this);
  }

  Regressor.prototype.estimate = function(input) {
    var basis, i, output, _i, _len, _ref;
    output = 0;
    _ref = this.bases;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      basis = _ref[i];
      output += this.thetas[i] * basis(input);
    }
    return output;
  };

  Regressor.prototype.feed = function(input, output) {
    var basis, gradient, i, _i, _len, _ref, _results;
    gradient = this.estimate(input) - output;
    _ref = this.bases;
    _results = [];
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      basis = _ref[i];
      _results.push(this.thetas[i] -= this.rate * (gradient + this.lambda * this.thetas[i] / this.thetas.length) * basis(input));
    }
    return _results;
  };

  Regressor.prototype.serialize = function() {
    return {
      thetas: this.thetas,
      rate: this.rate,
      lambda: this.lambda
    };
  };

  return Regressor;

})();

Regressor.fromSerialized = function(bases, serialized) {
  var k;
  k = new Regressor(bases, serialized.rate, serialized.lambda);
  k.thetas = serialized.thetas;
  return k;
};


},{}]},{},[2])(2)
});