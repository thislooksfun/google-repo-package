{CompositeDisposable} = require 'atom'
pathMod               = require 'path'

module.exports =
  
  init: (@host, @treeRoot) ->
    # empty
  
  deinit: ->
    @subscriptions?.dispose()
    @clearStatuses @treeRoot
  
  clearStatuses: (item) ->
    return unless item?
    @setStatus(item, null)
    
    return unless item.entries?
    @clearStatuses v for k, v of item.entries
  
  registerExpandListeners: ->
    @subscriptions?.dispose()
    @subscriptions = new CompositeDisposable
    @registerExpandListenersInDir @treeRoot
  
  
  registerExpandListenersInDir: (dir) ->
    @subscriptions.add dir.onDidAddEntries =>
      @host.scanAll().then => @registerExpandListeners()
    
    for k, v of dir.entries
      @registerExpandListenersInDir v if v.entries?
      
  
  ignoreDotRepo: ->
    end = @traverseTree @treeRoot, pathMod.join(@treeRoot.path, ".repo")
    return unless end?
    @ignoreAllIn end
  
  ignoreAllIn: (dir) ->
    @setStatus(dir, "ignored")
    
    for k, v of dir.entries
      if v.entries?
        @ignoreAllIn v
      else
        @setStatus(v, "ignored")
  
  
  updateItem: (item, repo) ->
    return unless item?
    repo = @host.getRepoForPath item.path unless repo?
    if item.isFile()
      @updateFile item, repo
    else
      @updateDir item, repo
  
  
  updateFile: (file, repo) ->
    return unless file?
    repo = @host.getRepoForPath file.path unless repo?
    end = @traverseTree @treeRoot, file.path
    return unless end?
    
    newStatus = null
    newStatus = "modified" if repo.isPathModified file.path
    newStatus = "added"    if repo.isPathNew      file.path
    newStatus = "ignored"  if repo.isPathIgnored  file.path
    @setStatus(end, newStatus)
  
  
  updateDir: (dir, repo) ->
    return unless dir?
    repo = @host.getRepoForPath dir.path unless repo?
    end = @traverseTree @treeRoot, dir.path
    return unless end?
    
    status = repo.getDirectoryStatus dir.path
    newStatus = null
    newStatus = "modified" if repo.isStatusModified status
    newStatus = "added"    if repo.isStatusNew      status
    newStatus = "ignored"  if repo.isPathIgnored    dir.path
    @setStatus(end, newStatus)
  
  
  setStatus: (item, state) ->
    return if item.state == state
    item.status = state
    item.emitter.emit("did-status-change", state)
  
  
  traverseTree: (tree, dest) ->
    rel = pathMod.relative(tree.path, dest)
    parts = rel.split(pathMod.sep)
    
    next = tree
    for p in parts
      break unless next?
      next = next.entries[p]
    
    return null unless next?
    return next