
###
  GET home page.
###

module.exports = (req, res) ->
  res.render 'index', title: 'Index Page'
