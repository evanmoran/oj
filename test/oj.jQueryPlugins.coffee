# oj.jQueryPlugins.coffee
# ==============================================================================

path = require 'path'
fs = require 'fs'
oj = require '../lib/oj.js'
oj.extend this

describe 'oj.jQueryPlugins', ->

  $body = $('body')
  $one = null
  $many = null
  one = 'one'
  many = 'many'
  added = 'added'
  added1 = 'added1'
  added2 = 'added2'
  added3 = 'added3'

  removeWhitespace = (str) ->
    str.replace /[\t\s\n]*(<.*>)[\t\s\n]*/gm, '$1'

  expectHTML = (htmlResult) ->
    htmlResult = removeWhitespace htmlResult
    expect($body.html()).to.equal htmlResult

  oneAddOne = (pluginName, html) ->
    $one[pluginName] ->
      oj.div c:added, added1
    expectHTML html

  oneAddMany = (pluginName, html) ->
    $one[pluginName] ->
      oj.div c:added, added1
      oj.div c:added, added2
    expectHTML html

  manyAddOne = (pluginName, html) ->
    $many[pluginName] ->
      oj.div c:added, added1
    expectHTML html

  manyAddMany = (pluginName, html) ->
    $many[pluginName] ->
      oj.div c:added, added1
      oj.div c:added, added2
    expectHTML html

  testPlugin = (pluginName, map) ->

    it "jquery.#{pluginName} exists", ->
      expect($body.oj).to.be.a 'function'

    it "jquery.#{pluginName}: select one, add one", ->
      oneAddOne pluginName, map.oneOne

    it "jquery.#{pluginName}: select one, add many", ->
      oneAddMany pluginName, map.oneMany

    it "jquery.#{pluginName}: select many, add one", ->
      manyAddOne pluginName, map.manyOne

    it "jquery.#{pluginName}: select many, add many", ->
      manyAddMany pluginName, map.manyMany

  beforeEach ->
    # Clear html
    $body.html removeWhitespace """
      <div class="one">
        <div class="many">many1</div>
        <div class="many">many2</div>
      </div>
    """

    $one = $('.one')
    $many = $('.many')

  # jquery.oj
  # ---------------------------------------------------------------------------

  testPlugin 'oj',
    oneOne: """
      <div class="one">
        <div class="added">added1</div>
      </div>
    """
    oneMany: """
      <div class="one">
        <div class="added">added1</div>
        <div class="added">added2</div>
      </div>
    """
    manyOne: """
      <div class="one">
        <div class="many">
          <div class="added">added1</div>
        </div>
        <div class="many">
          <div class="added">added1</div>
        </div>
      </div>
    """
    manyMany: """
      <div class="one">
        <div class="many">
          <div class="added">added1</div>
          <div class="added">added2</div>
        </div>
        <div class="many">
          <div class="added">added1</div>
          <div class="added">added2</div>
        </div>
      </div>
    """


  it "jquery.ojValue get number", ->
    $('body').html """
      <div class="test">42</div>
    """
    expect($('.test').ojValue()).to.equal '42'

  it "jquery.ojValue get string", ->
    $('body').html """
      <div class="test">forty-two</div>
    """
    expect($('.test').ojValue()).to.equal 'forty-two'

  it "jquery.ojValue get oj instance", ->
    cb = null
    $('body').oj ->
      oj.div c:'test', ->
        cb = oj.CheckBox value:true

    result = $('.test').ojValue()
    expect(oj.isOJ result).to.equal true
    expect(result.typeName).to.equal 'CheckBox'
    expect(result).to.equal cb

  it "jquery.ojValue get one (element)", ->

    result = $one.ojValue()
    expect(oj.isDOMElement result).to.equal true
    expect(result.tagName).to.equal 'DIV'

  it "jquery.ojValue get many (strings)", ->
    results = $many.ojValue()
    expect(results).to.deep.equal ['many1', 'many2']

  # jquery.ojAfter
  # ---------------------------------------------------------------------------
  testPlugin 'ojAfter',
    oneOne: """
      <div class="one">
        <div class="many">many1</div>
        <div class="many">many2</div>
      </div>
      <div class="added">added1</div>
    """
    oneMany: """
      <div class="one">
        <div class="many">many1</div>
        <div class="many">many2</div>
      </div>
      <div class="added">added1</div>
      <div class="added">added2</div>
    """
    manyOne: """
      <div class="one">
        <div class="many">many1</div>
        <div class="added">added1</div>
        <div class="many">many2</div>
        <div class="added">added1</div>
      </div>
    """
    manyMany: """
      <div class="one">
        <div class="many">many1</div>
        <div class="added">added1</div>
        <div class="added">added2</div>
        <div class="many">many2</div>
        <div class="added">added1</div>
        <div class="added">added2</div>
      </div>
    """

  # jquery.ojBefore
  # ---------------------------------------------------------------------------

  testPlugin 'ojBefore',
    oneOne: """
      <div class="added">added1</div>
      <div class="one">
        <div class="many">many1</div>
        <div class="many">many2</div>
      </div>
    """
    oneMany: """
      <div class="added">added1</div>
      <div class="added">added2</div>
      <div class="one">
        <div class="many">many1</div>
        <div class="many">many2</div>
      </div>
    """
    manyOne: """
      <div class="one">
        <div class="added">added1</div>
        <div class="many">many1</div>
        <div class="added">added1</div>
        <div class="many">many2</div>
      </div>
    """
    manyMany: """
      <div class="one">
        <div class="added">added1</div>
        <div class="added">added2</div>
        <div class="many">many1</div>
        <div class="added">added1</div>
        <div class="added">added2</div>
        <div class="many">many2</div>
      </div>
    """

  # jquery.ojAppend
  # ---------------------------------------------------------------------------

  testPlugin 'ojAppend',
    oneOne: """
      <div class="one">
        <div class="many">many1</div>
        <div class="many">many2</div>
        <div class="added">added1</div>
      </div>
    """
    oneMany: """
      <div class="one">
        <div class="many">many1</div>
        <div class="many">many2</div>
        <div class="added">added1</div>
        <div class="added">added2</div>
      </div>
    """
    manyOne: """
      <div class="one">
        <div class="many">many1
          <div class="added">added1</div>
        </div>
        <div class="many">many2
          <div class="added">added1</div>
        </div>
      </div>
    """
    manyMany: """
      <div class="one">
        <div class="many">many1
          <div class="added">added1</div>
          <div class="added">added2</div>
        </div>
        <div class="many">many2
          <div class="added">added1</div>
          <div class="added">added2</div>
        </div>
      </div>
    """

  # jquery.ojPrepend
  # ---------------------------------------------------------------------------

  testPlugin 'ojPrepend',
    oneOne: """
      <div class="one">
        <div class="added">added1</div>
        <div class="many">many1</div>
        <div class="many">many2</div>
      </div>
    """
    oneMany: """
      <div class="one">
        <div class="added">added1</div>
        <div class="added">added2</div>
        <div class="many">many1</div>
        <div class="many">many2</div>
      </div>
    """
    manyOne: """
      <div class="one">
        <div class="many">
          <div class="added">added1</div>
          many1
        </div>
        <div class="many">
          <div class="added">added1</div>
          many2
        </div>
      </div>
    """
    manyMany: """
      <div class="one">
        <div class="many">
          <div class="added">added1</div>
          <div class="added">added2</div>
          many1
        </div>
        <div class="many">
          <div class="added">added1</div>
          <div class="added">added2</div>
          many2
        </div>
      </div>
    """


  # jquery.ojReplaceWith
  # ---------------------------------------------------------------------------

  testPlugin 'ojReplaceWith',
    oneOne: """
      <div class="added">added1</div>
    """
    oneMany: """
      <div class="added">added1</div>
      <div class="added">added2</div>
    """
    manyOne: """
      <div class="one">
        <div class="added">added1</div>
        <div class="added">added1</div>
      </div>
    """
    manyMany: """
      <div class="one">
        <div class="added">added1</div>
        <div class="added">added2</div>
        <div class="added">added1</div>
        <div class="added">added2</div>
      </div>
    """

  # jquery.ojWrap
  # ---------------------------------------------------------------------------

  testPlugin 'ojWrap',
    oneOne: """
      <div class="added">added1
        <div class="one">
          <div class="many">many1</div>
          <div class="many">many2</div>
        </div>
      </div>
    """
    oneMany: """
      <div class="added">added1
        <div class="one">
          <div class="many">many1</div>
          <div class="many">many2</div>
        </div>
      </div>
    """
    manyOne: """
      <div class="one">
        <div class="added">added1
          <div class="many">many1</div>
        </div>
        <div class="added">added1
          <div class="many">many2</div>
        </div>
      </div>
    """
    manyMany: """
      <div class="one">
        <div class="added">added1
          <div class="many">many1</div>
        </div>
        <div class="added">added1
          <div class="many">many2</div>
        </div>
      </div>
    """

  # jquery.ojWrapInner
  # ---------------------------------------------------------------------------

  testPlugin 'ojWrapInner',
    oneOne: """
      <div class="one">
        <div class="added">added1
          <div class="many">many1</div>
          <div class="many">many2</div>
        </div>
      </div>
    """
    oneMany: """
      <div class="one">
        <div class="added">added1
          <div class="many">many1</div>
          <div class="many">many2</div>
        </div>
      </div>
    """
    manyOne: """
      <div class="one">
        <div class="many">
          <div class="added">added1many1</div>
        </div>
        <div class="many">
          <div class="added">added1many2</div>
        </div>
      </div>
    """
    manyMany: """
      <div class="one">
        <div class="many">
          <div class="added">added1many1</div>
        </div>
        <div class="many">
          <div class="added">added1many2</div>
        </div>
      </div>

    """

