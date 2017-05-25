ws = require 'ws'
vm = require 'vm'
rpc = require 'atomic_rpc'
{TextEditor} = require 'atom'
remote = require('remote')
app = remote.app
_ = require 'lodash'
AtomSpacePenViews = require 'atom-space-pen-views'

class Voicecode
  constructor: ->
    @subscriptions = []
    @editors = {}
    @startMaintenance()
    @myWindowId = remote.getCurrentWindow().id
    @subscribeToWindowFocus()
    @remote = new rpc
      host: 'localhost'
      port: 7777
      reconnect: true
    @remote.expose 'injectCode', @injectCode.bind @

    element = document.createElement 'atom-text-editor'
    originalFocused = element.constructor::focused
    originalBlurred = element.constructor::blurred
    __this = @
    handler = (focusEvent, original, focus) ->
      __this.updateEditorState @model, focus
      original.call @, focusEvent
    ourBlurred = (focusEvent) ->
      handler.call @, focusEvent, originalBlurred, false
    ourFocused = (focusEvent) ->
      handler.call @, focusEvent, originalFocused, true
    element.constructor::blurred = ourBlurred
    element.constructor::focused = ourFocused

    # bind our proxied blur/focus event to existing editors
    editors = atom.workspace.getTextEditors()
    _.every editors, (editor) ->
      element = atom.views.getView editor
      element.removeEventListener 'blur', originalBlurred
      element.removeEventListener 'focused', originalFocused
      element.addEventListener 'blur', element.constructor::blurred
      element.addEventListener 'focus', element.constructor::focused
      true
    @remote.on 'connect', (socket) ->
      document.querySelector('atom-text-editor.is-focused')?.dispatchEvent new Event 'focus'
    @remote.initialize()
    @remote.expose 'sendCurrentEditor', @sendCurrentEditor, @


  activate: (state) ->
    
  updateEditorState: (editor, focused) ->
    # cache in order to not do a DOM look up in @currentEditor
    editor.focused = focused
    @editors[editor.id] = editor

    @updateAppState
      # name: 'Atom'
      # bundleId: 'com.github.atom'
      editor:
        id: editor.id
        focused: (focused and remote.getCurrentWindow().isFocused())
        mini: editor.mini
        scopes: editor.getRootScopeDescriptor().scopes

  subscribeToWindowFocus: ->
    # @subscriptions.push app.on 'browser-window-blur',
    # (e, window) =>
    #   console.log e
    #   @updateAppState
    #     window:
    #       focused: false

    # this tells remote side which window(socket) is focused(active)
    @subscriptions.push app.on 'browser-window-focus',
    (e, window) =>
      if window.id is @myWindowId
        @updateAppState
          window:
            focused: true
            id: window.id
        @sendCurrentEditor()

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
      @remote.expose name, funk, @remote.exposures

  evaluate: (code) ->
    sandbox = vm.createContext _.extend {}, global, {_, CustomEvent, AtomSpacePenViews }
    try
      vm.runInContext code, sandbox
    catch err
      console.error err
      atom.notifications.addError('VoiceCode: Remote Commands Failed',
      {detail: err, dismissible: true, icon: 'bug'})

  # "manually" determine currently focused editor.
  sendCurrentEditor: ->
    if editor = @currentEditor()
      @updateEditorState editor, true

  currentEditor: ->
    result = _.find @editors, {focused: true}
    unless result?
      result = document.querySelector('atom-text-editor.is-focused')?.model
    result

  startMaintenance: ->
    setInterval ( =>
      @editors = _.reduce @editors, (editors, editor, id) ->
        if editor.alive
          editors[id] = editor
        editors
      , {}
      ), 120000
module.exports = window.voicecode = new Voicecode
