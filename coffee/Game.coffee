# controlls everything that has to do with logic and gameplay or menus
class Naubino.Game extends Naubino.Layer
  
  ###
  * get this started 
  ###
  constructor: (canvas, @graph) ->
    super(canvas)
    @name = "game"

    # display stuff
    @paused = true # changed imidiately after loading by start_timer
    @drawing = true # for debugging
    @focused_naub = null # points to the naub you click on
    @gravity = Naubino.Settings.gravity.game

    @points = -1
    @joining_allowed = yes
    Naubino.mousemove.add @move_pointer
    Naubino.mousedown.add @click
    Naubino.mouseup.add @unfocus

  ###
  state machine stuff
  ###


  ### 
  the game gives it the game takes it
  methods that create naubs
  ###
  create_some_naubs: (n = 3) ->
    for [1..n]
      {x,y} = @random_outside()
      #Naubino.background.draw_marker(x,y)
      @create_naub_pair(x,y)
    for [1..n]
      {x,y} = @random_outside()
      #Naubino.background.draw_marker(x,y)
      @create_naub_triple(x,y)


  create_matching_naubs: (n=1,extras=0) ->
    #create n sets of matching pairs
    for [1..n]
      colors = _.shuffle [0..5]
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


  create_naub: (x = @center.x, y = @center.y) ->
      naub_a = new Naubino.Naub this
      @add_object naub_a
      naub_a.shape.pre_render() # again just to get the numbers
      naub_a.physics.pos.Set x, y


  create_naub_pair: (x, y, color_a = null, color_b = null) ->
      naub_a = new Naubino.Naub this, color_a
      naub_b = new Naubino.Naub this, color_b
      color_a = naub_a.color_id
      color_b = naub_b.color_id

      @add_object naub_a
      @add_object naub_b
      naub_a.shape.pre_render() # again just to get the numbers
      naub_b.shape.pre_render() # again just to get the numbers

      dir = Math.random() * Math.PI

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x, y

      naub_a.physics.pos.AddPolar(dir, 15)
      naub_b.physics.pos.AddPolar(dir, -15)

      naub_a.join_with naub_b
      [color_a, color_b]


  create_naub_triple: (x, y) ->
      naub_a = new Naubino.Naub this
      naub_b = new Naubino.Naub this
      naub_c = new Naubino.Naub this

      @add_object naub_a
      @add_object naub_b
      @add_object naub_c
      naub_a.shape.pre_render() # again just to get the numbers
      naub_b.shape.pre_render() # again just to get the numbers
      naub_c.shape.pre_render() # again just to get the numbers

      dir = Math.random() * Math.PI

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x, y
      naub_c.physics.pos.Set x, y

      naub_a.physics.pos.AddPolar(dir, 30)
      naub_c.physics.pos.AddPolar(dir, -30)

      naub_a.join_with naub_b
      naub_b.join_with naub_c

  ###
  makes every naub show its own id
  ###
  toggle_numbers: () ->
    unless @show_numbers?
      @show_numbers = true
    else @show_numbers = not @show_numbers
    for id, naub of @objects
      naub.content = if @show_numbers then naub.shape.draw_number else null
      naub.shape.pre_render()



  ###
  produces a random set of coordinates outside the field
  ###
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

  ###
  counts howmany naubs would be inside the circle
  important for gameplay
  TODO: need a function that determines how many actually fit inside the 'basket'
  ###
  count_basket: ->
    count = []
    if @basket_size?
      for id, naub of @objects
        diff = @center.Copy()
        diff.Subtract naub.physics.pos
        if diff.Length() < @basket_size - naub.size/2
          count.push naub.number
    count


  ###
  destroys every naub in a list of IDs by calling its own destroy function
  TODO: need a start id, so the animation starts at a specific point
  ###
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
    allowed = no
    unless naub.number == other.number or not @joining_allowed
      #console.log "checking #{@number}(#{@color_id}) and #{other.number}(#{other.color_id})"

      close_related = false
      naub_partners = for id, partner of naub.joins
        partner.number

      for id, partner of other.joins
        if partner.number in naub_partners
          close_related = true

      joined = naub.is_joined_with other
      alone = _.keys(naub.joins).length == 0
      other_alone = _.keys(other.joins).length == 0
      same_color = naub.color_id == other.color_id

      if !naub.disabled && not joined && same_color && not close_related && not alone && not other_alone
        other.replace_with naub
        allowed = yes
      else if alone and not (other.disabled or naub.disabled)
        naub.join_with other
        allowed = yes
    allowed

    


  ###
  draws everything that happens inside the field
  ###
  draw:  ->
    # clears the canvas before drawing
    @ctx.clearRect(0, 0, Naubino.game_canvas.width, Naubino.game_canvas.height)
    # draws joins and naubs seperately
    @ctx.save()
    for id, obj of @objects
      obj.draw_joins @ctx

    for id, obj of @objects
      obj.draw @ctx
    @ctx.restore()
      


  ###
  clears the graph as well, just in case
  ###
  clear: ->
    super()
    Naubino.graph.clear()


  # work and have everybody else do their work as well
  step: (dt) ->
    # physics
    @naub_forces dt
    
    # check for joinings
    if @mousedown && @focused_naub
      @focused_naub.physics.follow @pointer.Copy()
      for id, other of  @objects
        if (@focused_naub.distance_to other) < (@focused_naub.size+10)
          @check_joining(@focused_naub,other)
          break

    # delete objects
    for id, obj of @objects
      if obj.removed
        @remove_obj id
        return 42 # TODO found out if there is a way to have a void function?




  ###
  moves naubs with every step
  ###
  naub_forces: (dt) ->
    for id, naub of @objects

      # everything moves toward the middle
      naub.physics.gravitate()

      # joined naubs have spring forces 
      for id, other of naub.joins
        naub.physics.join_springs other
      
      # collide
      for [0..3]
        for id, other of @objects
          naub.physics.collide other
      
      # use all previously calculated forces and actually move the damn thing 
      naub.step(dt)

