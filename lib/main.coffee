{requirePackages}     = require 'atom-utils'
{CompositeDisposable} = require 'atom'
repoHost              = require './repoHost'

module.exports = GoogleRepo =
  googleRepoView: null
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    
    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'google-repo:refresh': => @refresh()
    
    requirePackages("tree-view").then ([tree]) =>
      root = tree.treeView.list[0].querySelector('.project-root').directory
      repoHost.start root

  deactivate: ->
    @subscriptions.dispose()
    repoHost.stop()

  refresh: ->
    repoHost.stop()
    tree = atom.packages.getLoadedPackage("tree-view").mainModule
    root = tree.treeView.list[0].querySelector('.project-root').directory
    repoHost.start root