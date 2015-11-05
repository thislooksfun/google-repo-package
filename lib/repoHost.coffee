{CompositeDisposable} = require 'atom'
{Parser}              = require 'xml2js'
updater               = require './statusUpdater'
{Directory}           = require 'pathwatcher'
pathMod               = require 'path'

module.exports =
  start: (@root) ->
    @getRootDir().getSubdirectory(".repo").exists().then (exists) =>
      if exists
        @_beginLoad()
  
  
  stop: ->
    @subscriptions?.dispose()
    updater.deinit()
    #TODO
  
  
  _beginLoad: ->
    @collectRepos =>
      updater.init @, @root
      
      @scanAll(true).then =>  # Scan a first time to initalize everything
        @scanAll().then =>    # Scan a second time to read directory status
          updater.registerExpandListeners()
  
  
  scanAll: (isInit) ->
    updater.ignoreDotRepo()
    promise = new Promise (resolve, reject) =>
      @_crawl(new Directory(dir), repo, isInit ? false) for dir, repo of @repos
      resolve()
    
    return promise
  
  
  _crawl: (item, repo, isInit) ->
    relPath = pathMod.basename(pathMod.dirname(repo.path))+"/"+pathMod.relative(pathMod.dirname(repo.path), item.path)
    
    updater.updateItem(item, repo)
    
    if isInit && item.isFile()
      repo.isPathNew(item.path)
    
    if item.isDirectory()
      @_crawl entry, repo, isInit for entry in item.getEntriesSync()
  
  
  getRepoForPath: (path) ->
    for dir, repo of @repos
      return repo if path.indexOf(dir) > -1
    return null
  
  
  repos: {}
  
  collectRepos: (cb) ->
    @subscriptions?.dispose()
    @subscriptions = new CompositeDisposable
    
    mnfst = @getRootDir().getSubdirectory(".repo").getFile("manifest.xml")
    mnfst.read(false).then (contents) =>
      @getParser().parseString contents, (err, res) =>
        cnt = res.manifest.project.length
        dec = -> cb() if --cnt <= 0
        
        for proj in res.manifest.project
          abspth = pathMod.join(@getRootDir().path, proj.$.path)
          dir = new Directory(abspth)
          repo = atom.project.repositoryForDirectory(dir).then (repo) =>
            if repo?
              @repos[pathMod.dirname(repo.path)] = repo
              @subscriptions.add repo.onDidChangeStatus   => @scanAll().then => updater.registerExpandListeners()
              @subscriptions.add repo.onDidChangeStatuses => @scanAll().then => updater.registerExpandListeners()
            dec()
  
  
  getParser: ->
    @parser = new Parser() unless @parser?
    return @parser
  
  
  getRootDir: ->
    atom.project.getDirectories()[0]