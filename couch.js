var ddoc = module.exports = {
  _id: '_design/app',
  views: {}
}

ddoc.views.by_email = {
  map: function(doc) { if (doc.email) emit(doc.email) }
}
