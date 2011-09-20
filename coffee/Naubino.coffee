require 'lib/jquery-1.6.3.min.js'
require 'lib/underscore/underscore.js'
require 'lib/signals/signals.min.js'
require 'lib/state-machine/state-machine.min.js'
require 'lib/b2Vec2.js'
require 'js/Settings.js'
require 'js/GameModes.js' # TODO rename modes to states
require 'js/Keybindings.js'
require 'js/Naub.js'
require 'js/Shape.js'
require 'js/Ball.js'
require 'js/PhysicsModel.js'
require 'js/Layer.js'
require 'js/Menu.js'
require 'js/Game.js'
require 'js/Graph.js'

window.onload = ->
  window.naubino = Naubino.constructor()

@Naubino = {
  constructor: () ->

    @overlay_canvas = document.getElementById("overlay_canvas")
    @world_canvas = document.getElementById("world_canvas")
    @background_canvas = document.getElementById("background_canvas")

    @setup_keybindings()
    @setup_cursorbindings()
    @colors = @Settings.colors.output

    @graph = new @Graph()

    @background = new Naubino.Background(@background_canvas)
    @game = new @Game(@world_canvas, @graph)
    @menu = new @Menu(@overlay_canvas)

    @game.create_some_naubs(6)

  setup_keybindings: () ->
    @keybindings = new @KeyBindings()
    window.onkeydown = (key) => @keybindings.keydown(key)
    window.onkeyup = (key) => @keybindings.keyup(key)
    @keybindings.enable 32, => @game.pause()


  setup_cursorbindings: () ->
    # TODO mouse events must go solely through mode
    onmousemove = (e) =>
      #@state.mousemove.dispatch(e)
      @menu.move_pointer e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop
      @game.move_pointer e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop

    onmouseup = (e) =>
      #@state.mouseup.dispatch(e)
      @game.unfocus e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop

    onmousedown = (e) =>
      #@state.mousedown.dispatch(e)
      @menu.click e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop
      @game.click e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop

    @overlay_canvas.addEventListener("mousedown", onmousedown, false)
    @overlay_canvas.addEventListener("mouseup", onmouseup, false)
    @overlay_canvas.addEventListener("mousemove", onmousemove, false)
    @overlay_canvas.addEventListener("mouseout", onmouseup, false)

    @overlay_canvas.addEventListener("touchstart", onmousedown, false)
    @overlay_canvas.addEventListener("touchend", onmouseup, false)
    @overlay_canvas.addEventListener("touchmove", onmousemove, false)
}
