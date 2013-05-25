#!/usr/bin/env node_modules/.bin/coffee

# server.forfastlearners.com

express = require 'express'
fs      = require 'fs'

config  = require './config'

if config.server.port is 80
  server = config.server.name
else
  server = "#{config.server.name}:#{config.server.port}"

app = express()
db = require('couch') "#{config.couchdb.protocol}://#{config.couchdb.name}
:#{config.couchdb.port}/#{config.couchdb.db}"

app.use express.bodyParser()
app.use express.cookieParser()
app.use express.session { secret: config.secret }

require('express-persona') app, { audience: server }

folder_for = (email, callback) ->
  db.design('app').view('by_email').query { key: email, include_docs: true },
    (e, result) ->
      if result.rows.length is 1
        callback result.rows[0].doc
      else
        doc = { email: email, created: new Date }
        db.post doc, (e, info) ->
          doc._id = info.id
          doc._rev = info.rev
          callback doc

do ->
  http_proxy = require('http-proxy')
  proxy = new http_proxy.RoutingProxy
  @proxy_request = (req, res) ->
    proxy.proxyRequest req, res, {
      host: config.couchdb.name,
      port: config.couchdb.port 
    }

app.get '*', (req, res, next) ->
  if req.headers.host is server then next()
  else
    name = req.headers.host.split('.')[0]
    req.url = '/static-sites/' + name + req.url;
    proxy_request req, res

app.get '/folder', (req, res) ->
  email = req.session.email
  if not email? then return res.end 'not signed in'

  res.type 'json'
  folder_for email, (doc) -> res.end JSON.stringify doc

app.put '/folder/*', (req, res) ->
  email = req.session.email

  if email?
    folder_for email, (doc) ->
      req.url = req.url.replace 'folder', "#{config.couchdb.db}/#{doc._id}"
      req.url += "?rev=#{doc._rev}"
      console.log req.url
      proxy_request req, res
  else
    res.end 'not signed in'

app.get '/*', (req, res) ->
  path = "#{__dirname}/static#{req.url}"
  fs.exists path, (exists) ->
    if exists
      res.charset = 'utf-8'
      res.sendfile path
    else
      res.end '404'

app.listen config.server.port
