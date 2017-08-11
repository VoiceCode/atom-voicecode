ws = require 'ws'
vm = require 'vm'
rpc = require 'atomic_rpc'
{TextEditor} = require 'atom'
remote = require('remote')
app = remote.app
_ = require 'lodash'
AtomSpacePenViews = require 'atom-space-pen-views'
$ = require 'jquery'

class Voicecode
  constructor: ->
    @subscriptions = []
    @myWindowId = remote.getCurrentWindow().id
    @subscribeToWindowFocus()
    @remote = new rpc
      host: 'localhost'
      port: 7777
      reconnect: true
    @remote.expose 'injectCode', @injectCode.bind @
    @instrumented = new WeakSet()

    $(document).bind "DOMSubtreeModified",  _.debounce ( =>
      _.each $('atom-text-editor'), (element) =>
        return true if @instrumented.has element
        editor = element.getModel()

        element.addEventListener 'focus', =>
          @lastFocused = editor
          @updateEditorState editor, true
        element.addEventListener 'blur', =>
          @updateEditorState editor, false

        @instrumented.add element
        if $(element).hasClass('is-focused')
          @lastFocused = editor
          @updateEditorState editor, true
    ), 100, {leading: false, trailing: true}
    @remote.on 'connect', (socket) ->
      console.log 'voicecode connected'

    @remote.initialize()
    @remote.expose 'sendCurrentEditor', @sendCurrentEditor, @

  activate: (state) ->

  updateEditorState: (editor, focused) ->
    @updateAppState
      editor:
        id: editor.id
        focused: (focused and remote.getCurrentWindow().isFocused())
        mini: editor.mini
        scopes: editor.getRootScopeDescriptor().scopes

  subscribeToWindowFocus: ->
    @subscriptions.push app.on 'browser-window-blur',
     (e, window) =>
       if editor = @currentEditor()
         @lastFocused = editor
    @subscriptions.push app.on 'browser-window-focus',
    (e, window) =>
      if window.id is @myWindowId
        @lastFocused?.editorElement.dispatchEvent new Event 'focus'

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

  sendCurrentEditor: ->
    if remote.getCurrentWindow().isFocused
      if ettore = @currentEditor()
        @updateEditorState editor, true

  currentEditor: ->
    $('atom-text-editor.is-focused')[0]?.getModel()

module.exports = window.voicecode = new Voicecode
