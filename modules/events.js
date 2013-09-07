function EventEmitter(){this.domain=null,EventEmitter.usingDomains&&(domain=domain||require("domain"),domain.active&&!(this instanceof domain.Domain)&&(this.domain=domain.active)),this._events=this._events||{},this._maxListeners=this._maxListeners||undefined}var domain,util=require("util");module.exports=EventEmitter,EventEmitter.EventEmitter=EventEmitter,EventEmitter.usingDomains=!1,EventEmitter.prototype.domain=undefined,EventEmitter.prototype._events=undefined,EventEmitter.prototype._maxListeners=undefined,EventEmitter.defaultMaxListeners=10,EventEmitter.prototype.setMaxListeners=function(e){if(!util.isNumber(e)||e<0)throw TypeError("n must be a positive number");return this._maxListeners=e,this},EventEmitter.prototype.emit=function(e){var t,n,r,i,s,o;this._events||(this._events={});if(e==="error")if(!this._events.error||util.isObject(this._events.error)&&!this._events.error.length){t=arguments[1];if(!this.domain)throw t instanceof Error?t:TypeError('Uncaught, unspecified "error" event.');return t||(t=new TypeError('Uncaught, unspecified "error" event.')),t.domainEmitter=this,t.domain=this.domain,t.domainThrown=!1,this.domain.emit("error",t),!1}n=this._events[e];if(util.isUndefined(n))return!1;this.domain&&this!==process&&this.domain.enter();if(util.isFunction(n))switch(arguments.length){case 1:n.call(this);break;case 2:n.call(this,arguments[1]);break;case 3:n.call(this,arguments[1],arguments[2]);break;default:r=arguments.length,i=new Array(r-1);for(s=1;s<r;s++)i[s-1]=arguments[s];n.apply(this,i)}else if(util.isObject(n)){r=arguments.length,i=new Array(r-1);for(s=1;s<r;s++)i[s-1]=arguments[s];o=n.slice(),r=o.length;for(s=0;s<r;s++)o[s].apply(this,i)}return this.domain&&this!==process&&this.domain.exit(),!0},EventEmitter.prototype.addListener=function(e,t){var n;if(!util.isFunction(t))throw TypeError("listener must be a function");this._events||(this._events={}),this._events.newListener&&this.emit("newListener",e,util.isFunction(t.listener)?t.listener:t),this._events[e]?util.isObject(this._events[e])?this._events[e].push(t):this._events[e]=[this._events[e],t]:this._events[e]=t;if(util.isObject(this._events[e])&&!this._events[e].warned){var n;util.isUndefined(this._maxListeners)?n=EventEmitter.defaultMaxListeners:n=this._maxListeners,n&&n>0&&this._events[e].length>n&&(this._events[e].warned=!0,console.error("(node) warning: possible EventEmitter memory leak detected. %d listeners added. Use emitter.setMaxListeners() to increase limit.",this._events[e].length),console.trace())}return this},EventEmitter.prototype.on=EventEmitter.prototype.addListener,EventEmitter.prototype.once=function(e,t){function n(){this.removeListener(e,n),t.apply(this,arguments)}if(!util.isFunction(t))throw TypeError("listener must be a function");return n.listener=t,this.on(e,n),this},EventEmitter.prototype.removeListener=function(e,t){var n,r,i,s;if(!util.isFunction(t))throw TypeError("listener must be a function");if(!this._events||!this._events[e])return this;n=this._events[e],i=n.length,r=-1;if(n===t||util.isFunction(n.listener)&&n.listener===t)delete this._events[e],this._events.removeListener&&this.emit("removeListener",e,t);else if(util.isObject(n)){for(s=i;s-->0;)if(n[s]===t||n[s].listener&&n[s].listener===t){r=s;break}if(r<0)return this;n.length===1?(n.length=0,delete this._events[e]):n.splice(r,1),this._events.removeListener&&this.emit("removeListener",e,t)}return this},EventEmitter.prototype.removeAllListeners=function(e){var t,n;if(!this._events)return this;if(!this._events.removeListener)return arguments.length===0?this._events={}:this._events[e]&&delete this._events[e],this;if(arguments.length===0){for(t in this._events){if(t==="removeListener")continue;this.removeAllListeners(t)}return this.removeAllListeners("removeListener"),this._events={},this}n=this._events[e];if(util.isFunction(n))this.removeListener(e,n);else while(n.length)this.removeListener(e,n[n.length-1]);return delete this._events[e],this},EventEmitter.prototype.listeners=function(e){var t;return!this._events||!this._events[e]?t=[]:util.isFunction(this._events[e])?t=[this._events[e]]:t=this._events[e].slice(),t},EventEmitter.listenerCount=function(e,t){var n;return!e._events||!e._events[t]?n=0:util.isFunction(e._events[t])?n=1:n=e._events[t].length,n}