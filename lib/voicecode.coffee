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

  selectNextWord: (distance) ->
    console.log "select next word"
    editor = atom.workspaceView.getActiveView()?.editor
    return unless editor
    for selection in editor.getSelections()
      range = [@_pointAfter(editor, selection.getBufferRange().end), editor.getEofBufferPosition()]
      editor.scanInBufferRange /[\w]+/, range, (result) ->
        if result.match
          selection.setBufferRange([result.range.start, result.range.end])
        result.stop()
    editor.mergeCursors() # undocumented

  selectPreviousWord: (distance) ->
    console.log "select previous word"
    editor = atom.workspaceView.getActiveView()?.editor
    return unless editor
    for selection in editor.getSelections()
      range = [0, @_pointBefore(editor, selection.getBufferRange().start)]
      editor.backwardsScanInBufferRange /[\w]+/, range, (result) ->
        if result.match
          selection.setBufferRange([result.range.start, result.range.end])
        result.stop()
    editor.mergeCursors() # undocumented

  _pointAfter: (editor, pt) ->
    new Point(pt.row, pt.column + 1)

  _pointBefore: (editor, pt) ->
    new Point(pt.row, pt.column)
