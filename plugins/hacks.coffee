
run = (require 'child_process').spawnSync
path = require 'path'
_ = require 'underscore'

module.exports = (env, callback) ->

    env.helpers.getLastUpdateTime = (filepath) ->
        result = run 'git', [
            'log', '-1', '--pretty=%cd', '--date=iso8601',
            path.join env.config.contents, filepath]
        return result.stdout.toString().trim()

    env.helpers.getPages = (contents, path) ->
        # sort pages by date
        return env.helpers.getPagesSortedBy contents, path, (p) -> p.date

    env.helpers.getPagesSortedBy = (contents, path, sortBy) ->
        pages = contents[path]._.directories.map (item) -> item.index
            .filter (item) -> item.template isnt 'none'  # template should be there
            .filter (item) -> item.template.indexOf('draft') < 0  # no drafts please
        return _.sortBy pages, sortBy
            .reverse()

    callback()
