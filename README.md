
oj
================================================================================

Object-oriented web templating for the people. *Thirsty people.*

[ojjs.org](http://ojjs.org)

[ojjs.org/docs](http://ojjs.org/docs)

[ojjs.org/learn](http://ojjs.org/learn)

[ojjs.org/download](http://ojjs.org/download)

Contact Info
--------------------------------------------------------------------------------

Reach out on irc or email. Log issues on GitHub!

irc: freenode.net #oj

email: evan(at)ojjs.org

twitter: @evanmoran

repo: github.com/ojjs/oj

Change Log:
--------------------------------------------------------------------------------

### 0.3.2
* Improved minification

### 0.3.1
* oj.List.each can accept a ModelView. By default the ModelView will be a child of the `<li>` element. Optionally the instace have a isListItem=true property, that when set will cause the ModelView to take the place of the `<li>` instead.
* OJ Core types like List, Table, CheckBox, now can be replaced by plugins. This is useful on certain "big framework" plugins -- more info coming soon!

### 0.3.0
* Express is supported with separate module compiling middleware
* Yeoman is supported. Install with `npm install -g generator oj` and then `yo oj`
* CLI supports --modules, --js, --css and --html to allow unified or separate compiling in any combination

### 0.2.2

* Added AMD support (for RequireJS)
* Added Bower support (a client side package manager)
* Fixing oj.toCSS to correctly accept minify option
* Fixing oj.copyProperty to handle null definitions

### 0.2.1

* Adding `insert` event to tag functions that is triggered when the element is inserted
  This very fast and does not use DOMNodeInserted.

### 0.2.0

* Rewrote oj.js into JavaScript (from CoffeeScript)
* Minified code is now 16% smaller
* Performance is 10% faster
* Removed id generation for root object elements
* Remove oj.id and oj.guid methods since id generation isn't necessary
* Removed typeOf method as it was slow and for the most part unused
* Remove several internal helper functions

### 0.1.6

* Fixes npm package management

### 0.1.5

* Minor fix to npm package to ensure it works without coffee-script installed globally.

### 0.1.4

* Plugins now include themselves once required in node or included with a `<script>` tag client-side
* Hacker News initial release.

### 0.1.0

* Everything works. Time to make it great.





