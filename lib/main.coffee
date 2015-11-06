{requirePackages}     = require 'atom-utils'
{CompositeDisposable} = require 'atom'
repoHost              = require './repoHost'
graphics              = require './graphicIntegrationOverride'

module.exports = GoogleRepo =
  subscriptions: null

  # Power up the module
  activate: (state) ->
    @subscriptions = new CompositeDisposable  # Create a new subscriptions object
    
    @subscriptions.add atom.commands.add 'atom-workspace', 'google-repo:refresh': => @refresh()  # Add the refresh command
    
    requirePackages("tree-view", "status-bar").then ([tree, statusBar]) =>   # Wait for 'tree-view' and 'status-bar' to load before continuing
      root = tree.treeView.list[0].querySelector('.project-root').directory  # Get the root of the tree view
      
      repoHost.start root, =>            # Start the trackers
        graphics.override statusBar.git  # Initalize the overrides
  
  # Deactivate everything
  deactivate: ->
    @subscriptions.dispose()  # Throw away subscriptions
    repoHost.stop()           # Clean up logic
    graphics.restore()
  
  # Reload everything except the command subscriptions
  refresh: ->
    repoHost.stop()     # Shut down the logic
    graphics.restore()  # Restore the overridden items
    
    tree = atom.packages.getLoadedPackage("tree-view").mainModule          # Get the tree-view module instance
    root = tree.treeView.list[0].querySelector('.project-root').directory  # Get the root of the tree view
    
    repoHost.start root, =>            # Start the trackers
      graphics.override statusBar.git  # Initalize the overrides