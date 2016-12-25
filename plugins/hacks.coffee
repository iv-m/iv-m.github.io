
run = (require 'child_process').spawnSync
path = require 'path'

module.exports = (env, callback) ->
    env.helpers.foo = 'hi there'
    env.helpers.getLastUpdateTime = (filepath) ->
        result = run 'git', [
            'log', '-1', '--pretty=%cd', '--date=iso8601',
            path.join env.config.contents, filepath]
        return result.stdout.toString().trim()
    callback()

