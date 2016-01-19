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
    element = document.createElement 'atom-text-editor'
    originalFocused = element.constructor::focused
    originalBlurred = element.constructor::blurred
    __this = @
    handler = (focusEvent, original, focus) ->
      @model.focused = focus
      __this.updateEditorState @model
      original.apply @, focusEvent

    element.constructor::blurred = (focusEvent) ->
      handler.call @, focusEvent, originalBlurred, false
    element.constructor::focused = (focusEvent) ->
      handler.call @, focusEvent, originalFocused, true

    @subscriptions = []
    @editors = {} # TODO: cleanup dead editors

  activate: (state) ->
    @myWindowId = remote.getCurrentWindow().id
    @subscribeToWindowFocus()
    @remote = new rpc
      host: 'localhost'
      port: 7777
      reconnect: true
    @remote.expose 'injectCode', @injectCode.bind @

  updateEditorState: (editor) ->
    @editors[editor.id] = editor
    @updateAppState
      editor:
        id: editor.id
        focused: editor.focused
        mini: editor.mini

  subscribeToWindowFocus: ->
    # @subscriptions.push app.on 'browser-window-blur',
    # (e, window) =>
    #   console.log e
    #   @updateAppState
    #     window:
    #       focused: false
    @subscriptions.push app.on 'browser-window-focus',
    (e, window) =>
      if window.id is @myWindowId
        editor = _.findWhere @editors, {focused: true }
        if editor?
          @updateEditorState editor
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
