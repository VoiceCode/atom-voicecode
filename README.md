# VoiceCode / Atom Integration Package

This is an Atom package/plugin that lets VoiceCode http://voicecode.io control Atom http://atom.io

This integration is needed because many VoiceCode voice commands are more sophisticated than simply pressing keys or clicking the mouse. For example, a command that *selects the next curly brace*, or a command that *extends the current selection(s) forward until the next comma*, etc. It also enables synchronous bidirectional communication between VoiceCode and Atom.

## Setup

### Connecting

#### Automatically On Startup

To automatically connect Atom to VoiceCode on startup, in your Atom user init file, add the following:

```coffeescript
atom.commands.dispatch(atom.views.getView(atom.workspace), 'voicecode:connect')
```

#### Manually

If you want to manually connect it rather than have it auto-connect, just click the menu item: `Packages > VoiceCode > Connect`

### Triggering Atom commands
The Atom editor has a ton of built-in commands, and each Atom package adds even more. Any of these commands can be triggered directly from VoiceCode. In VoiceCode simply do:

```coffeescript
@runAtomCommand "trigger", {command: "tree-view:add-file"}
```

## Contributing

If you would like to make custom changes or contribute to this package, general development instructions are here: https://github.com/atom/atom/blob/master/docs/contributing-to-packages.md

## Installing a non-master branch of this plug-in for development or testing

- In Atom, go to preferences/packages and uninstall the VoiceCode package
- `git clone` the branch or version of this repository you want to use
- from the root of the the cloned repository, run `apm link`
- restart Atom
