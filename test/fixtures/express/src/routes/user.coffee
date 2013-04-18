
###
  GET user page
###

module.exports = (req, res) ->
  res.render 'user', title: 'User Page'
