{requirePackages}              = require 'atom-utils'
{CompositeDisposable, Emitter} = require 'atom'
RepoHost                       = require './repoHost'
GraphicsOverride               = require './graphicIntegrationOverride'
PluginManagement               = require './mixins/plugin-management'

class Main
  PluginManagement.includeInto(this)
  
  
  subscriptions: null  # The subscriptions we have
  emitter: null
  host: null
  
  # Power up the module
  activate: (state) ->
    @subscriptions = new CompositeDisposable  # Create a new subscriptions object
    
    @subscriptions.add atom.commands.add 'atom-workspace', 'google-repo:refresh': => @refresh()  # Add the refresh command
    
    @emitter = new Emitter
    
    @host = new RepoHost  # Create the RepoHost instance
    
    requirePackages("tree-view", "status-bar").then ([tree, statusBar]) =>   # Wait for 'tree-view' and 'status-bar' to load before continuing
      root = tree.treeView.list[0].querySelector('.project-root').directory  # Get the root of the tree view
      
      @graphics = new GraphicsOverride @host, statusBar.git  # Create the GraphicsOverride instance
      @host.start root, @emitter, =>  # Start the repo logic
        @graphics.override()          # Initalize the overrides
  
  
  onRepoListChange: (cb) ->
    @emitter.on "repo-list-change", cb
  
  
  # Deactivate everything
  deactivate: ->
    @subscriptions.dispose()  # Throw away subscriptions
    @host.stop()              # Clean up logic
    @graphics.restore()       # Restore the functions we replaced
  
  
  # Reload everything except the command subscriptions
  refresh: ->
    @host.stop()         # Shut down the logic
    @graphics.restore()  # Restore the overridden items
    
    tree = atom.packages.getLoadedPackage("tree-view").mainModule          # Get the tree-view module instance
    root = tree.treeView.list[0].querySelector('.project-root').directory  # Get the root of the tree view
    
    @host.start root, =>  # Start the repo logic
      @graphics.override  # Initalize the overrides


module.exports = new Main()