# VoiceCode package

This package integrates VoiceCode (voicecode.io) with Atom.

This integration is needed because many VoiceCode voice commands are more sophisticated than simply pressing keys. For example, a command like "select next word".

The integration is handled via unix sockets for communicating between Atom and VoiceCode.

## Setup

### Connecting

#### Automatically On Startup

To automatically connect Atom to VoiceCode on startup, in your Atom user init file, add the following:

```
atom.commands.dispatch(atom.views.getView(atom.workspace), 'voicecode:connect')
```

#### Manually

If you want to manually connected rather than have it auto-connect, just click the menu item: `Packages > VoiceCode > Connect`

### Adding your own commands


If you want to add new commands that are not already included in this passage, just do the following in your Atom user init file:

```
window.voiceCodeCommands =
  myCoolCommand: (options) ->
    # do something here
    # the 'options' are passed over from VoiceCode
    console.log "my cool command worked!"
```

Then, in your VoiceCode user commands, you can call this Atom command as follows:

```
"commandName":
    kind: "action"
    description: "does something cool, and has an override for Atom IDE"
    grammarType: "numberCapture"
    action: (input) ->
      switch @currentApplication()
        when "Sublime Text"
          @exec "subl --command 'select_next_word'"
        when "Atom"
          @runAtomCommand
            command: "myCoolCommand"
            options: input or 1
        else
          @selectContiguousMatching
            input: input
            expression: /\w/
            direction: 1
```
