@app = {}

$ = (selector) -> document.querySelector selector
$$ = (selector) -> document.querySelectorAll selector
map = (list, f) -> (f item for item in list)

load = ->
  request = new XMLHttpRequest
  request.open 'GET', '/folder', true
  request.addEventListener 'loadend', ->
    doc = JSON.parse this.responseText
    folder.innerHTML = ''
    if doc._attachments
      for name in Object.keys(doc._attachments)
        link = document.createElement 'a'
        link.href = "http://#{doc._id}.#{location.host}/#{name}";
        link.target = '_blank'
        link.innerText = name

        node = document.createElement 'div'
        node.className = 'file'
        node.appendChild link

        folder.appendChild node
  request.send()

@app.init = ->
  # authentication

  login.onclick = -> navigator.id.request()
  logout.onclick = -> navigator.id.logout()

  loggedin = (email) ->
    document.body.classList.add 'is_authenticated'
    document.body.classList.remove 'is_anonymous'
    map $$('output[name="email"]'), (el) -> el.innerText = email
    load()
  loggedout = ->
    document.body.classList.add 'is_anonymous'
    document.body.classList.remove 'is_authenticated'

  navigator.id.watch {
    onlogin: (assertion) ->
      request = new XMLHttpRequest
      request.open 'POST', '/persona/verify', true
      request.setRequestHeader 'Content-Type', 'application/json'
      request.addEventListener 'loadend', ->
        data = JSON.parse this.responseText
        if data?.status is 'okay' then loggedin data.email else loggedout()
      request.send JSON.stringify { assertion: assertion }
    onlogout: () ->
      request = new XMLHttpRequest
      request.open 'POST', '/persona/logout', true
      request.addEventListener 'loadend', -> loggedout()
      request.send()
  }

  # file handling
  folder.addEventListener 'dragover', (e) ->
    e.stopPropagation()
    e.preventDefault()
    e.dataTransfer.dropEffect = 'copy'
  folder.addEventListener 'drop', (e) ->
    e.stopPropagation()
    e.preventDefault()

    upload = (file) ->
      request = new XMLHttpRequest
      request.open 'PUT', '/folder/' + encodeURIComponent file.name, true
      request.setRequestHeader 'Content-Type', file.type
      request.addEventListener 'loadend', ->
        load()
      request.send file

    files = e.dataTransfer.files
    map files, upload

    #window.files = files
    #window.items = e.dataTransfer.items

    #output = (escape(f.name) for f in files).join '<br>'
    #folder.innerHTML = output
