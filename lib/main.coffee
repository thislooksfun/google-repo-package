{requirePackages}     = require 'atom-utils'
{CompositeDisposable} = require 'atom'
repoHost              = require './repoHost'
graphics              = require './graphicIntegrationOverride'

module.exports = GoogleRepo =
  googleRepoView: null
  subscriptions: null

  # Power up the module
  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'google-repo:refresh': => @refresh()
    
    # Wait for 'tree-view' and 'status-bar' to load before continuing
    requirePackages("tree-view", "status-bar").then ([tree, statusBar]) =>
      root = tree.treeView.list[0].querySelector('.project-root').directory
      repoHost.start root, =>            # Start the trackers
        graphics.override statusBar.git  # Initalize the overrides
  
  # Deactivate everything
  deactivate: ->
    @subscriptions.dispose()  # Throw away subscriptions
    repoHost.stop()           # Clean up logic
  
  # Reload everything except the command subscriptions
  refresh: ->
    repoHost.stop()
    tree = atom.packages.getLoadedPackage("tree-view").mainModule
    root = tree.treeView.list[0].querySelector('.project-root').directory
    repoHost.start root