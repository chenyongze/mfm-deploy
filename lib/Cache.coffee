class Cache
    constructor: () ->
        @cache_ = {}
    get:(key) -> @cache_[key]
    set:(key,val,delay) ->
        @cache_[key] = val
        setTimeout () =>
            delete @cache_[key]
        ,delay * 1000
    clear:(key)->
        delete @cache_[key]
module.exports = Cache

# test
if require.main is module
    cache = new Cache
    cache.set 'c1','c1',2
    cache.set 'c2','c2',3
    t = (delay) ->
        setTimeout () ->
            console.log "time:#{delay}"
            console.log cache.get 'c1'
            console.log cache.get 'c2'
            console.log '-------------------'
        ,delay
    t 1.2
    t 2.5
    t 3
