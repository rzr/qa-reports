# Stuff moved away from old huge application.js that is needed
# in more than one place. We are not using modules, and Sprocket
# will create the closure wrapper so we need to put these in global
# scope

@activateSuggestionLinks = (target) ->
  $(target).find(".suggestions a").on 'click', (e) ->
    e.preventDefault()
    $a = $(this)
    $a.parent().prevAll('input').val $a.text()

# TODO: Move to a separate file
$ = jQuery
$.fn.autogrow = (options) ->
  this.filter('textarea').each ->
    $this      = $(this)
    minHeight  = $this.height()
    lineHeight = $this.css('lineHeight')

    shadow = $('<div></div>').css
      position:   'absolute'
      top:        -10000
      left:       -10000
      width:      $(this).width() - parseInt($this.css('paddingLeft')) - parseInt($this.css('paddingRight'))
      fontSize:   $this.css('fontSize')
      fontFamily: $this.css('fontFamily')
      lineHeight: $this.css('lineHeight')
      resize:     'none'
    .appendTo(document.body)

    update = ->
      times = (string, number) ->
        _res = ''
        _res = _res + string for i in [1..number]
        _res

      val = this.value.replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/&/g, '&amp;')
        .replace(/\n$/, '<br/>&nbsp;')
        .replace(/\n/g, '<br/>')
        .replace(/[ ]{2,}/g, (space) -> times('&nbsp;', space.length - 1) + ' ')

      shadow.html(val);
      $(this).css('height', Math.max(shadow.height() + 20, minHeight))

    $(this).change(update).keyup(update).keydown(update)
    update.apply(this)

  this
