console.time("loading")

#requirejs.config {
#  baseUrl: 'js/'
#  paths:
#      lib: '../../lib'
#}

define ["Naubino"], (Naubino) ->
  window.onload = ->
    naubino = window.Naubino = new Naubino()
    naubino.setup()



    #populate color selector
    for name, colors of naubino.settings.colors
      $('select#colors').append("<option value=\"#{name}\">#{name}</option>")

    $('select#colors option').each (index,option) ->
      if option.value == naubino.settings.color
        option.selected = true

    $('select#colors').change ->
      naubino.settings.color = this.value

      if this.value == 'high_contrast'
        naubino.settings.graphics.draw_borders_old = naubino.settings.graphics.draw_borders
        naubino.settings.graphics.draw_borders = true
      else if naubino.settings.graphics.draw_borders_old?
        naubino.settings.graphics.draw_borders = naubino.settings.graphics.draw_borders_old


      naubino.menu.for_each (naub) -> naub.recolor()
      naubino.game.for_each (naub) -> naub.recolor()
      naubino.game.draw()





    # https://developer.mozilla.org/en/DOM/Using_full-screen_mode
    @requestFullscreen = ->
      docElm = document.documentElement

      if (docElm.requestFullscreen?)
        docElm.requestFullscreen()
      else if (docElm.mozRequestFullScreen?)
        docElm.mozRequestFullScreen()
      else if (docElm.oRequestFullScreen?)
        docElm.oRequestFullScreen()
      else if (docElm.webkitRequestFullScreen?)
        docElm.webkitRequestFullScreen()

    @exitFullscreen = ->
      if (document.exitFullscreen)
        document.exitFullscreen()

      else if (document.mozCancelFullScreen)
        document.mozCancelFullScreen()

      else if (document.webkitCancelFullScreen)
        document.webkitCancelFullScreen()

    window.onresize = =>
      if $('#maximizeCheck').attr('checked')
        clearTimeout window.resizetimeout if window.resizetimeout?
        window.resizetimeout = setTimeout (
          ->
            naubino.remaximize()
        ) , 1000


    @toggleMaximized= ->
      if $('#maximizeCheck').attr('checked')
        naubino.maximize()
      else
        naubino.demaximize()


    @togglePrerendering = ->
      naubino.settings.graphics.updating =
        if $('#prerenderingCheck').attr('checked')
          off
        else
          on


    @toggleFullscreen = ->
      if $('#fullScreenCheck').attr('checked')
        @requestFullscreen()
      else
        @exitFullscreen()

    @changeFullscreen = (fullScreen) ->
      if fullScreen or (document.fullscreen) or (document.mozFullScreen) or (document.webkitIsFullScreen)
        window.Naubino.maximize()
      else
        window.Naubino.demaximize()


    document.addEventListener("fullscreenchange",       ( => @changeFullscreen (document.fullscreen)         ), false)
    document.addEventListener("mozfullscreenchange",    ( => @changeFullscreen (document.mozFullScreen)      ), false)
    document.addEventListener("webkitfullscreenchange", ( => @changeFullscreen (document.webkitIsFullScreen) ), false)



