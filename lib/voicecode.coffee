net = require("net")
fs = require("fs")
socketPath = "/tmp/voicecode-atom.sock"

{Point} = require 'atom'
{View, TextEditorView} = require 'atom-space-pen-views'
$ = require 'jquery'

Transformer = require './transformer'

Voicecode =
  subscriptions: null

  activate: (state) ->
    atom.commands.add 'atom-workspace', 'voicecode:connect': => @connect()
    atom.commands.add 'atom-workspace', 'voicecode:select-next-word': => @selectNextWord()

    @connect()
    window.addEventListener('focus', @connect.bind(@), true)

  deactivate: ->
  serialize: ->

  connect: ->
    console.log "connecting to voicecode"
    fs.stat socketPath, (err) =>
      if !err
        fs.unlinkSync socketPath

      unixServer = net.createServer (localSerialConnection) =>
        localSerialConnection.on 'data', (data) =>
          @commandRecieved(data)

      unixServer.listen socketPath

  trigger: (command) ->
    atom.views.getView(atom.workspace).dispatchEvent(new CustomEvent(command, {bubbles: true, cancelable: true}))

  commandRecieved: (data) ->
    body = data.toString('utf8')
    console.log body: body
    parsed = JSON.parse body
    command = parsed.command
    options = parsed.options
    console.log
      method: "commandRecieved"
      body: body
      parsed: parsed
      command: command
      options: options
    if @[command]?
      @[command](options)
    else if window.voiceCodeCommands?[command]
      window.voiceCodeCommands?[command](options)
    else
      atom.notifications.addError("the command: '#{command}' was not found. Try updating the Atom voicecode package.")
  _editor: ->
    atom.workspace.getActiveTextEditor()
  _afterRange: (selection, editor) ->
    [selection.getBufferRange().end, editor.getEofBufferPosition()]
  _beforeRange: (selection) ->
    [0, selection.getBufferRange().start]
  _pointAfter: (pt) ->
    new Point(pt.row, pt.column + 1)
  _pointBefore: (pt) ->
    new Point(pt.row, pt.column - 1)
  _searchEscape: (expression) ->
    expression.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")

  goToLine: (line) ->
    position = new Point(line - 1, 0)
    editor = @_editor()
    editor.scrollToBufferPosition(position)
    editor.setCursorBufferPosition(position)
    editor.moveToFirstCharacterOfLine()

  selectLineRange: (options) ->
    from = new Point(options.from - 1, 0)
    to = new Point(options.to, 0)
    editor = @_editor()
    return unless editor
    editor.setSelectedBufferRange([from, to])

  extendSelectionToLine: (line) ->
    line = line - 1
    editor = @_editor()
    return unless editor
    current = editor.getSelections()[0].getBufferRange()
    range = if line < current.start.row
      [new Point(line, 0), current.end]
    else if line > current.end.row
      [current.start, new Point(line + 1, 0)]
    else if line is current.start.row or line is current.end.row
      # nothing
    else
      topHeight = line - current.start.row
      bottomHeight = current.end.row - line
      if topHeight > bottomHeight
        [new Point(line, 0), current.end]
      else
        [current.start, new Point(line + 1, 0)]
    if range?
      editor.setSelectedBufferRange(range)

  selectNextWord: (distance) ->
    editor = @_editor()
    return unless editor
    for selection in editor.getSelections()
      index = 0
      found = null
      range = @_afterRange(selection, editor)
      editor.scanInBufferRange /[\w]+/g, range, (result) ->
        if result.match
          found = result
          if index++ is (distance - 1)
            result.stop()
      if found?
        selection.setBufferRange([found.range.start, found.range.end])
    editor.mergeCursors() # undocumented

  selectPreviousWord: (distance) ->
    editor = @_editor()
    return unless editor
    for selection in editor.getSelections()
      index = 0
      found = null
      range = @_beforeRange(selection)
      editor.backwardsScanInBufferRange /[\w]+/g, range, (result) ->
        if result.match
          found = result
          if index++ is (distance - 1)
            result.stop()
      if found?
        selection.setBufferRange([found.range.start, found.range.end])
    editor.mergeCursors() # undocumented

  ###
  options.value => search term
  options.distance => preferred match index
  ###
  selectNextOccurrence: (options) ->
    editor = @_editor()
    return unless editor
    found = null
    if options.value is null
      options.value = editor.selections[0].getText()
      return if options.value is ''
    for selection in editor.getSelections()
      index = 0
      range = @_afterRange(selection, editor)
      editor.scanInBufferRange new RegExp(@_searchEscape(options.value), "ig"), range, (result) ->
        if result.match
          found = result
          if index++ is (options.distance - 1)
            result.stop()
      if found?
        selection.setBufferRange([found.range.start, found.range.end])
    editor.mergeCursors() # undocumented

  ###
  options.value => search term
  options.distance => preferred match index
  ###
  selectPreviousOccurrence: (options) ->
    editor = @_editor()
    return unless editor
    found = null
    if options.value is null
      options.value = editor.selections[0].getText()
      return if options.value is ''
    for selection in editor.getSelections()
      index = 0
      range = @_beforeRange(selection)
      editor.backwardsScanInBufferRange new RegExp(@_searchEscape(options.value), "ig"), range, (result) ->
        if result.match
          found = result
          if index++ is (options.distance - 1)
            result.stop()
      if found?
        selection.setBufferRange([found.range.start, found.range.end])
    editor.mergeCursors() # undocumented

  ###
  options.value => search term
  options.distance => preferred match index
  ###
  selectToNextOccurrence: (options) ->
    editor = @_editor()
    return unless editor
    for selection, index in editor.getSelections()
      found = null
      index = 0
      range = @_afterRange(selection, editor)
      editor.scanInBufferRange new RegExp(@_searchEscape(options.value), "ig"), range, (result) ->
        console.log result: result
        if result.match
          found = result
          if index++ is (options.distance - 1)
            result.stop()
      if found?
        selection.setBufferRange([selection.getBufferRange().start, found.range.end])

  ###
  options.value => search term
  options.distance => preferred match index
  ###
  selectToPreviousOccurrence: (options) ->
    editor = @_editor()
    return unless editor
    for selection in editor.getSelections()
      found = null
      index = 0
      range = @_beforeRange(selection, editor)
      editor.backwardsScanInBufferRange new RegExp(@_searchEscape(options.value), "ig"), range, (result) ->
        if result.match
          found = result
          if index++ is (options.distance - 1)
            result.stop()
      if found?
        selection.setBufferRange([found.range.start, selection.getBufferRange().end])

  selectSurroundedOccurrence: (options) ->
    expression = options.expression
    return unless expression.length
    direction = options.direction
    distance = (options.distance or 1) - 1

    first = expression[0]
    last = expression[expression.length - 1]
    find = new RegExp("(^|\\W)#{first}[\\w]+#{last}($|\\W)", "ig")
    editor = @_editor()
    return unless editor
    console.log
      first: first
      last: last
      find: find

    for selection in editor.getSelections()
      found = null
      index = 0
      if direction is 1
        range = @_afterRange(selection, editor)
        editor.scanInBufferRange find, range, (result) ->
          if result.match
            found = result
            if index++ is (options.distance - 1)
              result.stop()
      else
        range = @_beforeRange(selection)
        editor.backwardsScanInBufferRange find, range, (result) ->
          if result.match
            found = result
            if index++ is (options.distance - 1)
              result.stop()
      if found?
        selection.setBufferRange([@_pointAfter(found.range.start), @_pointBefore(found.range.end)])

  # case transforms

  transformSelectedText: (transform) ->
    transformer = new Transformer()
    editor = @_editor()
    return unless editor
    editor.mutateSelectedText (selection) ->
      text = selection.getText()
      transformed = transformer[transform](text)
      selection.delete()
      selection.insertText(transformed)

  insertContentFromLine: (line) ->
    editor = @_editor()
    return unless editor
    return unless line
    content = editor.getBuffer().lines[line - 1]?.trim()
    editor.insertText(content)

module.exports = Voicecode
