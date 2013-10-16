
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





