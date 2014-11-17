_max = (arr) ->
  top = -Infinity
  top = Math.max(top, el) for el, i in arr
  return top

exports.RollingGraph = class RollingGraph
  constructor: (@canvas, @len, @channels = 2) ->
    @ctx = @canvas.getContext '2d'
    @buffers = (new Float64Array(@len) for [0...@channels])
    @indices = (0 for [0...@channels])
    @maximums = (0 for [0...@channels])
    @colors = ['#00F', '#0FF', '#F0F', '#F00', '#FF0', '#0F0']
    @listening = true

  index: -> _max(@indices)

  feed: (data, channel = 0) ->
    @buffers[channel][@indices[channel] %% @len] = data
    @maximums[channel] = Math.max data, @maximums[channel]
    @indices[channel]++
    @render()

  render: ->
    @ctx.clearRect 0, 0, @canvas.width, @canvas.height

    index = @index()
    for buffer, channel in @buffers
      @ctx.strokeStyle = @colors[channel]
      @ctx.beginPath()
      @ctx.moveTo 0, @canvas.height
      for el, i in buffer when i + index < @indices[channel] + @len
        el = buffer[(i + index) %% @len]
        @ctx.lineTo @canvas.width * i / @len, @canvas.height * (1 - el / @maximums[channel])

      @ctx.stroke()
