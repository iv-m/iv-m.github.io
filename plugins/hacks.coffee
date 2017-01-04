
run = (require 'child_process').spawnSync
path = require 'path'

module.exports = (env, callback) ->

    env.helpers.getLastUpdateTime = (filepath) ->
        result = run 'git', [
            'log', '-1', '--pretty=%cd', '--date=iso8601',
            path.join env.config.contents, filepath]
        return result.stdout.toString().trim()

    env.helpers.getPages = (contents, path) ->
        pages = contents[path]._.directories.map (item) -> item.index
        # skip pages that does not have a template associated
        pages = pages.filter (item) -> item.template isnt 'none'
        # also, skip drafts:
        pages = pages.filter (item) -> item.template.indexOf('draft') < 0
        # sort pages by date
        pages.sort (a, b) -> b.date - a.date
        return pages

    callback()

