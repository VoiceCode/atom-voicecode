net = require("net")
fs = require("fs")
socketPath = "/tmp/voicecode-atom.sock"

{View, EditorView, $, Point} = require 'atom'

module.exports = Voicecode =
  voicecodeView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    atom.commands.add 'atom-workspace', 'voicecode:connect': => @connect()
    atom.commands.add 'atom-workspace', 'voicecode:select-next-word': => @selectNextWord()

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
    editor = atom.workspaceView.getActiveView()?.editor
  _afterRange: (selection, editor) ->
    [@_pointAfter(selection.getBufferRange().end), editor.getEofBufferPosition()]
  _beforeRange: (selection) ->
    [0, @_pointBefore(selection.getBufferRange().start)]
  _pointAfter: (pt) ->
    new Point(pt.row, pt.column + 1)
  _pointBefore: (pt) ->
    new Point(pt.row, pt.column)
  _searchEscape: (expression) ->
    expression.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")

  selectNextWord: (distance) ->
    console.log "select next word"
    editor = @_editor()
    return unless editor
    for selection in editor.getSelections()
      range = @_afterRange(selection, editor)
      editor.scanInBufferRange /[\w]+/, range, (result) ->
        if result.match
          selection.setBufferRange([result.range.start, result.range.end])
        result.stop()
    editor.mergeCursors() # undocumented

  selectPreviousWord: (distance) ->
    console.log "select previous word"
    editor = @_editor()
    return unless editor
    for selection in editor.getSelections()
      range = @_beforeRange(selection)
      editor.backwardsScanInBufferRange /[\w]+/, range, (result) ->
        if result.match
          selection.setBufferRange([result.range.start, result.range.end])
        result.stop()
    editor.mergeCursors() # undocumented

  ###
  options.value => search term
  options.distance => preferred match index
  ###
  selectNextOccurrence: (options) ->
    console.log "select next occurrence"
    editor = @_editor()
    return unless editor
    found = null
    for selection, index in editor.getSelections()
      range = @_afterRange(selection, editor)
      editor.scanInBufferRange new RegExp(@_searchEscape(options.value), "i"), range, (result) ->
        if result.match
          found = result
          if index is (options.distance - 1)
            result.stop()
      if found?
        selection.setBufferRange([found.range.start, found.range.end])
    editor.mergeCursors() # undocumented

  ###
  options.value => search term
  options.distance => preferred match index
  ###
  selectPreviousOccurrence: (options) ->
    console.log "select previous occurrence"
    editor = @_editor()
    return unless editor
    found = null
    for selection, index in editor.getSelections()
      range = @_beforeRange(selection)
      editor.backwardsScanInBufferRange new RegExp(@_searchEscape(options.value), "i"), range, (result) ->
        if result.match
          found = result
          if index is (options.distance - 1)
            result.stop()
      if found?
        selection.setBufferRange([found.range.start, found.range.end])
    editor.mergeCursors() # undocumented
