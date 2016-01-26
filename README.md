# VoiceCode / Atom Integration Package

This is an Atom package/plugin that lets VoiceCode http://voicecode.io control Atom http://atom.io

This integration is needed because many VoiceCode voice commands are more sophisticated than simply pressing keys or clicking the mouse. For example, a command that *selects the next curly brace*, or a command that *extends the current selection(s) forward until the next comma*, etc.

## Setup

### Connecting

#### Automatically On Startup

To automatically connect Atom to VoiceCode on startup, in your Atom user init file, add the following:

```coffeescript
atom.commands.dispatch(atom.views.getView(atom.workspace), 'voicecode:connect')
```

#### Manually

If you want to manually connect it rather than have it auto-connect, just click the menu item: `Packages > VoiceCode > Connect`

## Adding your own commands

If you want to add new commands that are not already included in this package, just do the following in your Atom user init file:

```coffeescript
window.voiceCodeCommands =
  myCoolCommand: (options) ->
    # do something here
    # the 'options' are passed over from VoiceCode
    console.log "my cool command worked!"
```

Then, in your VoiceCode user commands, you can call this Atom command as follows:

```coffeescript
@runAtomCommand "myCoolCommand", someObjectOrValue
```

And for a more concrete example, it may look like this in VoiceCode:

```coffeescript
"commandName":
    kind: "action"
    description: "does something cool, and has an override for Atom IDE"
    grammarType: "numberCapture"
    action: (input) ->
      switch @currentApplication()
        when "Sublime Text"
          @exec "subl --command 'select_next_word'"
        when "Atom"
          @runAtomCommand "myCoolCommand",
            distance: input
            value: "something"
        else
          # do some default action
```

### Triggering existing Atom commands

In VoiceCode simply do:

```coffeescript
@runAtomCommand "trigger", "tree-view:add-file"
```

## Contributing

If you would like to make custom changes or contribute to this package, general development instructions are here: https://github.com/atom/atom/blob/master/docs/contributing-to-packages.md
