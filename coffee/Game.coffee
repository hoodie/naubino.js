# controlls everything that has to do with logic and gameplay or menus
# @extends Layer
define ["Layer", "Naub", "Graph", "Shapes"], (Layer, Naub, Graph, { Ball, Square, Frame, FrameCircle, Clock, NumberShape, StringShape, PlayButton, PauseButton }) -> class Game extends Layer

  # get this started
  constructor: (canvas) ->
    super(canvas)
    @name = "game"
    @graph = new Graph(this)
    @animation.name = "game.animation"

    # display stuff
    @drawing = true # for debugging
    @focused_naub = null # points to the naub you click on
    @gravity = Naubino.settings.physics.gravity.game

    #@points = -1
    @joining_allowed = yes
    console.log "mousemove"
    Naubino.mousemove.add @move_pointer
    Naubino.mousedown.add @click
    Naubino.mouseup.add @unfocus

    
    # gameplay
    @naub_replaced   = new Naubino.Signal()
    @naub_joined     = new Naubino.Signal()
    @naub_destroyed  = new Naubino.Signal()
    @cycle_found     = new Naubino.Signal()
    @naub_focused    = new Naubino.Signal()
    @naub_unfocused  = new Naubino.Signal()

    #state machine
    StateMachine.create {
      target: this
      #error:(event,from,to,args,ec,em) -> console.warn "#{event}(#{args}): #{from}->#{to} - #{ec}:\"#{em}\"" unless event is 'click'
      events: Naubino.settings.events
    }


  #default state change actions
  onplaying: ->
    @animation.play()
    @start_stepper()

  onleaveplaying: (e,f,t) -> @stop_stepper()
  onpaused: (e,f,t) -> @animation.pause()
  onstopped: (e,f,t) ->

  # the game gives it the game takes it
  
  # methods that create naubs
  #
  # @param [int] n number of pairs or triples
  create_some_naubs: (n = 1) ->
    for [1..n]
      @create_naub_pair()
      @create_naub_triple()


  #create n sets of matching pairs and some leftovers
  #
  # @param n [int] number of matching pairs
  # @param extras [int] number of leftovers
  create_matching_naubs: (n=1,extras=0) ->
    for [1..n]
      colors = Util.shuffle [0..5]
      colors[5] = colors[0]
      i = 0
      while i < (colors.length )-1
        {x,y} = @random_outside()
        #Naubino.background.draw_marker(x,y)
        [a,b] = @create_naub_pair(x,y,colors[i],colors[i+1])
        #console.log "pairing " + [a,b]
        i++

    #create some extras
    if extras > 0
      for [1..extras]
        {x,y} = @random_outside()
        #Naubino.background.draw_marker(x,y)
        @create_naub_pair(x,y)


  # create a pair of joined naubs
  #
  # @default
  # @param x [int] x-ordinate
  # @param y [int] y-ordinate
  # @param color [int] color id of naub 1
  # @param color [int] color id of naub 2
  # IMPLICIT if game has a @max_colors int random colors will only be picked out range [1..@max_colors]
  create_naub_pair: (x=null, y=x, color_a = null, color_b = null) =>

    {x,y} = @random_outside() unless x?

    naub_a = new Naub this, color_a
    naub_b = new Naub this, color_b
    color_a = naub_a.color_id
    color_b = naub_b.color_id

    naub_a.add_shape new Ball
    naub_b.add_shape new Ball

    color_a = naub_a.color_id
    color_b = naub_b.color_id

    @add_object naub_a
    @add_object naub_b

    naub_a.update() # again just to get the numbers
    naub_b.update() # again just to get the numbers

    dir = Math.random() * Math.PI

    naub_a.physics.pos.Set x, y
    naub_b.physics.pos.Set x, y

    naub_a.physics.pos.AddPolar(dir, 15)
    naub_b.physics.pos.AddPolar(dir, -15)

    naub_a.join_with naub_b
    [color_a, color_b]

  # create a triple of joined naubs
  #
  # works almost like create_naub_pair
  # @param x [int] x-ordinate
  # @param y [int] y-ordinate
  create_naub_triple: (x=null, y=x, color_a = null, color_b = null, color_c = null) =>
    {x,y} = @random_outside() unless x?
    naub_a = new Naub this, color_a
    naub_b = new Naub this, color_b
    naub_c = new Naub this, color_c

    naub_a.add_shape new Ball
    naub_b.add_shape new Ball
    naub_c.add_shape new Ball

    @add_object naub_a
    @add_object naub_b
    @add_object naub_c

    naub_a.update() # again just to get the numbers
    naub_b.update() # again just to get the numbers
    naub_c.update() # again just to get the numbers

    dir = Math.random() * Math.PI

    naub_a.physics.pos.Set x, y
    naub_b.physics.pos.Set x, y
    naub_c.physics.pos.Set x, y

    naub_a.physics.pos.AddPolar(dir, 30)
    naub_c.physics.pos.AddPolar(dir, -30)

    naub_a.join_with naub_b
    naub_b.join_with naub_c


  # produces a random set of coordinates outside the field
  random_outside: ->
    offset = 100
    seed = Math.round (Math.random() * 3)+1
    switch seed
      when 1
        x = @width + offset
        y = @height * Math.random()
      when 2
        x = @width  * Math.random()
        y = @height + offset
      when 3
        x = 0 - offset
        y = @height * Math.random()
      when 4
        x = @width * Math.random()
        y = 0 - offset
    {x,y}

  # counts howmany naubs would be inside the circle
  # important for gameplay
  count_basket: ->
    count = []
    if @basket_size?
      for id, naub of @objects
        diff = @center.Copy()
        diff.Subtract naub.physics.pos
        if diff.Length() < @basket_size - naub.size/2
          count.push naub
    count


  # shows how much room is available in the basket
  capacity: ->
    r = @basket_size
    size= Math.ceil r * r * Math.PI * 0.75 # don't ask me why
    filling =0
    for naub in @count_basket()
      filling += naub.area()
    100-Math.ceil(filling*100 / size)

  # destroys every naub in a list of IDs by calling its own destroy function
  destroy_naubs: (list)->
    for naub in list
      @get_object(naub).disable()

    i = 0
    one_after_another= =>
      if i < list.length
        @get_object(list[i]).destroy()
        i++
      setTimeout one_after_another, 40
    one_after_another()


  # is one naub allowed to join with another
  check_joining: (naub, other) ->
    return no if naub.number == other.number or not @joining_allowed

    naub_partners = (partner.number for id, partner of naub.joins)
    other_partners = (partner.number for id, partner of other.joins)
    close_related = naub_partners.some (x) -> x in other_partners # "some" is standard js and means "filter"

    joined = naub.is_joined_with other
    alone = Object.keys(naub.joins).length == 0
    other_alone = Object.keys(other.joins).length == 0
    same_color = naub.color_id == other.color_id

    if !naub.disabled && not joined && same_color && not close_related && not alone && not other_alone
      other.replace_with naub
      return yes
    else if alone and not (other.disabled or naub.disabled)
      naub.join_with other
      return yes
    no

  # draws everything that happens inside the field
  draw:  ->
    # clears the canvas before drawing
    @ctx.clearRect(0, 0, Naubino.settings.canvas.width, Naubino.settings.canvas.height)
    # draws joins and naubs seperately
    @ctx.save()
    for id, obj of @objects
      obj.draw_joins @ctx

    for id, obj of @objects
      obj.draw @ctx
    @ctx.restore()



  # clears the graph as well, just in case
  clear_objects: ->
    super()
    @graph.clear()


  # run naub_forces, check for joinings and clean up
  step: (dt) ->
    @chip_step()
    
    @naub_forces dt

    # check for joinings
    if @mousedown && @focused_naub
      @focused_naub.physics.follow @pointer.Copy()
      for id, other of  @objects
        if (@focused_naub.distance_to other) < (@focused_naub.size+Naubino.settings.naub.fondness)
          @check_joining(@focused_naub,other)
          break

    # delete objects
    for id, obj of @objects
      if obj.removed
        @remove_obj id
        return 42 # TODO found out if there is a way to have a void function?




  # moves naubs on every step
  #
  # @param [float] time-difference determines step size
  naub_forces: (dt) ->
    for id, naub of @objects

      # everything moves toward the middle
      naub.physics.gravitate(dt)

      # joined naubs have spring forces
      for id, other of naub.joins
        naub.physics.join_springs other

      # collide
      for [0..3]
        for id, other of @objects
          naub.physics.collide other

      # use all previously calculated forces and actually move the damn thing
      naub.step(dt)

