{CompositeDisposable} = require 'atom'

module.exports = LinterLanguagetool =
  config:
    languagetoolServerPath:
      title: 'URL of the Languagetool server or path to your local languagetool-server.jar'
      description: """Set the URL of your Languagetool server.
        It defaults to the public Languagetool server API.
        If you give the path to your local languagetool-server.jar,
        linter tries to start the local languagetool server and connect to it."""
      type: 'string'
      default: 'https://languagetool.org/api/'
      order: 1
    configFilePath:
      title: 'Path to a config file'
      description: 'Path to a configuration file for the LanguageTool server. Can be used to provide the path to the n-gram data to LanugageTool. If given, LanguageTool can detect errors with words that are often confused, like *their* and *there*. See [LanguageTool Wiki](http://wiki.languagetool.org/finding-errors-using-n-gram-data) for more information'
      type: 'string'
      default: ''
    languagetoolServerPort:
      title: 'Port for local languagetool-server.jar'
      description: 'Sets the port on which the local languagetool server will listen.'
      type: 'number'
      default: 8081
    preferredVariants:
      type: 'array'
      description: 'List of preferred language variants. The language detector used with language=auto can detect e.g. English, but it cannot decide whether British English or American English is used. Thus this parameter can be used to specify the preferred variants like en-GB and de-AT. Only available with language=auto.'
      default: []
      items:
        type: 'string'
    disabledCategories:
      type: 'array'
      description: 'List of LanguageTool rule categories to be disabled.'
      default: []
      items:
        type: 'string'
    disabledRules:
      type: 'array'
      description: 'List of LanguageTool rules to be disabled.'
      default: []
      items:
        type: 'string'
    motherTongue:
      type: 'string'
      description: 'A language code of the user\'s native language, enabling false friends checks for some language pairs.'
      default: require('electron').remote.app.getLocale()
    lintsOnChange:
      type: 'boolean'
      description: 'If enabled the linter will run on every change on the file.'
      default: false
      
  activate: ->
    @subscriptions = new CompositeDisposable()
    lthelper = require './ltserver-helper'
    lthelper.init()

    GrammarManager = require './grammar-manager'
    global.grammarManager = new GrammarManager()
    @subscriptions.add(global.grammarManager)

    LTInfoView = require './lt-status-view'
    @ltInfo = new LTInfoView()
    
  
  deactivate: ->
    lthelper = require './ltserver-helper'
    lthelper?.destroy()
    
    @ltInfo?.destroy()
    @ltInfo = null
    
    @statusBarTile?.destroy()
    @statusBarTile = null
    
    @subscriptions?.dispose()
    @subscriptions = null
    
  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addRightTile(item: @ltInfo.element, priority: 400)

  consumeGrammar: (grammars) ->
    return global.grammarManager.consumeGrammar(grammars)

  provideGrammar: ->
    GrammarProvider = require './grammar-provider'
    return GrammarProvider.provideGrammar()

  provideLinter: ->
    LinterProvider = require './linter-provider'
    provider = new LinterProvider()
    return {
      name: 'languagetool'
      scope: 'file'
      lintsOnChange: atom.config.get 'linter-languagetool.lintsOnChange'
      grammarScopes: ['*']
      lint: provider.lint
    }
