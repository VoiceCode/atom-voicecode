ws = require 'ws'
vm = require 'vm'
rpc = require 'atomic_rpc'
{TextEditor} = require 'atom'
remote = require('remote')
app = remote.require 'app'
_ = require 'lodash'
$ = require 'jquery'

class Voicecode
  constructor: ->
    @subscriptions = []
    @editors = {} # TODO: cleanup dead editors

  activate: (state) ->
    @window = remote.getCurrentWindow()
    @remote = new rpc
      host: 'localhost'
      port: 7777
      reconnect: true
    @remote.expose 'injectCode', @injectCode.bind @

    # @subscriptions.push app.on 'browser-window-blur',
    # (e, window) =>
    #   @updateAppState
    #     window:
    #       focused: false
    # @subscriptions.push app.on 'browser-window-focus',
    # (e, window) =>
    #   @updateAppState
    #     window:
    #       focused: true

    @subscriptions.push atom.workspace.observeTextEditors _.once (editor) =>
      originalFocused = $('atom-text-editor')[0].constructor::focused
      originalBlurred = $('atom-text-editor')[0].constructor::blurred
      __this = @
      handler = (original, focus) ->
        @model.focused = focus
        __this.updateEditorState @model
        original.apply @, arguments

      $('atom-text-editor')[0].constructor::blurred = ->
        handler.call @, originalBlurred, false
      $('atom-text-editor')[0].constructor::focused = ->
        handler.call @, originalFocused, true

  updateEditorState: (editor) ->
    @editors[editor.id] = editor
    @updateAppState
      editor:
        id: editor.id
        focused: editor.focused
        mini: editor.mini

  updateAppState: (state) ->
    @remote.call
      method: 'updateAppState'
      params: state

  deactivate: ->
    _.all @subscriptions, (subscription) ->
      subscription.dispose()

  serialize: ->

  injectCode: ({code}, callback) ->
    injectedMethods = @evaluate code
    _.every injectedMethods, (funk, name) =>
      @remote.expose name, funk, injectedMethods

  evaluate: (code) ->
    sandbox = vm.createContext _.extend {}, global, {_, CustomEvent, $}
    try
      vm.runInContext code, sandbox
    catch err
      console.error err

  currentEditor: ->
    _.findWhere @editors, {focused: true}

module.exports = window.voicecode = new Voicecode
