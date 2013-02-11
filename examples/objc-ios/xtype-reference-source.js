// Built with IMPACT - impactjs.org
(function(window) {
	"use strict";
	Number.prototype.map = function(istart, istop, ostart, ostop) {
		return ostart + (ostop - ostart) * ((this - istart) / (istop - istart));
	};
	Number.prototype.limit = function(min, max) {
		return Math.min(max, Math.max(min, this));
	};
	Number.prototype.round = function(precision) {
		precision = Math.pow(10, precision || 0);
		return Math.round(this * precision) / precision;
	};
	Number.prototype.floor = function() {
		return Math.floor(this);
	};
	Number.prototype.ceil = function() {
		return Math.ceil(this);
	};
	Number.prototype.toInt = function() {
		return (this | 0);
	};
	Number.prototype.toRad = function() {
		return (this / 180) * Math.PI;
	};
	Number.prototype.toDeg = function() {
		return (this * 180) / Math.PI;
	};
	Array.prototype.erase = function(item) {
		for (var i = this.length; i--;) {
			if (this[i] === item) {
				this.splice(i, 1);
			}
		}
		return this;
	};
	Array.prototype.random = function() {
		return this[Math.floor(Math.random() * this.length)];
	};
	Function.prototype.bind = Function.prototype.bind ||
	function(oThis) {
		if (typeof this !== "function") {
			throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable");
		}
		var aArgs = Array.prototype.slice.call(arguments, 1),
			fToBind = this,
			fNOP = function() {},
			fBound = function() {
				return fToBind.apply((this instanceof fNOP && oThis ? this : oThis), aArgs.concat(Array.prototype.slice.call(arguments)));
			};
		fNOP.prototype = this.prototype;
		fBound.prototype = new fNOP();
		return fBound;
	};
	window.ig = {
		game: null,
		debug: null,
		version: '1.20',
		global: window,
		modules: {},
		resources: [],
		ready: false,
		baked: false,
		nocache: '',
		ua: {},
		prefix: (window.ImpactPrefix || ''),
		lib: 'lib/',
		_current: null,
		_loadQueue: [],
		_waitForOnload: 0,
		$: function(selector) {
			return selector.charAt(0) == '#' ? document.getElementById(selector.substr(1)) : document.getElementsByTagName(selector);
		},
		$new: function(name) {
			return document.createElement(name);
		},
		copy: function(object) {
			if (!object || typeof(object) != 'object' || object instanceof HTMLElement || object instanceof ig.Class) {
				return object;
			} else if (object instanceof Array) {
				var c = [];
				for (var i = 0, l = object.length; i < l; i++) {
					c[i] = ig.copy(object[i]);
				}
				return c;
			} else {
				var c = {};
				for (var i in object) {
					c[i] = ig.copy(object[i]);
				}
				return c;
			}
		},
		merge: function(original, extended) {
			for (var key in extended) {
				var ext = extended[key];
				if (typeof(ext) != 'object' || ext instanceof HTMLElement || ext instanceof ig.Class) {
					original[key] = ext;
				} else {
					if (!original[key] || typeof(original[key]) != 'object') {
						original[key] = (ext instanceof Array) ? [] : {};
					}
					ig.merge(original[key], ext);
				}
			}
			return original;
		},
		ksort: function(obj) {
			if (!obj || typeof(obj) != 'object') {
				return [];
			}
			var keys = [],
				values = [];
			for (var i in obj) {
				keys.push(i);
			}
			keys.sort();
			for (var i = 0; i < keys.length; i++) {
				values.push(obj[keys[i]]);
			}
			return values;
		},
		setVendorAttribute: function(el, attr, val) {
			var uc = attr.charAt(0).toUpperCase() + attr.substr(1);
			el[attr] = el['ms' + uc] = el['moz' + uc] = el['webkit' + uc] = el['o' + uc] = val;
		},
		getVendorAttribute: function(el, attr) {
			var uc = attr.charAt(0).toUpperCase() + attr.substr(1);
			return el[attr] || el['ms' + uc] || el['moz' + uc] || el['webkit' + uc] || el['o' + uc];
		},
		normalizeVendorAttribute: function(el, attr) {
			var prefixedVal = ig.getVendorAttribute(el, attr);
			if (!el[attr] && prefixedVal) {
				el[attr] = prefixedVal;
			}
		},
		getImagePixels: function(image, x, y, width, height) {
			var canvas = ig.$new('canvas');
			canvas.width = image.width;
			canvas.height = image.height;
			var ctx = canvas.getContext('2d');
			var ratio = ig.getVendorAttribute(ctx, 'backingStorePixelRatio') || 1;
			ig.normalizeVendorAttribute(ctx, 'getImageDataHD');
			var realWidth = image.width / ratio,
				realHeight = image.height / ratio;
			canvas.width = Math.ceil(realWidth);
			canvas.height = Math.ceil(realHeight);
			ctx.drawImage(image, 0, 0, realWidth, realHeight);
			return (ratio === 1) ? ctx.getImageData(x, y, width, height) : ctx.getImageDataHD(x, y, width, height);
		},
		module: function(name) {
			if (ig._current) {
				throw ("Module '" + ig._current.name + "' defines nothing");
			}
			if (ig.modules[name] && ig.modules[name].body) {
				throw ("Module '" + name + "' is already defined");
			}
			ig._current = {
				name: name,
				requires: [],
				loaded: false,
				body: null
			};
			ig.modules[name] = ig._current;
			ig._loadQueue.push(ig._current);
			return ig;
		},
		requires: function() {
			ig._current.requires = Array.prototype.slice.call(arguments);
			return ig;
		},
		defines: function(body) {
			ig._current.body = body;
			ig._current = null;
			ig._initDOMReady();
		},
		addResource: function(resource) {
			ig.resources.push(resource);
		},
		setNocache: function(set) {
			ig.nocache = set ? '?' + Date.now() : '';
		},
		log: function() {},
		assert: function(condition, msg) {},
		show: function(name, number) {},
		mark: function(msg, color) {},
		_loadScript: function(name, requiredFrom) {
			ig.modules[name] = {
				name: name,
				requires: [],
				loaded: false,
				body: null
			};
			ig._waitForOnload++;
			var path = ig.prefix + ig.lib + name.replace(/\./g, '/') + '.js' + ig.nocache;
			var script = ig.$new('script');
			script.type = 'text/javascript';
			script.src = path;
			script.onload = function() {
				ig._waitForOnload--;
				ig._execModules();
			};
			script.onerror = function() {
				throw ('Failed to load module ' + name + ' at ' + path + ' ' + 'required from ' + requiredFrom);
			};
			ig.$('head')[0].appendChild(script);
		},
		_execModules: function() {
			var modulesLoaded = false;
			for (var i = 0; i < ig._loadQueue.length; i++) {
				var m = ig._loadQueue[i];
				var dependenciesLoaded = true;
				for (var j = 0; j < m.requires.length; j++) {
					var name = m.requires[j];
					if (!ig.modules[name]) {
						dependenciesLoaded = false;
						ig._loadScript(name, m.name);
					} else if (!ig.modules[name].loaded) {
						dependenciesLoaded = false;
					}
				}
				if (dependenciesLoaded && m.body) {
					ig._loadQueue.splice(i, 1);
					m.loaded = true;
					m.body();
					modulesLoaded = true;
					i--;
				}
			}
			if (modulesLoaded) {
				ig._execModules();
			} else if (!ig.baked && ig._waitForOnload == 0 && ig._loadQueue.length != 0) {
				var unresolved = [];
				for (var i = 0; i < ig._loadQueue.length; i++) {
					var unloaded = [];
					var requires = ig._loadQueue[i].requires;
					for (var j = 0; j < requires.length; j++) {
						var m = ig.modules[requires[j]];
						if (!m || !m.loaded) {
							unloaded.push(requires[j]);
						}
					}
					unresolved.push(ig._loadQueue[i].name + ' (requires: ' + unloaded.join(', ') + ')');
				}
				throw ('Unresolved (circular?) dependencies. ' + "Most likely there's a name/path mismatch for one of the listed modules:\n" + unresolved.join('\n'));
			}
		},
		_DOMReady: function() {
			if (!ig.modules['dom.ready'].loaded) {
				if (!document.body) {
					return setTimeout(ig._DOMReady, 13);
				}
				ig.modules['dom.ready'].loaded = true;
				ig._waitForOnload--;
				ig._execModules();
			}
			return 0;
		},
		_boot: function() {
			if (document.location.href.match(/\?nocache/)) {
				ig.setNocache(true);
			}
			ig.ua.pixelRatio = window.devicePixelRatio || 1;
			ig.ua.viewport = {
				width: window.innerWidth,
				height: window.innerHeight
			};
			ig.ua.screen = {
				width: window.screen.availWidth * ig.ua.pixelRatio,
				height: window.screen.availHeight * ig.ua.pixelRatio
			};
			ig.ua.iPhone = /iPhone/i.test(navigator.userAgent);
			ig.ua.iPhone4 = (ig.ua.iPhone && ig.ua.pixelRatio == 2);
			ig.ua.iPad = /iPad/i.test(navigator.userAgent);
			ig.ua.android = /android/i.test(navigator.userAgent);
			ig.ua.iOS = ig.ua.iPhone || ig.ua.iPad;
			ig.ua.mobile = ig.ua.iOS || ig.ua.android;
		},
		_initDOMReady: function() {
			if (ig.modules['dom.ready']) {
				ig._execModules();
				return;
			}
			ig._boot();
			ig.modules['dom.ready'] = {
				requires: [],
				loaded: false,
				body: null
			};
			ig._waitForOnload++;
			if (document.readyState === 'complete') {
				ig._DOMReady();
			} else {
				document.addEventListener('DOMContentLoaded', ig._DOMReady, false);
				window.addEventListener('load', ig._DOMReady, false);
			}
		}
	};
	ig.normalizeVendorAttribute(window, 'requestAnimationFrame');
	if (window.requestAnimationFrame) {
		var next = 1,
			anims = {};
		window.ig.setAnimation = function(callback, element) {
			var current = next++;
			anims[current] = true;
			var animate = function() {
					if (!anims[current]) {
						return;
					}
					window.requestAnimationFrame(animate, element);
					callback();
				};
			window.requestAnimationFrame(animate, element);
			return current;
		};
		window.ig.clearAnimation = function(id) {
			delete anims[id];
		};
	} else {
		window.ig.setAnimation = function(callback, element) {
			return window.setInterval(callback, 1000 / 60);
		};
		window.ig.clearAnimation = function(id) {
			window.clearInterval(id);
		};
	}
	var initializing = false,
		fnTest = /xyz/.test(function() {
			xyz;
		}) ? /\bparent\b/ : /.*/;
	window.ig.Class = function() {};
	var inject = function(prop) {
			var proto = this.prototype;
			var parent = {};
			for (var name in prop) {
				if (typeof(prop[name]) == "function" && typeof(proto[name]) == "function" && fnTest.test(prop[name])) {
					parent[name] = proto[name];
					proto[name] = (function(name, fn) {
						return function() {
							var tmp = this.parent;
							this.parent = parent[name];
							var ret = fn.apply(this, arguments);
							this.parent = tmp;
							return ret;
						};
					})(name, prop[name]);
				} else {
					proto[name] = prop[name];
				}
			}
		};
	window.ig.Class.extend = function(prop) {
		var parent = this.prototype;
		initializing = true;
		var prototype = new this();
		initializing = false;
		for (var name in prop) {
			if (typeof(prop[name]) == "function" && typeof(parent[name]) == "function" && fnTest.test(prop[name])) {
				prototype[name] = (function(name, fn) {
					return function() {
						var tmp = this.parent;
						this.parent = parent[name];
						var ret = fn.apply(this, arguments);
						this.parent = tmp;
						return ret;
					};
				})(name, prop[name]);
			} else {
				prototype[name] = prop[name];
			}
		}

		function Class() {
			if (!initializing) {
				if (this.staticInstantiate) {
					var obj = this.staticInstantiate.apply(this, arguments);
					if (obj) {
						return obj;
					}
				}
				for (var p in this) {
					if (typeof(this[p]) == 'object') {
						this[p] = ig.copy(this[p]);
					}
				}
				if (this.init) {
					this.init.apply(this, arguments);
				}
			}
			return this;
		}
		Class.prototype = prototype;
		Class.prototype.constructor = Class;
		Class.extend = window.ig.Class.extend;
		Class.inject = inject;
		return Class;
	};
})(window);

// lib/impact/image.js
ig.baked = true;
ig.module('impact.image').defines(function() {
	"use strict";
	ig.Image = ig.Class.extend({
		data: null,
		width: 0,
		height: 0,
		loaded: false,
		failed: false,
		loadCallback: null,
		path: '',
		staticInstantiate: function(path) {
			return ig.Image.cache[path] || null;
		},
		init: function(path) {
			this.path = path;
			this.load();
		},
		load: function(loadCallback) {
			if (this.loaded) {
				if (loadCallback) {
					loadCallback(this.path, true);
				}
				return;
			} else if (!this.loaded && ig.ready) {
				this.loadCallback = loadCallback || null;
				this.data = new Image();
				this.data.onload = this.onload.bind(this);
				this.data.onerror = this.onerror.bind(this);
				this.data.src = ig.prefix + this.path + ig.nocache;
			} else {
				ig.addResource(this);
			}
			ig.Image.cache[this.path] = this;
		},
		reload: function() {
			this.loaded = false;
			this.data = new Image();
			this.data.onload = this.onload.bind(this);
			this.data.src = this.path + '?' + Date.now();
		},
		onload: function(event) {
			this.width = this.data.width;
			this.height = this.data.height;
			this.loaded = true;
			if (ig.system.scale != 1) {
				this.resize(ig.system.scale);
			}
			if (this.loadCallback) {
				this.loadCallback(this.path, true);
			}
		},
		onerror: function(event) {
			this.failed = true;
			if (this.loadCallback) {
				this.loadCallback(this.path, false);
			}
		},
		resize: function(scale) {
			var origPixels = ig.getImagePixels(this.data, 0, 0, this.width, this.height);
			var widthScaled = this.width * scale;
			var heightScaled = this.height * scale;
			var scaled = ig.$new('canvas');
			scaled.width = widthScaled;
			scaled.height = heightScaled;
			var scaledCtx = scaled.getContext('2d');
			var scaledPixels = scaledCtx.getImageData(0, 0, widthScaled, heightScaled);
			for (var y = 0; y < heightScaled; y++) {
				for (var x = 0; x < widthScaled; x++) {
					var index = (Math.floor(y / scale) * this.width + Math.floor(x / scale)) * 4;
					var indexScaled = (y * widthScaled + x) * 4;
					scaledPixels.data[indexScaled] = origPixels.data[index];
					scaledPixels.data[indexScaled + 1] = origPixels.data[index + 1];
					scaledPixels.data[indexScaled + 2] = origPixels.data[index + 2];
					scaledPixels.data[indexScaled + 3] = origPixels.data[index + 3];
				}
			}
			scaledCtx.putImageData(scaledPixels, 0, 0);
			this.data = scaled;
		},
		draw: function(targetX, targetY, sourceX, sourceY, width, height) {
			if (!this.loaded) {
				return;
			}
			var scale = ig.system.scale;
			sourceX = sourceX ? sourceX * scale : 0;
			sourceY = sourceY ? sourceY * scale : 0;
			width = (width ? width : this.width) * scale;
			height = (height ? height : this.height) * scale;
			ig.system.context.drawImage(this.data, sourceX, sourceY, width, height, ig.system.getDrawPos(targetX), ig.system.getDrawPos(targetY), width, height);
			ig.Image.drawCount++;
		},
		drawTile: function(targetX, targetY, tile, tileWidth, tileHeight, flipX, flipY) {
			tileHeight = tileHeight ? tileHeight : tileWidth;
			if (!this.loaded || tileWidth > this.width || tileHeight > this.height) {
				return;
			}
			var scale = ig.system.scale;
			var tileWidthScaled = Math.floor(tileWidth * scale);
			var tileHeightScaled = Math.floor(tileHeight * scale);
			var scaleX = flipX ? -1 : 1;
			var scaleY = flipY ? -1 : 1;
			if (flipX || flipY) {
				ig.system.context.save();
				ig.system.context.scale(scaleX, scaleY);
			}
			ig.system.context.drawImage(this.data, (Math.floor(tile * tileWidth) % this.width) * scale, (Math.floor(tile * tileWidth / this.width) * tileHeight) * scale, tileWidthScaled, tileHeightScaled, ig.system.getDrawPos(targetX) * scaleX - (flipX ? tileWidthScaled : 0), ig.system.getDrawPos(targetY) * scaleY - (flipY ? tileHeightScaled : 0), tileWidthScaled, tileHeightScaled);
			if (flipX || flipY) {
				ig.system.context.restore();
			}
			ig.Image.drawCount++;
		}
	});
	ig.Image.drawCount = 0;
	ig.Image.cache = {};
	ig.Image.reloadCache = function() {
		for (var path in ig.Image.cache) {
			ig.Image.cache[path].reload();
		}
	};
});

// lib/impact/font.js
ig.baked = true;
ig.module('impact.font').requires('impact.image').defines(function() {
	"use strict";
	ig.Font = ig.Image.extend({
		widthMap: [],
		indices: [],
		firstChar: 32,
		alpha: 1,
		letterSpacing: 1,
		lineSpacing: 0,
		onload: function(ev) {
			this._loadMetrics(this.data);
			this.parent(ev);
		},
		widthForString: function(text) {
			if (text.indexOf('\n') !== -1) {
				var lines = text.split('\n');
				var width = 0;
				for (var i = 0; i < lines.length; i++) {
					width = Math.max(width, this._widthForLine(lines[i]));
				}
				return width;
			} else {
				return this._widthForLine(text);
			}
		},
		_widthForLine: function(text) {
			var width = 0;
			for (var i = 0; i < text.length; i++) {
				width += this.widthMap[text.charCodeAt(i) - this.firstChar] + this.letterSpacing;
			}
			return width;
		},
		heightForString: function(text) {
			return text.split('\n').length * (this.height + this.lineSpacing);
		},
		draw: function(text, x, y, align) {
			if (typeof(text) != 'string') {
				text = text.toString();
			}
			if (text.indexOf('\n') !== -1) {
				var lines = text.split('\n');
				var lineHeight = this.height + this.lineSpacing;
				for (var i = 0; i < lines.length; i++) {
					this.draw(lines[i], x, y + i * lineHeight, align);
				}
				return;
			}
			if (align == ig.Font.ALIGN.RIGHT || align == ig.Font.ALIGN.CENTER) {
				var width = this._widthForLine(text);
				x -= align == ig.Font.ALIGN.CENTER ? width / 2 : width;
			}
			if (this.alpha !== 1) {
				ig.system.context.globalAlpha = this.alpha;
			}
			for (var i = 0; i < text.length; i++) {
				var c = text.charCodeAt(i);
				x += this._drawChar(c - this.firstChar, x, y);
			}
			if (this.alpha !== 1) {
				ig.system.context.globalAlpha = 1;
			}
			ig.Image.drawCount += text.length;
		},
		_drawChar: function(c, targetX, targetY) {
			if (!this.loaded || c < 0 || c >= this.indices.length) {
				return 0;
			}
			var scale = ig.system.scale;
			var charX = this.indices[c] * scale;
			var charY = 0;
			var charWidth = this.widthMap[c] * scale;
			var charHeight = (this.height - 2) * scale;
			ig.system.context.drawImage(this.data, charX, charY, charWidth, charHeight, ig.system.getDrawPos(targetX), ig.system.getDrawPos(targetY), charWidth, charHeight);
			return this.widthMap[c] + this.letterSpacing;
		},
		_loadMetrics: function(image) {
			this.height = image.height - 1;
			this.widthMap = [];
			this.indices = [];
			var px = ig.getImagePixels(image, 0, image.height - 1, image.width, 1);
			var currentChar = 0;
			var currentWidth = 0;
			for (var x = 0; x < image.width; x++) {
				var index = x * 4 + 3;
				if (px.data[index] > 127) {
					currentWidth++;
				} else if (px.data[index] == 0 && currentWidth) {
					this.widthMap.push(currentWidth);
					this.indices.push(x - currentWidth);
					currentChar++;
					currentWidth = 0;
				}
			}
			this.widthMap.push(currentWidth);
			this.indices.push(x - currentWidth);
		}
	});
	ig.Font.ALIGN = {
		LEFT: 0,
		RIGHT: 1,
		CENTER: 2
	};
});

// lib/impact/sound.js
ig.baked = true;
ig.module('impact.sound').defines(function() {
	"use strict";
	ig.SoundManager = ig.Class.extend({
		clips: {},
		volume: 1,
		format: null,
		init: function() {
			if (!ig.Sound.enabled || !window.Audio) {
				ig.Sound.enabled = false;
				return;
			}
			var probe = new Audio();
			for (var i = 0; i < ig.Sound.use.length; i++) {
				var format = ig.Sound.use[i];
				if (probe.canPlayType(format.mime)) {
					this.format = format;
					break;
				}
			}
			if (!this.format) {
				ig.Sound.enabled = false;
			}
		},
		load: function(path, multiChannel, loadCallback) {
			var realPath = ig.prefix + path.replace(/[^\.]+$/, this.format.ext) + ig.nocache;
			if (this.clips[path]) {
				if (multiChannel && this.clips[path].length < ig.Sound.channels) {
					for (var i = this.clips[path].length; i < ig.Sound.channels; i++) {
						var a = new Audio(realPath);
						a.load();
						this.clips[path].push(a);
					}
				}
				return this.clips[path][0];
			}
			var clip = new Audio(realPath);
			if (loadCallback) {
				clip.addEventListener('canplaythrough', function cb(ev) {
					clip.removeEventListener('canplaythrough', cb, false);
					loadCallback(path, true, ev);
				}, false);
				clip.addEventListener('error', function(ev) {
					loadCallback(path, false, ev);
				}, false);
			}
			clip.preload = 'auto';
			clip.load();
			this.clips[path] = [clip];
			if (multiChannel) {
				for (var i = 1; i < ig.Sound.channels; i++) {
					var a = new Audio(realPath);
					a.load();
					this.clips[path].push(a);
				}
			}
			return clip;
		},
		get: function(path) {
			var channels = this.clips[path];
			for (var i = 0, clip; clip = channels[i++];) {
				if (clip.paused || clip.ended) {
					if (clip.ended) {
						clip.currentTime = 0;
					}
					return clip;
				}
			}
			channels[0].pause();
			channels[0].currentTime = 0;
			return channels[0];
		}
	});
	ig.Music = ig.Class.extend({
		tracks: [],
		namedTracks: {},
		currentTrack: null,
		currentIndex: 0,
		random: false,
		_volume: 1,
		_loop: false,
		_fadeInterval: 0,
		_fadeTimer: null,
		_endedCallbackBound: null,
		init: function() {
			this._endedCallbackBound = this._endedCallback.bind(this);
			if (Object.defineProperty) {
				Object.defineProperty(this, "volume", {
					get: this.getVolume.bind(this),
					set: this.setVolume.bind(this)
				});
				Object.defineProperty(this, "loop", {
					get: this.getLooping.bind(this),
					set: this.setLooping.bind(this)
				});
			} else if (this.__defineGetter__) {
				this.__defineGetter__('volume', this.getVolume.bind(this));
				this.__defineSetter__('volume', this.setVolume.bind(this));
				this.__defineGetter__('loop', this.getLooping.bind(this));
				this.__defineSetter__('loop', this.setLooping.bind(this));
			}
		},
		add: function(music, name) {
			if (!ig.Sound.enabled) {
				return;
			}
			var path = music instanceof ig.Sound ? music.path : music;
			var track = ig.soundManager.load(path, false);
			track.loop = this._loop;
			track.volume = this._volume;
			track.addEventListener('ended', this._endedCallbackBound, false);
			this.tracks.push(track);
			if (name) {
				this.namedTracks[name] = track;
			}
			if (!this.currentTrack) {
				this.currentTrack = track;
			}
		},
		next: function() {
			if (!this.tracks.length) {
				return;
			}
			this.stop();
			this.currentIndex = this.random ? Math.floor(Math.random() * this.tracks.length) : (this.currentIndex + 1) % this.tracks.length;
			this.currentTrack = this.tracks[this.currentIndex];
			this.play();
		},
		pause: function() {
			if (!this.currentTrack) {
				return;
			}
			this.currentTrack.pause();
		},
		stop: function() {
			if (!this.currentTrack) {
				return;
			}
			this.currentTrack.pause();
			this.currentTrack.currentTime = 0;
		},
		play: function(name) {
			if (name && this.namedTracks[name]) {
				var newTrack = this.namedTracks[name];
				if (newTrack != this.currentTrack) {
					this.stop();
					this.currentTrack = newTrack;
				}
			} else if (!this.currentTrack) {
				return;
			}
			this.currentTrack.play();
		},
		getLooping: function() {
			return this._loop;
		},
		setLooping: function(l) {
			this._loop = l;
			for (var i in this.tracks) {
				this.tracks[i].loop = l;
			}
		},
		getVolume: function() {
			return this._volume;
		},
		setVolume: function(v) {
			this._volume = v.limit(0, 1);
			for (var i in this.tracks) {
				this.tracks[i].volume = this._volume;
			}
		},
		fadeOut: function(time) {
			if (!this.currentTrack) {
				return;
			}
			clearInterval(this._fadeInterval);
			this.fadeTimer = new ig.Timer(time);
			this._fadeInterval = setInterval(this._fadeStep.bind(this), 50);
		},
		_fadeStep: function() {
			var v = this.fadeTimer.delta().map(-this.fadeTimer.target, 0, 1, 0).limit(0, 1) * this._volume;
			if (v <= 0.01) {
				this.stop();
				this.currentTrack.volume = this._volume;
				clearInterval(this._fadeInterval);
			} else {
				this.currentTrack.volume = v;
			}
		},
		_endedCallback: function() {
			if (this._loop) {
				this.play();
			} else {
				this.next();
			}
		}
	});
	ig.Sound = ig.Class.extend({
		path: '',
		volume: 1,
		currentClip: null,
		multiChannel: true,
		init: function(path, multiChannel) {
			this.path = path;
			this.multiChannel = (multiChannel !== false);
			this.load();
		},
		load: function(loadCallback) {
			if (!ig.Sound.enabled) {
				if (loadCallback) {
					loadCallback(this.path, true);
				}
				return;
			}
			if (ig.ready) {
				ig.soundManager.load(this.path, this.multiChannel, loadCallback);
			} else {
				ig.addResource(this);
			}
		},
		play: function() {
			if (!ig.Sound.enabled) {
				return;
			}
			this.currentClip = ig.soundManager.get(this.path);
			this.currentClip.volume = ig.soundManager.volume * this.volume;
			this.currentClip.play();
		},
		stop: function() {
			if (this.currentClip) {
				this.currentClip.pause();
				this.currentClip.currentTime = 0;
			}
		}
	});
	ig.Sound.FORMAT = {
		MP3: {
			ext: 'mp3',
			mime: 'audio/mpeg'
		},
		M4A: {
			ext: 'm4a',
			mime: 'audio/mp4; codecs=mp4a'
		},
		OGG: {
			ext: 'ogg',
			mime: 'audio/ogg; codecs=vorbis'
		},
		WEBM: {
			ext: 'webm',
			mime: 'audio/webm; codecs=vorbis'
		},
		CAF: {
			ext: 'caf',
			mime: 'audio/x-caf'
		}
	};
	ig.Sound.use = [ig.Sound.FORMAT.OGG, ig.Sound.FORMAT.MP3];
	ig.Sound.channels = 4;
	ig.Sound.enabled = true;
});

// lib/impact/loader.js
ig.baked = true;
ig.module('impact.loader').requires('impact.image', 'impact.font', 'impact.sound').defines(function() {
	"use strict";
	ig.Loader = ig.Class.extend({
		resources: [],
		gameClass: null,
		status: 0,
		done: false,
		_unloaded: [],
		_drawStatus: 0,
		_intervalId: 0,
		_loadCallbackBound: null,
		init: function(gameClass, resources) {
			this.gameClass = gameClass;
			this.resources = resources;
			this._loadCallbackBound = this._loadCallback.bind(this);
			for (var i = 0; i < this.resources.length; i++) {
				this._unloaded.push(this.resources[i].path);
			}
		},
		load: function() {
			ig.system.clear('#000');
			if (!this.resources.length) {
				this.end();
				return;
			}
			for (var i = 0; i < this.resources.length; i++) {
				this.loadResource(this.resources[i]);
			}
			this._intervalId = setInterval(this.draw.bind(this), 16);
		},
		loadResource: function(res) {
			res.load(this._loadCallbackBound);
		},
		end: function() {
			if (this.done) {
				return;
			}
			this.done = true;
			clearInterval(this._intervalId);
			ig.system.setGame(this.gameClass);
		},
		draw: function() {
			this._drawStatus += (this.status - this._drawStatus) / 5;
			var s = ig.system.scale;
			var w = ig.system.width * 0.6;
			var h = ig.system.height * 0.1;
			var x = ig.system.width * 0.5 - w / 2;
			var y = ig.system.height * 0.5 - h / 2;
			ig.system.context.fillStyle = '#000';
			ig.system.context.fillRect(0, 0, 480, 320);
			ig.system.context.fillStyle = '#fff';
			ig.system.context.fillRect(x * s, y * s, w * s, h * s);
			ig.system.context.fillStyle = '#000';
			ig.system.context.fillRect(x * s + s, y * s + s, w * s - s - s, h * s - s - s);
			ig.system.context.fillStyle = '#fff';
			ig.system.context.fillRect(x * s, y * s, w * s * this._drawStatus, h * s);
		},
		_loadCallback: function(path, status) {
			if (status) {
				this._unloaded.erase(path);
			} else {
				throw ('Failed to load resource: ' + path);
			}
			this.status = 1 - (this._unloaded.length / this.resources.length);
			if (this._unloaded.length == 0) {
				setTimeout(this.end.bind(this), 250);
			}
		}
	});
});

// lib/impact/timer.js
ig.baked = true;
ig.module('impact.timer').defines(function() {
	"use strict";
	ig.Timer = ig.Class.extend({
		target: 0,
		base: 0,
		last: 0,
		pausedAt: 0,
		init: function(seconds) {
			this.base = ig.Timer.time;
			this.last = ig.Timer.time;
			this.target = seconds || 0;
		},
		set: function(seconds) {
			this.target = seconds || 0;
			this.base = ig.Timer.time;
			this.pausedAt = 0;
		},
		reset: function() {
			this.base = ig.Timer.time;
			this.pausedAt = 0;
		},
		tick: function() {
			var delta = ig.Timer.time - this.last;
			this.last = ig.Timer.time;
			return (this.pausedAt ? 0 : delta);
		},
		delta: function() {
			return (this.pausedAt || ig.Timer.time) - this.base - this.target;
		},
		pause: function() {
			if (!this.pausedAt) {
				this.pausedAt = ig.Timer.time;
			}
		},
		unpause: function() {
			if (this.pausedAt) {
				this.base += ig.Timer.time - this.pausedAt;
				this.pausedAt = 0;
			}
		}
	});
	ig.Timer._last = 0;
	ig.Timer.time = Number.MIN_VALUE;
	ig.Timer.timeScale = 1;
	ig.Timer.maxStep = 0.05;
	ig.Timer.step = function() {
		var current = Date.now();
		var delta = (current - ig.Timer._last) / 1000;
		ig.Timer.time += Math.min(delta, ig.Timer.maxStep) * ig.Timer.timeScale;
		ig.Timer._last = current;
	};
});

// lib/impact/system.js
ig.baked = true;
ig.module('impact.system').requires('impact.timer', 'impact.image').defines(function() {
	"use strict";
	ig.System = ig.Class.extend({
		fps: 30,
		width: 320,
		height: 240,
		realWidth: 320,
		realHeight: 240,
		scale: 1,
		tick: 0,
		animationId: 0,
		newGameClass: null,
		running: false,
		delegate: null,
		clock: null,
		canvas: null,
		context: null,
		init: function(canvasId, fps, width, height, scale) {
			this.fps = fps;
			this.clock = new ig.Timer();
			this.canvas = ig.$(canvasId);
			this.resize(width, height, scale);
			this.context = this.canvas.getContext('2d');
			this.getDrawPos = ig.System.drawMode;
			if (this.scale != 1) {
				ig.System.scaleMode = ig.System.SCALE.CRISP;
			}
			ig.System.scaleMode(this.canvas, this.context);
		},
		resize: function(width, height, scale) {
			this.width = width;
			this.height = height;
			this.scale = scale || this.scale;
			this.realWidth = this.width * this.scale;
			this.realHeight = this.height * this.scale;
			this.canvas.width = this.realWidth;
			this.canvas.height = this.realHeight;
		},
		setGame: function(gameClass) {
			if (this.running) {
				this.newGameClass = gameClass;
			} else {
				this.setGameNow(gameClass);
			}
		},
		setGameNow: function(gameClass) {
			ig.game = new(gameClass)();
			ig.system.setDelegate(ig.game);
		},
		setDelegate: function(object) {
			if (typeof(object.run) == 'function') {
				this.delegate = object;
				this.startRunLoop();
			} else {
				throw ('System.setDelegate: No run() function in object');
			}
		},
		stopRunLoop: function() {
			ig.clearAnimation(this.animationId);
			this.running = false;
		},
		startRunLoop: function() {
			this.stopRunLoop();
			this.animationId = ig.setAnimation(this.run.bind(this), this.canvas);
			this.running = true;
		},
		clear: function(color) {
			this.context.fillStyle = color;
			this.context.fillRect(0, 0, this.realWidth, this.realHeight);
		},
		run: function() {
			ig.Timer.step();
			this.tick = this.clock.tick();
			this.delegate.run();
			ig.input.clearPressed();
			if (this.newGameClass) {
				this.setGameNow(this.newGameClass);
				this.newGameClass = null;
			}
		},
		getDrawPos: null
	});
	ig.System.DRAW = {
		AUTHENTIC: function(p) {
			return Math.round(p) * this.scale;
		},
		SMOOTH: function(p) {
			return Math.round(p * this.scale);
		},
		SUBPIXEL: function(p) {
			return p * this.scale;
		}
	};
	ig.System.drawMode = ig.System.DRAW.SMOOTH;
	ig.System.SCALE = {
		CRISP: function(canvas, context) {
			ig.setVendorAttribute(context, 'imageSmoothingEnabled', false);
			canvas.style.imageRendering = '-moz-crisp-edges';
			canvas.style.imageRendering = '-o-crisp-edges';
			canvas.style.imageRendering = '-webkit-optimize-contrast';
			canvas.style.imageRendering = 'crisp-edges';
			canvas.style.msInterpolationMode = 'nearest-neighbor';
		},
		SMOOTH: function(canvas, context) {
			ig.setVendorAttribute(context, 'imageSmoothingEnabled', true);
			canvas.style.imageRendering = '';
			canvas.style.msInterpolationMode = '';
		}
	};
	ig.System.scaleMode = ig.System.SCALE.SMOOTH;
});

// lib/impact/input.js
ig.baked = true;
ig.module('impact.input').defines(function() {
	"use strict";
	ig.KEY = {
		'MOUSE1': -1,
		'MOUSE2': -3,
		'MWHEEL_UP': -4,
		'MWHEEL_DOWN': -5,
		'BACKSPACE': 8,
		'TAB': 9,
		'ENTER': 13,
		'PAUSE': 19,
		'CAPS': 20,
		'ESC': 27,
		'SPACE': 32,
		'PAGE_UP': 33,
		'PAGE_DOWN': 34,
		'END': 35,
		'HOME': 36,
		'LEFT_ARROW': 37,
		'UP_ARROW': 38,
		'RIGHT_ARROW': 39,
		'DOWN_ARROW': 40,
		'INSERT': 45,
		'DELETE': 46,
		'_0': 48,
		'_1': 49,
		'_2': 50,
		'_3': 51,
		'_4': 52,
		'_5': 53,
		'_6': 54,
		'_7': 55,
		'_8': 56,
		'_9': 57,
		'A': 65,
		'B': 66,
		'C': 67,
		'D': 68,
		'E': 69,
		'F': 70,
		'G': 71,
		'H': 72,
		'I': 73,
		'J': 74,
		'K': 75,
		'L': 76,
		'M': 77,
		'N': 78,
		'O': 79,
		'P': 80,
		'Q': 81,
		'R': 82,
		'S': 83,
		'T': 84,
		'U': 85,
		'V': 86,
		'W': 87,
		'X': 88,
		'Y': 89,
		'Z': 90,
		'NUMPAD_0': 96,
		'NUMPAD_1': 97,
		'NUMPAD_2': 98,
		'NUMPAD_3': 99,
		'NUMPAD_4': 100,
		'NUMPAD_5': 101,
		'NUMPAD_6': 102,
		'NUMPAD_7': 103,
		'NUMPAD_8': 104,
		'NUMPAD_9': 105,
		'MULTIPLY': 106,
		'ADD': 107,
		'SUBSTRACT': 109,
		'DECIMAL': 110,
		'DIVIDE': 111,
		'F1': 112,
		'F2': 113,
		'F3': 114,
		'F4': 115,
		'F5': 116,
		'F6': 117,
		'F7': 118,
		'F8': 119,
		'F9': 120,
		'F10': 121,
		'F11': 122,
		'F12': 123,
		'SHIFT': 16,
		'CTRL': 17,
		'ALT': 18,
		'PLUS': 187,
		'COMMA': 188,
		'MINUS': 189,
		'PERIOD': 190
	};
	ig.Input = ig.Class.extend({
		bindings: {},
		actions: {},
		presses: {},
		locks: {},
		delayedKeyup: {},
		isUsingMouse: false,
		isUsingKeyboard: false,
		isUsingAccelerometer: false,
		mouse: {
			x: 0,
			y: 0
		},
		accel: {
			x: 0,
			y: 0,
			z: 0
		},
		initMouse: function() {
			if (this.isUsingMouse) {
				return;
			}
			this.isUsingMouse = true;
			var mouseWheelBound = this.mousewheel.bind(this);
			ig.system.canvas.addEventListener('mousewheel', mouseWheelBound, false);
			ig.system.canvas.addEventListener('DOMMouseScroll', mouseWheelBound, false);
			ig.system.canvas.addEventListener('contextmenu', this.contextmenu.bind(this), false);
			ig.system.canvas.addEventListener('mousedown', this.keydown.bind(this), false);
			ig.system.canvas.addEventListener('mouseup', this.keyup.bind(this), false);
			ig.system.canvas.addEventListener('mousemove', this.mousemove.bind(this), false);
			ig.system.canvas.addEventListener('touchstart', this.keydown.bind(this), false);
			ig.system.canvas.addEventListener('touchend', this.keyup.bind(this), false);
			ig.system.canvas.addEventListener('touchmove', this.mousemove.bind(this), false);
		},
		initKeyboard: function() {
			if (this.isUsingKeyboard) {
				return;
			}
			this.isUsingKeyboard = true;
			window.addEventListener('keydown', this.keydown.bind(this), false);
			window.addEventListener('keyup', this.keyup.bind(this), false);
		},
		initAccelerometer: function() {
			if (this.isUsingAccelerometer) {
				return;
			}
			window.addEventListener('devicemotion', this.devicemotion.bind(this), false);
		},
		mousewheel: function(event) {
			var delta = event.wheelDelta ? event.wheelDelta : (event.detail * -1);
			var code = delta > 0 ? ig.KEY.MWHEEL_UP : ig.KEY.MWHEEL_DOWN;
			var action = this.bindings[code];
			if (action) {
				this.actions[action] = true;
				this.presses[action] = true;
				this.delayedKeyup[action] = true;
				event.stopPropagation();
				event.preventDefault();
			}
		},
		getEventPosition: function(event) {
			var internalWidth = parseInt(ig.system.canvas.offsetWidth) || ig.system.realWidth;
			var scale = ig.system.scale * (internalWidth / ig.system.realWidth);
			var pos = {
				left: 0,
				top: 0
			};
			if (ig.system.canvas.getBoundingClientRect) {
				pos = ig.system.canvas.getBoundingClientRect();
			}
			return {
				x: (event.clientX - pos.left) / scale,
				y: (event.clientY - pos.top) / scale
			};
		},
		mousemove: function(event) {
			ig.input.mouse = this.getEventPosition(event.touches ? event.touches[0] : event);
		},
		contextmenu: function(event) {
			if (this.bindings[ig.KEY.MOUSE2]) {
				event.stopPropagation();
				event.preventDefault();
			}
		},
		keydown: function(event) {
			var tag = event.target.tagName;
			if (tag == 'INPUT' || tag == 'TEXTAREA') {
				return;
			}
			var code = event.type == 'keydown' ? event.keyCode : (event.button == 2 ? ig.KEY.MOUSE2 : ig.KEY.MOUSE1);
			if (event.type == 'touchstart' || event.type == 'mousedown') {
				this.mousemove(event);
			}
			var action = this.bindings[code];
			if (action) {
				this.actions[action] = true;
				if (!this.locks[action]) {
					this.presses[action] = true;
					this.locks[action] = true;
				}
				event.stopPropagation();
				event.preventDefault();
			}
		},
		keyup: function(event) {
			var tag = event.target.tagName;
			if (tag == 'INPUT' || tag == 'TEXTAREA') {
				return;
			}
			var code = event.type == 'keyup' ? event.keyCode : (event.button == 2 ? ig.KEY.MOUSE2 : ig.KEY.MOUSE1);
			var action = this.bindings[code];
			if (action) {
				this.delayedKeyup[action] = true;
				event.stopPropagation();
				event.preventDefault();
			}
		},
		devicemotion: function(event) {
			this.accel = event.accelerationIncludingGravity;
		},
		bind: function(key, action) {
			if (key < 0) {
				this.initMouse();
			} else if (key > 0) {
				this.initKeyboard();
			}
			this.bindings[key] = action;
		},
		bindTouch: function(selector, action) {
			var element = ig.$(selector);
			var that = this;
			element.addEventListener('touchstart', function(ev) {
				that.touchStart(ev, action);
			}, false);
			element.addEventListener('touchend', function(ev) {
				that.touchEnd(ev, action);
			}, false);
		},
		unbind: function(key) {
			var action = this.bindings[key];
			this.delayedKeyup[action] = true;
			this.bindings[key] = null;
		},
		unbindAll: function() {
			this.bindings = {};
			this.actions = {};
			this.presses = {};
			this.locks = {};
			this.delayedKeyup = {};
		},
		state: function(action) {
			return this.actions[action];
		},
		pressed: function(action) {
			return this.presses[action];
		},
		released: function(action) {
			return this.delayedKeyup[action];
		},
		clearPressed: function() {
			for (var action in this.delayedKeyup) {
				this.actions[action] = false;
				this.locks[action] = false;
			}
			this.delayedKeyup = {};
			this.presses = {};
		},
		touchStart: function(event, action) {
			this.actions[action] = true;
			this.presses[action] = true;
			event.stopPropagation();
			event.preventDefault();
			return false;
		},
		touchEnd: function(event, action) {
			this.delayedKeyup[action] = true;
			event.stopPropagation();
			event.preventDefault();
			return false;
		}
	});
});

// lib/impact/impact.js
ig.baked = true;
ig.module('impact.impact').requires('dom.ready', 'impact.loader', 'impact.system', 'impact.input', 'impact.sound').defines(function() {
	"use strict";
	ig.main = function(canvasId, gameClass, fps, width, height, scale, loaderClass) {
		ig.system = new ig.System(canvasId, fps, width, height, scale || 1);
		ig.input = new ig.Input();
		ig.soundManager = new ig.SoundManager();
		ig.music = new ig.Music();
		ig.ready = true;
		var loader = new(loaderClass || ig.Loader)(gameClass, ig.resources);
		loader.load();
	};
});

// lib/impact/animation.js
ig.baked = true;
ig.module('impact.animation').requires('impact.timer', 'impact.image').defines(function() {
	"use strict";
	ig.AnimationSheet = ig.Class.extend({
		width: 8,
		height: 8,
		image: null,
		init: function(path, width, height) {
			this.width = width;
			this.height = height;
			this.image = new ig.Image(path);
		}
	});
	ig.Animation = ig.Class.extend({
		sheet: null,
		timer: null,
		sequence: [],
		flip: {
			x: false,
			y: false
		},
		pivot: {
			x: 0,
			y: 0
		},
		frame: 0,
		tile: 0,
		loopCount: 0,
		alpha: 1,
		angle: 0,
		init: function(sheet, frameTime, sequence, stop) {
			this.sheet = sheet;
			this.pivot = {
				x: sheet.width / 2,
				y: sheet.height / 2
			};
			this.timer = new ig.Timer();
			this.frameTime = frameTime;
			this.sequence = sequence;
			this.stop = !! stop;
			this.tile = this.sequence[0];
		},
		rewind: function() {
			this.timer.set();
			this.loopCount = 0;
			this.tile = this.sequence[0];
			return this;
		},
		gotoFrame: function(f) {
			this.timer.set(this.frameTime * -f);
			this.update();
		},
		gotoRandomFrame: function() {
			this.gotoFrame(Math.floor(Math.random() * this.sequence.length))
		},
		update: function() {
			var frameTotal = Math.floor(this.timer.delta() / this.frameTime);
			this.loopCount = Math.floor(frameTotal / this.sequence.length);
			if (this.stop && this.loopCount > 0) {
				this.frame = this.sequence.length - 1;
			} else {
				this.frame = frameTotal % this.sequence.length;
			}
			this.tile = this.sequence[this.frame];
		},
		draw: function(targetX, targetY) {
			var bbsize = Math.max(this.sheet.width, this.sheet.height);
			if (targetX > ig.system.width || targetY > ig.system.height || targetX + bbsize < 0 || targetY + bbsize < 0) {
				return;
			}
			if (this.alpha != 1) {
				ig.system.context.globalAlpha = this.alpha;
			}
			if (this.angle == 0) {
				this.sheet.image.drawTile(targetX, targetY, this.tile, this.sheet.width, this.sheet.height, this.flip.x, this.flip.y);
			} else {
				ig.system.context.save();
				ig.system.context.translate(ig.system.getDrawPos(targetX + this.pivot.x), ig.system.getDrawPos(targetY + this.pivot.y));
				ig.system.context.rotate(this.angle);
				this.sheet.image.drawTile(-this.pivot.x, -this.pivot.y, this.tile, this.sheet.width, this.sheet.height, this.flip.x, this.flip.y);
				ig.system.context.restore();
			}
			if (this.alpha != 1) {
				ig.system.context.globalAlpha = 1;
			}
		}
	});
});

// lib/impact/entity.js
ig.baked = true;
ig.module('impact.entity').requires('impact.animation', 'impact.impact').defines(function() {
	"use strict";
	ig.Entity = ig.Class.extend({
		id: 0,
		settings: {},
		size: {
			x: 16,
			y: 16
		},
		offset: {
			x: 0,
			y: 0
		},
		pos: {
			x: 0,
			y: 0
		},
		last: {
			x: 0,
			y: 0
		},
		vel: {
			x: 0,
			y: 0
		},
		accel: {
			x: 0,
			y: 0
		},
		friction: {
			x: 0,
			y: 0
		},
		maxVel: {
			x: 100,
			y: 100
		},
		zIndex: 0,
		gravityFactor: 1,
		standing: false,
		bounciness: 0,
		minBounceVelocity: 40,
		anims: {},
		animSheet: null,
		currentAnim: null,
		health: 10,
		type: 0,
		checkAgainst: 0,
		collides: 0,
		_killed: false,
		slopeStanding: {
			min: (44).toRad(),
			max: (136).toRad()
		},
		init: function(x, y, settings) {
			this.id = ++ig.Entity._lastId;
			this.pos.x = x;
			this.pos.y = y;
			ig.merge(this, settings);
		},
		addAnim: function(name, frameTime, sequence, stop) {
			if (!this.animSheet) {
				throw ('No animSheet to add the animation ' + name + ' to.');
			}
			var a = new ig.Animation(this.animSheet, frameTime, sequence, stop);
			this.anims[name] = a;
			if (!this.currentAnim) {
				this.currentAnim = a;
			}
			return a;
		},
		update: function() {
			this.last.x = this.pos.x;
			this.last.y = this.pos.y;
			this.vel.y += ig.game.gravity * ig.system.tick * this.gravityFactor;
			this.vel.x = this.getNewVelocity(this.vel.x, this.accel.x, this.friction.x, this.maxVel.x);
			this.vel.y = this.getNewVelocity(this.vel.y, this.accel.y, this.friction.y, this.maxVel.y);
			var mx = this.vel.x * ig.system.tick;
			var my = this.vel.y * ig.system.tick;
			var res = ig.game.collisionMap.trace(this.pos.x, this.pos.y, mx, my, this.size.x, this.size.y);
			this.handleMovementTrace(res);
			if (this.currentAnim) {
				this.currentAnim.update();
			}
		},
		getNewVelocity: function(vel, accel, friction, max) {
			if (accel) {
				return (vel + accel * ig.system.tick).limit(-max, max);
			} else if (friction) {
				var delta = friction * ig.system.tick;
				if (vel - delta > 0) {
					return vel - delta;
				} else if (vel + delta < 0) {
					return vel + delta;
				} else {
					return 0;
				}
			}
			return vel.limit(-max, max);
		},
		handleMovementTrace: function(res) {
			this.standing = false;
			if (res.collision.y) {
				if (this.bounciness > 0 && Math.abs(this.vel.y) > this.minBounceVelocity) {
					this.vel.y *= -this.bounciness;
				} else {
					if (this.vel.y > 0) {
						this.standing = true;
					}
					this.vel.y = 0;
				}
			}
			if (res.collision.x) {
				if (this.bounciness > 0 && Math.abs(this.vel.x) > this.minBounceVelocity) {
					this.vel.x *= -this.bounciness;
				} else {
					this.vel.x = 0;
				}
			}
			if (res.collision.slope) {
				var s = res.collision.slope;
				if (this.bounciness > 0) {
					var proj = this.vel.x * s.nx + this.vel.y * s.ny;
					this.vel.x = (this.vel.x - s.nx * proj * 2) * this.bounciness;
					this.vel.y = (this.vel.y - s.ny * proj * 2) * this.bounciness;
				} else {
					var lengthSquared = s.x * s.x + s.y * s.y;
					var dot = (this.vel.x * s.x + this.vel.y * s.y) / lengthSquared;
					this.vel.x = s.x * dot;
					this.vel.y = s.y * dot;
					var angle = Math.atan2(s.x, s.y);
					if (angle > this.slopeStanding.min && angle < this.slopeStanding.max) {
						this.standing = true;
					}
				}
			}
			this.pos = res.pos;
		},
		draw: function() {
			if (this.currentAnim) {
				this.currentAnim.draw(this.pos.x - this.offset.x - ig.game._rscreen.x, this.pos.y - this.offset.y - ig.game._rscreen.y);
			}
		},
		kill: function() {
			ig.game.removeEntity(this);
		},
		receiveDamage: function(amount, from) {
			this.health -= amount;
			if (this.health <= 0) {
				this.kill();
			}
		},
		touches: function(other) {
			return !(this.pos.x >= other.pos.x + other.size.x || this.pos.x + this.size.x <= other.pos.x || this.pos.y >= other.pos.y + other.size.y || this.pos.y + this.size.y <= other.pos.y);
		},
		distanceTo: function(other) {
			var xd = (this.pos.x + this.size.x / 2) - (other.pos.x + other.size.x / 2);
			var yd = (this.pos.y + this.size.y / 2) - (other.pos.y + other.size.y / 2);
			return Math.sqrt(xd * xd + yd * yd);
		},
		angleTo: function(other) {
			return Math.atan2((other.pos.y + other.size.y / 2) - (this.pos.y + this.size.y / 2), (other.pos.x + other.size.x / 2) - (this.pos.x + this.size.x / 2));
		},
		check: function(other) {},
		collideWith: function(other, axis) {},
		ready: function() {}
	});
	ig.Entity._lastId = 0;
	ig.Entity.COLLIDES = {
		NEVER: 0,
		LITE: 1,
		PASSIVE: 2,
		ACTIVE: 4,
		FIXED: 8
	};
	ig.Entity.TYPE = {
		NONE: 0,
		A: 1,
		B: 2,
		BOTH: 3
	};
	ig.Entity.checkPair = function(a, b) {
		if (a.checkAgainst & b.type) {
			a.check(b);
		}
		if (b.checkAgainst & a.type) {
			b.check(a);
		}
		if (a.collides && b.collides && a.collides + b.collides > ig.Entity.COLLIDES.ACTIVE) {
			ig.Entity.solveCollision(a, b);
		}
	};
	ig.Entity.solveCollision = function(a, b) {
		var weak = null;
		if (a.collides == ig.Entity.COLLIDES.LITE || b.collides == ig.Entity.COLLIDES.FIXED) {
			weak = a;
		} else if (b.collides == ig.Entity.COLLIDES.LITE || a.collides == ig.Entity.COLLIDES.FIXED) {
			weak = b;
		}
		if (a.last.x + a.size.x > b.last.x && a.last.x < b.last.x + b.size.x) {
			if (a.last.y < b.last.y) {
				ig.Entity.seperateOnYAxis(a, b, weak);
			} else {
				ig.Entity.seperateOnYAxis(b, a, weak);
			}
			a.collideWith(b, 'y');
			b.collideWith(a, 'y');
		} else if (a.last.y + a.size.y > b.last.y && a.last.y < b.last.y + b.size.y) {
			if (a.last.x < b.last.x) {
				ig.Entity.seperateOnXAxis(a, b, weak);
			} else {
				ig.Entity.seperateOnXAxis(b, a, weak);
			}
			a.collideWith(b, 'x');
			b.collideWith(a, 'x');
		}
	};
	ig.Entity.seperateOnXAxis = function(left, right, weak) {
		var nudge = (left.pos.x + left.size.x - right.pos.x);
		if (weak) {
			var strong = left === weak ? right : left;
			weak.vel.x = -weak.vel.x * weak.bounciness + strong.vel.x;
			var resWeak = ig.game.collisionMap.trace(weak.pos.x, weak.pos.y, weak == left ? -nudge : nudge, 0, weak.size.x, weak.size.y);
			weak.pos.x = resWeak.pos.x;
		} else {
			var v2 = (left.vel.x - right.vel.x) / 2;
			left.vel.x = -v2;
			right.vel.x = v2;
			var resLeft = ig.game.collisionMap.trace(left.pos.x, left.pos.y, -nudge / 2, 0, left.size.x, left.size.y);
			left.pos.x = Math.floor(resLeft.pos.x);
			var resRight = ig.game.collisionMap.trace(right.pos.x, right.pos.y, nudge / 2, 0, right.size.x, right.size.y);
			right.pos.x = Math.ceil(resRight.pos.x);
		}
	};
	ig.Entity.seperateOnYAxis = function(top, bottom, weak) {
		var nudge = (top.pos.y + top.size.y - bottom.pos.y);
		if (weak) {
			var strong = top === weak ? bottom : top;
			weak.vel.y = -weak.vel.y * weak.bounciness + strong.vel.y;
			var nudgeX = 0;
			if (weak == top && Math.abs(weak.vel.y - strong.vel.y) < weak.minBounceVelocity) {
				weak.standing = true;
				nudgeX = strong.vel.x * ig.system.tick;
			}
			var resWeak = ig.game.collisionMap.trace(weak.pos.x, weak.pos.y, nudgeX, weak == top ? -nudge : nudge, weak.size.x, weak.size.y);
			weak.pos.y = resWeak.pos.y;
			weak.pos.x = resWeak.pos.x;
		} else if (ig.game.gravity && (bottom.standing || top.vel.y > 0)) {
			var resTop = ig.game.collisionMap.trace(top.pos.x, top.pos.y, 0, -(top.pos.y + top.size.y - bottom.pos.y), top.size.x, top.size.y);
			top.pos.y = resTop.pos.y;
			if (top.bounciness > 0 && top.vel.y > top.minBounceVelocity) {
				top.vel.y *= -top.bounciness;
			} else {
				top.standing = true;
				top.vel.y = 0;
			}
		} else {
			var v2 = (top.vel.y - bottom.vel.y) / 2;
			top.vel.y = -v2;
			bottom.vel.y = v2;
			var nudgeX = bottom.vel.x * ig.system.tick;
			var resTop = ig.game.collisionMap.trace(top.pos.x, top.pos.y, nudgeX, -nudge / 2, top.size.x, top.size.y);
			top.pos.y = resTop.pos.y;
			var resBottom = ig.game.collisionMap.trace(bottom.pos.x, bottom.pos.y, 0, nudge / 2, bottom.size.x, bottom.size.y);
			bottom.pos.y = resBottom.pos.y;
		}
	};
});

// lib/impact/map.js
ig.baked = true;
ig.module('impact.map').defines(function() {
	"use strict";
	ig.Map = ig.Class.extend({
		tilesize: 8,
		width: 1,
		height: 1,
		data: [
			[]
		],
		name: null,
		init: function(tilesize, data) {
			this.tilesize = tilesize;
			this.data = data;
			this.height = data.length;
			this.width = data[0].length;
		},
		getTile: function(x, y) {
			var tx = Math.floor(x / this.tilesize);
			var ty = Math.floor(y / this.tilesize);
			if ((tx >= 0 && tx < this.width) && (ty >= 0 && ty < this.height)) {
				return this.data[ty][tx];
			} else {
				return 0;
			}
		},
		setTile: function(x, y, tile) {
			var tx = Math.floor(x / this.tilesize);
			var ty = Math.floor(y / this.tilesize);
			if ((tx >= 0 && tx < this.width) && (ty >= 0 && ty < this.height)) {
				this.data[ty][tx] = tile;
			}
		}
	});
});

// lib/impact/collision-map.js
ig.baked = true;
ig.module('impact.collision-map').requires('impact.map').defines(function() {
	"use strict";
	ig.CollisionMap = ig.Map.extend({
		lastSlope: 1,
		tiledef: null,
		init: function(tilesize, data, tiledef) {
			this.parent(tilesize, data);
			this.tiledef = tiledef || ig.CollisionMap.defaultTileDef;
			for (var t in this.tiledef) {
				if (t | 0 > this.lastSlope) {
					this.lastSlope = t | 0;
				}
			}
		},
		trace: function(x, y, vx, vy, objectWidth, objectHeight) {
			var res = {
				collision: {
					x: false,
					y: false,
					slope: false
				},
				pos: {
					x: x,
					y: y
				},
				tile: {
					x: 0,
					y: 0
				}
			};
			var steps = Math.ceil(Math.max(Math.abs(vx), Math.abs(vy)) / this.tilesize);
			if (steps > 1) {
				var sx = vx / steps;
				var sy = vy / steps;
				for (var i = 0; i < steps && (sx || sy); i++) {
					this._traceStep(res, x, y, sx, sy, objectWidth, objectHeight, vx, vy, i);
					x = res.pos.x;
					y = res.pos.y;
					if (res.collision.x) {
						sx = 0;
						vx = 0;
					}
					if (res.collision.y) {
						sy = 0;
						vy = 0;
					}
					if (res.collision.slope) {
						break;
					}
				}
			} else {
				this._traceStep(res, x, y, vx, vy, objectWidth, objectHeight, vx, vy, 0);
			}
			return res;
		},
		_traceStep: function(res, x, y, vx, vy, width, height, rvx, rvy, step) {
			res.pos.x += vx;
			res.pos.y += vy;
			var t = 0;
			if (vx) {
				var pxOffsetX = (vx > 0 ? width : 0);
				var tileOffsetX = (vx < 0 ? this.tilesize : 0);
				var firstTileY = Math.max(Math.floor(y / this.tilesize), 0);
				var lastTileY = Math.min(Math.ceil((y + height) / this.tilesize), this.height);
				var tileX = Math.floor((res.pos.x + pxOffsetX) / this.tilesize);
				var prevTileX = Math.floor((x + pxOffsetX) / this.tilesize);
				if (step > 0 || tileX == prevTileX || prevTileX < 0 || prevTileX >= this.width) {
					prevTileX = -1;
				}
				if (tileX >= 0 && tileX < this.width) {
					for (var tileY = firstTileY; tileY < lastTileY; tileY++) {
						if (prevTileX != -1) {
							t = this.data[tileY][prevTileX];
							if (t > 1 && t <= this.lastSlope && this._checkTileDef(res, t, x, y, rvx, rvy, width, height, prevTileX, tileY)) {
								break;
							}
						}
						t = this.data[tileY][tileX];
						if (t == 1 || t > this.lastSlope || (t > 1 && this._checkTileDef(res, t, x, y, rvx, rvy, width, height, tileX, tileY))) {
							if (t > 1 && t <= this.lastSlope && res.collision.slope) {
								break;
							}
							res.collision.x = true;
							res.tile.x = t;
							x = res.pos.x = tileX * this.tilesize - pxOffsetX + tileOffsetX;
							rvx = 0;
							break;
						}
					}
				}
			}
			if (vy) {
				var pxOffsetY = (vy > 0 ? height : 0);
				var tileOffsetY = (vy < 0 ? this.tilesize : 0);
				var firstTileX = Math.max(Math.floor(res.pos.x / this.tilesize), 0);
				var lastTileX = Math.min(Math.ceil((res.pos.x + width) / this.tilesize), this.width);
				var tileY = Math.floor((res.pos.y + pxOffsetY) / this.tilesize);
				var prevTileY = Math.floor((y + pxOffsetY) / this.tilesize);
				if (step > 0 || tileY == prevTileY || prevTileY < 0 || prevTileY >= this.height) {
					prevTileY = -1;
				}
				if (tileY >= 0 && tileY < this.height) {
					for (var tileX = firstTileX; tileX < lastTileX; tileX++) {
						if (prevTileY != -1) {
							t = this.data[prevTileY][tileX];
							if (t > 1 && t <= this.lastSlope && this._checkTileDef(res, t, x, y, rvx, rvy, width, height, tileX, prevTileY)) {
								break;
							}
						}
						t = this.data[tileY][tileX];
						if (t == 1 || t > this.lastSlope || (t > 1 && this._checkTileDef(res, t, x, y, rvx, rvy, width, height, tileX, tileY))) {
							if (t > 1 && t <= this.lastSlope && res.collision.slope) {
								break;
							}
							res.collision.y = true;
							res.tile.y = t;
							res.pos.y = tileY * this.tilesize - pxOffsetY + tileOffsetY;
							break;
						}
					}
				}
			}
		},
		_checkTileDef: function(res, t, x, y, vx, vy, width, height, tileX, tileY) {
			var def = this.tiledef[t];
			if (!def) {
				return false;
			}
			var lx = (tileX + def[0]) * this.tilesize,
				ly = (tileY + def[1]) * this.tilesize,
				lvx = (def[2] - def[0]) * this.tilesize,
				lvy = (def[3] - def[1]) * this.tilesize,
				solid = def[4];
			var tx = x + vx + (lvy < 0 ? width : 0) - lx,
				ty = y + vy + (lvx > 0 ? height : 0) - ly;
			if (lvx * ty - lvy * tx > 0) {
				if (vx * -lvy + vy * lvx < 0) {
					return solid;
				}
				var length = Math.sqrt(lvx * lvx + lvy * lvy);
				var nx = lvy / length,
					ny = -lvx / length;
				var proj = tx * nx + ty * ny;
				var px = nx * proj,
					py = ny * proj;
				if (px * px + py * py >= vx * vx + vy * vy) {
					return solid || (lvx * (ty - vy) - lvy * (tx - vx) < 0.5);
				}
				res.pos.x = x + vx - px;
				res.pos.y = y + vy - py;
				res.collision.slope = {
					x: lvx,
					y: lvy,
					nx: nx,
					ny: ny
				};
				return true;
			}
			return false;
		}
	});
	var H = 1 / 2,
		N = 1 / 3,
		M = 2 / 3,
		SOLID = true,
		NON_SOLID = false;
	ig.CollisionMap.defaultTileDef = {
		5: [0, 1, 1, M, SOLID],
		6: [0, M, 1, N, SOLID],
		7: [0, N, 1, 0, SOLID],
		3: [0, 1, 1, H, SOLID],
		4: [0, H, 1, 0, SOLID],
		2: [0, 1, 1, 0, SOLID],
		10: [H, 1, 1, 0, SOLID],
		21: [0, 1, H, 0, SOLID],
		32: [M, 1, 1, 0, SOLID],
		43: [N, 1, M, 0, SOLID],
		54: [0, 1, N, 0, SOLID],
		27: [0, 0, 1, N, SOLID],
		28: [0, N, 1, M, SOLID],
		29: [0, M, 1, 1, SOLID],
		25: [0, 0, 1, H, SOLID],
		26: [0, H, 1, 1, SOLID],
		24: [0, 0, 1, 1, SOLID],
		11: [0, 0, H, 1, SOLID],
		22: [H, 0, 1, 1, SOLID],
		33: [0, 0, N, 1, SOLID],
		44: [N, 0, M, 1, SOLID],
		55: [M, 0, 1, 1, SOLID],
		16: [1, N, 0, 0, SOLID],
		17: [1, M, 0, N, SOLID],
		18: [1, 1, 0, M, SOLID],
		14: [1, H, 0, 0, SOLID],
		15: [1, 1, 0, H, SOLID],
		13: [1, 1, 0, 0, SOLID],
		8: [H, 1, 0, 0, SOLID],
		19: [1, 1, H, 0, SOLID],
		30: [N, 1, 0, 0, SOLID],
		41: [M, 1, N, 0, SOLID],
		52: [1, 1, M, 0, SOLID],
		38: [1, M, 0, 1, SOLID],
		39: [1, N, 0, M, SOLID],
		40: [1, 0, 0, N, SOLID],
		36: [1, H, 0, 1, SOLID],
		37: [1, 0, 0, H, SOLID],
		35: [1, 0, 0, 1, SOLID],
		9: [1, 0, H, 1, SOLID],
		20: [H, 0, 0, 1, SOLID],
		31: [1, 0, M, 1, SOLID],
		42: [M, 0, N, 1, SOLID],
		53: [N, 0, 0, 1, SOLID],
		12: [0, 0, 1, 0, NON_SOLID],
		23: [1, 1, 0, 1, NON_SOLID],
		34: [1, 0, 1, 1, NON_SOLID],
		45: [0, 1, 0, 0, NON_SOLID]
	};
	ig.CollisionMap.staticNoCollision = {
		trace: function(x, y, vx, vy) {
			return {
				collision: {
					x: false,
					y: false,
					slope: false
				},
				pos: {
					x: x + vx,
					y: y + vy
				},
				tile: {
					x: 0,
					y: 0
				}
			};
		}
	};
});

// lib/impact/background-map.js
ig.baked = true;
ig.module('impact.background-map').requires('impact.map', 'impact.image').defines(function() {
	"use strict";
	ig.BackgroundMap = ig.Map.extend({
		tiles: null,
		scroll: {
			x: 0,
			y: 0
		},
		distance: 1,
		repeat: false,
		tilesetName: '',
		foreground: false,
		enabled: true,
		preRender: false,
		preRenderedChunks: null,
		chunkSize: 512,
		debugChunks: false,
		anims: {},
		init: function(tilesize, data, tileset) {
			this.parent(tilesize, data);
			this.setTileset(tileset);
		},
		setTileset: function(tileset) {
			this.tilesetName = tileset instanceof ig.Image ? tileset.path : tileset;
			this.tiles = new ig.Image(this.tilesetName);
			this.preRenderedChunks = null;
		},
		setScreenPos: function(x, y) {
			this.scroll.x = x / this.distance;
			this.scroll.y = y / this.distance;
		},
		preRenderMapToChunks: function() {
			var totalWidth = this.width * this.tilesize * ig.system.scale,
				totalHeight = this.height * this.tilesize * ig.system.scale;
			var chunkCols = Math.ceil(totalWidth / this.chunkSize),
				chunkRows = Math.ceil(totalHeight / this.chunkSize);
			this.preRenderedChunks = [];
			for (var y = 0; y < chunkRows; y++) {
				this.preRenderedChunks[y] = [];
				for (var x = 0; x < chunkCols; x++) {
					var chunkWidth = (x == chunkCols - 1) ? totalWidth - x * this.chunkSize : this.chunkSize;
					var chunkHeight = (y == chunkRows - 1) ? totalHeight - y * this.chunkSize : this.chunkSize;
					this.preRenderedChunks[y][x] = this.preRenderChunk(x, y, chunkWidth, chunkHeight);
				}
			}
		},
		preRenderChunk: function(cx, cy, w, h) {
			var tw = w / this.tilesize / ig.system.scale + 1,
				th = h / this.tilesize / ig.system.scale + 1;
			var nx = (cx * this.chunkSize / ig.system.scale) % this.tilesize,
				ny = (cy * this.chunkSize / ig.system.scale) % this.tilesize;
			var tx = Math.floor(cx * this.chunkSize / this.tilesize / ig.system.scale),
				ty = Math.floor(cy * this.chunkSize / this.tilesize / ig.system.scale);
			var chunk = ig.$new('canvas');
			chunk.width = w;
			chunk.height = h;
			var oldContext = ig.system.context;
			ig.system.context = chunk.getContext("2d");
			for (var x = 0; x < tw; x++) {
				for (var y = 0; y < th; y++) {
					if (x + tx < this.width && y + ty < this.height) {
						var tile = this.data[y + ty][x + tx];
						if (tile) {
							this.tiles.drawTile(x * this.tilesize - nx, y * this.tilesize - ny, tile - 1, this.tilesize);
						}
					}
				}
			}
			ig.system.context = oldContext;
			return chunk;
		},
		draw: function() {
			if (!this.tiles.loaded || !this.enabled) {
				return;
			}
			if (this.preRender) {
				this.drawPreRendered();
			} else {
				this.drawTiled();
			}
		},
		drawPreRendered: function() {
			if (!this.preRenderedChunks) {
				this.preRenderMapToChunks();
			}
			var dx = ig.system.getDrawPos(this.scroll.x),
				dy = ig.system.getDrawPos(this.scroll.y);
			if (this.repeat) {
				var w = this.width * this.tilesize * ig.system.scale;
				dx = (dx % w + w) % w;
				var h = this.height * this.tilesize * ig.system.scale;
				dy = (dy % h + h) % h;
			}
			var minChunkX = Math.max(Math.floor(dx / this.chunkSize), 0),
				minChunkY = Math.max(Math.floor(dy / this.chunkSize), 0),
				maxChunkX = Math.ceil((dx + ig.system.realWidth) / this.chunkSize),
				maxChunkY = Math.ceil((dy + ig.system.realHeight) / this.chunkSize),
				maxRealChunkX = this.preRenderedChunks[0].length,
				maxRealChunkY = this.preRenderedChunks.length;
			if (!this.repeat) {
				maxChunkX = Math.min(maxChunkX, maxRealChunkX);
				maxChunkY = Math.min(maxChunkY, maxRealChunkY);
			}
			var nudgeY = 0;
			for (var cy = minChunkY; cy < maxChunkY; cy++) {
				var nudgeX = 0;
				for (var cx = minChunkX; cx < maxChunkX; cx++) {
					var chunk = this.preRenderedChunks[cy % maxRealChunkY][cx % maxRealChunkX];
					var x = -dx + cx * this.chunkSize - nudgeX;
					var y = -dy + cy * this.chunkSize - nudgeY;
					ig.system.context.drawImage(chunk, x, y);
					ig.Image.drawCount++;
					if (this.debugChunks) {
						ig.system.context.strokeStyle = '#f0f';
						ig.system.context.strokeRect(x, y, this.chunkSize, this.chunkSize);
					}
					if (this.repeat && chunk.width < this.chunkSize && x + chunk.width < ig.system.realWidth) {
						nudgeX = this.chunkSize - chunk.width;
						maxChunkX++;
					}
				}
				if (this.repeat && chunk.height < this.chunkSize && y + chunk.height < ig.system.realHeight) {
					nudgeY = this.chunkSize - chunk.height;
					maxChunkY++;
				}
			}
		},
		drawTiled: function() {
			var tile = 0,
				anim = null,
				tileOffsetX = (this.scroll.x / this.tilesize).toInt(),
				tileOffsetY = (this.scroll.y / this.tilesize).toInt(),
				pxOffsetX = this.scroll.x % this.tilesize,
				pxOffsetY = this.scroll.y % this.tilesize,
				pxMinX = -pxOffsetX - this.tilesize,
				pxMinY = -pxOffsetY - this.tilesize,
				pxMaxX = ig.system.width + this.tilesize - pxOffsetX,
				pxMaxY = ig.system.height + this.tilesize - pxOffsetY;
			for (var mapY = -1, pxY = pxMinY; pxY < pxMaxY; mapY++, pxY += this.tilesize) {
				var tileY = mapY + tileOffsetY;
				if (tileY >= this.height || tileY < 0) {
					if (!this.repeat) {
						continue;
					}
					tileY = (tileY % this.height + this.height) % this.height;
				}
				for (var mapX = -1, pxX = pxMinX; pxX < pxMaxX; mapX++, pxX += this.tilesize) {
					var tileX = mapX + tileOffsetX;
					if (tileX >= this.width || tileX < 0) {
						if (!this.repeat) {
							continue;
						}
						tileX = (tileX % this.width + this.width) % this.width;
					}
					if ((tile = this.data[tileY][tileX])) {
						if ((anim = this.anims[tile - 1])) {
							anim.draw(pxX, pxY);
						} else {
							this.tiles.drawTile(pxX, pxY, tile - 1, this.tilesize);
						}
					}
				}
			}
		}
	});
});

// lib/impact/game.js
ig.baked = true;
ig.module('impact.game').requires('impact.impact', 'impact.entity', 'impact.collision-map', 'impact.background-map').defines(function() {
	"use strict";
	ig.Game = ig.Class.extend({
		clearColor: '#000000',
		gravity: 0,
		screen: {
			x: 0,
			y: 0
		},
		_rscreen: {
			x: 0,
			y: 0
		},
		entities: [],
		namedEntities: {},
		collisionMap: ig.CollisionMap.staticNoCollision,
		backgroundMaps: [],
		backgroundAnims: {},
		autoSort: false,
		sortBy: null,
		cellSize: 64,
		_deferredKill: [],
		_levelToLoad: null,
		_doSortEntities: false,
		staticInstantiate: function() {
			this.sortBy = this.sortBy || ig.Game.SORT.Z_INDEX;
			ig.game = this;
			return null;
		},
		loadLevel: function(data) {
			this.screen = {
				x: 0,
				y: 0
			};
			this.entities = [];
			this.namedEntities = {};
			for (var i = 0; i < data.entities.length; i++) {
				var ent = data.entities[i];
				this.spawnEntity(ent.type, ent.x, ent.y, ent.settings);
			}
			this.sortEntities();
			this.collisionMap = ig.CollisionMap.staticNoCollision;
			this.backgroundMaps = [];
			for (var i = 0; i < data.layer.length; i++) {
				var ld = data.layer[i];
				if (ld.name == 'collision') {
					this.collisionMap = new ig.CollisionMap(ld.tilesize, ld.data);
				} else {
					var newMap = new ig.BackgroundMap(ld.tilesize, ld.data, ld.tilesetName);
					newMap.anims = this.backgroundAnims[ld.tilesetName] || {};
					newMap.repeat = ld.repeat;
					newMap.distance = ld.distance;
					newMap.foreground = !! ld.foreground;
					newMap.preRender = !! ld.preRender;
					newMap.name = ld.name;
					this.backgroundMaps.push(newMap);
				}
			}
			for (var i = 0; i < this.entities.length; i++) {
				this.entities[i].ready();
			}
		},
		loadLevelDeferred: function(data) {
			this._levelToLoad = data;
		},
		getMapByName: function(name) {
			if (name == 'collision') {
				return this.collisionMap;
			}
			for (var i = 0; i < this.backgroundMaps.length; i++) {
				if (this.backgroundMaps[i].name == name) {
					return this.backgroundMaps[i];
				}
			}
			return null;
		},
		getEntityByName: function(name) {
			return this.namedEntities[name];
		},
		getEntitiesByType: function(type) {
			var entityClass = typeof(type) === 'string' ? ig.global[type] : type;
			var a = [];
			for (var i = 0; i < this.entities.length; i++) {
				var ent = this.entities[i];
				if (ent instanceof entityClass && !ent._killed) {
					a.push(ent);
				}
			}
			return a;
		},
		spawnEntity: function(type, x, y, settings) {
			var entityClass = typeof(type) === 'string' ? ig.global[type] : type;
			if (!entityClass) {
				throw ("Can't spawn entity of type " + type);
			}
			var ent = new(entityClass)(x, y, settings || {});
			this.entities.push(ent);
			if (ent.name) {
				this.namedEntities[ent.name] = ent;
			}
			return ent;
		},
		sortEntities: function() {
			this.entities.sort(this.sortBy);
		},
		sortEntitiesDeferred: function() {
			this._doSortEntities = true;
		},
		removeEntity: function(ent) {
			if (ent.name) {
				delete this.namedEntities[ent.name];
			}
			ent._killed = true;
			ent.type = ig.Entity.TYPE.NONE;
			ent.checkAgainst = ig.Entity.TYPE.NONE;
			ent.collides = ig.Entity.COLLIDES.NEVER;
			this._deferredKill.push(ent);
		},
		run: function() {
			this.update();
			this.draw();
		},
		update: function() {
			if (this._levelToLoad) {
				this.loadLevel(this._levelToLoad);
				this._levelToLoad = null;
			}
			if (this._doSortEntities || this.autoSort) {
				this.sortEntities();
				this._doSortEntities = false;
			}
			this.updateEntities();
			this.checkEntities();
			for (var i = 0; i < this._deferredKill.length; i++) {
				this.entities.erase(this._deferredKill[i]);
			}
			this._deferredKill = [];
			for (var tileset in this.backgroundAnims) {
				var anims = this.backgroundAnims[tileset];
				for (var a in anims) {
					anims[a].update();
				}
			}
		},
		updateEntities: function() {
			for (var i = 0; i < this.entities.length; i++) {
				var ent = this.entities[i];
				if (!ent._killed) {
					ent.update();
				}
			}
		},
		draw: function() {
			if (this.clearColor) {
				ig.system.clear(this.clearColor);
			}
			this._rscreen.x = ig.system.getDrawPos(this.screen.x) / ig.system.scale;
			this._rscreen.y = ig.system.getDrawPos(this.screen.y) / ig.system.scale;
			var mapIndex;
			for (mapIndex = 0; mapIndex < this.backgroundMaps.length; mapIndex++) {
				var map = this.backgroundMaps[mapIndex];
				if (map.foreground) {
					break;
				}
				map.setScreenPos(this.screen.x, this.screen.y);
				map.draw();
			}
			this.drawEntities();
			for (mapIndex; mapIndex < this.backgroundMaps.length; mapIndex++) {
				var map = this.backgroundMaps[mapIndex];
				map.setScreenPos(this.screen.x, this.screen.y);
				map.draw();
			}
		},
		drawEntities: function() {
			for (var i = 0; i < this.entities.length; i++) {
				this.entities[i].draw();
			}
		},
		checkEntities: function() {
			var hash = {};
			for (var e = 0; e < this.entities.length; e++) {
				var entity = this.entities[e];
				if (entity.type == ig.Entity.TYPE.NONE && entity.checkAgainst == ig.Entity.TYPE.NONE && entity.collides == ig.Entity.COLLIDES.NEVER) {
					continue;
				}
				var checked = {},
					xmin = Math.floor(entity.pos.x / this.cellSize),
					ymin = Math.floor(entity.pos.y / this.cellSize),
					xmax = Math.floor((entity.pos.x + entity.size.x) / this.cellSize) + 1,
					ymax = Math.floor((entity.pos.y + entity.size.y) / this.cellSize) + 1;
				for (var x = xmin; x < xmax; x++) {
					for (var y = ymin; y < ymax; y++) {
						if (!hash[x]) {
							hash[x] = {};
							hash[x][y] = [entity];
						} else if (!hash[x][y]) {
							hash[x][y] = [entity];
						} else {
							var cell = hash[x][y];
							for (var c = 0; c < cell.length; c++) {
								if (entity.touches(cell[c]) && !checked[cell[c].id]) {
									checked[cell[c].id] = true;
									ig.Entity.checkPair(entity, cell[c]);
								}
							}
							cell.push(entity);
						}
					}
				}
			}
		}
	});
	ig.Game.SORT = {
		Z_INDEX: function(a, b) {
			return a.zIndex - b.zIndex;
		},
		POS_X: function(a, b) {
			return (a.pos.x + a.size.x) - (b.pos.x + b.size.x);
		},
		POS_Y: function(a, b) {
			return (a.pos.y + a.size.y) - (b.pos.y + b.size.y);
		}
	};
});

// lib/plugins/impact-splash-loader.js
ig.baked = true;
ig.module('plugins.impact-splash-loader').requires('impact.loader').defines(function() {
	ig.ImpactSplashLoader = ig.Loader.extend({
		endTime: 0,
		fadeToWhiteTime: 200,
		fadeToGameTime: 800,
		logoWidth: 340,
		logoHeight: 120,
		init: function(gameClass, resources) {
			this.logo = new Image();
			this.logo.src = 'media/impact.png';
			this.parent(gameClass, resources);
		},
		end: function() {
			this.parent();
			this.endTime = Date.now();
			ig.system.setDelegate(this);
		},
		run: function() {
			var t = Date.now() - this.endTime;
			var alpha = 1;
			if (t < this.fadeToWhiteTime) {
				this.draw();
				alpha = t.map(0, this.fadeToWhiteTime, 0, 1);
			} else if (t < this.fadeToGameTime) {
				ig.game.run();
				alpha = t.map(this.fadeToWhiteTime, this.fadeToGameTime, 1, 0);
			} else {
				ig.system.setDelegate(ig.game);
				return;
			}
			ig.system.context.fillStyle = 'rgba(255,255,255,' + alpha + ')';
			ig.system.context.fillRect(0, 0, ig.system.realWidth, ig.system.realHeight);
		},
		draw: function() {
			this._drawStatus += (this.status - this._drawStatus) / 5;
			var ctx = ig.system.context;
			var w = ig.system.realWidth;
			var h = ig.system.realHeight;
			var scale = w / this.logoWidth / 3;
			var center = (w - this.logoWidth * scale) / 2;
			ctx.fillStyle = 'rgba(0,0,0,0.8)';
			ctx.fillRect(0, 0, w, h);
			ctx.save();
			ctx.translate(center, h / 2.5);
			ctx.scale(scale, scale);
			ctx.lineWidth = '3';
			ctx.strokeStyle = 'rgb(255,255,255)';
			ctx.strokeRect(25, this.logoHeight + 40, 300, 20);
			ctx.fillStyle = 'rgb(255,255,255)';
			ctx.fillRect(30, this.logoHeight + 45, 290 * this._drawStatus, 10);
			if (this.logo.width) {
				ctx.drawImage(this.logo, 0, 0);
			}
			ctx.restore();
		}
	});
});

// lib/game/entities/particle.js
ig.baked = true;
ig.module('game.entities.particle').requires('impact.entity').defines(function() {
	"use strict";
	window.EntityParticles = ig.Class.extend({
		type: ig.Entity.TYPE.NONE,
		checkAgainst: ig.Entity.TYPE.NONE,
		collides: ig.Entity.COLLIDES.NEVER,
		lifetime: 5,
		fadetime: 1,
		_vel: null,
		_pos: null,
		vel: {
			x: 0,
			y: 0
		},
		image: null,
		alpha: 1,
		count: 10,
		init: function(x, y, settings) {
			this.count = settings.count || this.count;
			var l = this.count * 2;
			x -= this.image.width / 2;
			y -= this.image.height / 2;
			this._vel = Array(l);
			this._pos = Array(l);
			for (var i = 0; i < l; i += 2) {
				this._vel[i] = (Math.random() * 2 - 1) * this.vel.x;
				this._vel[i + 1] = (Math.random() * 2 - 1) * this.vel.y;
				this._pos[i] = x;
				this._pos[i + 1] = y;
			}
			this.idleTimer = new ig.Timer();
		},
		update: function() {
			if (this.idleTimer.delta() > this.lifetime) {
				ig.game.removeEntity(this);
				return;
			}
			this.alpha = this.idleTimer.delta().map(this.lifetime - this.fadetime, this.lifetime, 1, 0);
		},
		draw: function() {
			var l = this.count * 2;
			var p = this._pos,
				v = this._vel,
				t = ig.system.tick,
				ctx = ig.system.context,
				img = this.image.data,
				sx = ig.game._rscreen.x,
				sy = ig.game._rscreen.y;
			ig.system.context.globalAlpha = this.alpha;
			for (var i = 0; i < l; i += 2) {
				p[i] += v[i] * t;
				p[i + 1] += v[i + 1] * t;
				ctx.drawImage(img, p[i] + sx, p[i + 1] + sy);
			}
			ig.system.context.globalAlpha = 1;
		}
	});
});

// lib/game/entities/crosshair.js
ig.baked = true;
ig.module('game.entities.crosshair').requires('impact.entity').defines(function() {
	"use strict";
	window.EntityCrosshair = ig.Entity.extend({
		animSheet: new ig.AnimationSheet('media/sprites/crosshair.png', 18, 18),
		size: {
			x: 2,
			y: 2
		},
		offset: {
			x: 8,
			y: 8
		},
		type: ig.Entity.TYPE.NONE,
		init: function(x, y, settings) {
			this.parent(x, y, settings);
			this.addAnim('idle', 60, [0]);
		},
		update: function() {
			this.pos.x = ig.input.mouse.x;
			this.pos.y = ig.input.mouse.y;
			this.currentAnim.angle -= 3 * ig.system.tick;
		}
	});
});

// lib/game/entities/player.js
ig.baked = true;
ig.module('game.entities.player').requires('impact.entity', 'game.entities.particle', 'game.entities.crosshair').defines(function() {
	"use strict";
	window.EntityPlayer = ig.Entity.extend({
		animSheet: new ig.AnimationSheet('media/sprites/ship.png', 24, 24),
		shieldAnimSheet: new ig.AnimationSheet('media/sprites/shield.png', 48, 48),
		size: {
			x: 2,
			y: 2
		},
		offset: {
			x: 11,
			y: 11
		},
		angle: -Math.PI / 2,
		targetAngle: -Math.PI / 2,
		xfriction: {
			x: 800,
			y: 800
		},
		maxVel: {
			x: 300,
			y: 300
		},
		speed: 110,
		soundShoot: new ig.Sound('media/sounds/plasma-burst.ogg'),
		soundExplode: new ig.Sound('media/sounds/explosion.ogg'),
		type: ig.Entity.TYPE.A,
		init: function(x, y, settings) {
			this.parent(x, y, settings);
			this.addAnim('idle', 60, [0]);
			this.addAnim('shoot', 0.05, [3, 2, 1, 0], true);
			this.shield = new ig.Animation(this.shieldAnimSheet, 1, [0]);
			this.shieldTimer = new ig.Timer(2);
			this.lastShootTimer = new ig.Timer(0);
			this.crosshair = ig.game.crosshair;
			this.soundShoot.volume = 0.7;
			ig.game.player = this;
		},
		draw: function() {
			this.parent();
			if (this.shieldTimer) {
				this.shield.alpha = this.shieldTimer.delta().map(-0.5, 0, 0.5, 0).limit(0, 0.5);
				this.shield.draw(this.pos.x - 24 - ig.game._rscreen.x, this.pos.y - 24 - ig.game._rscreen.y);
			}
		},
		update: function() {
			if (this.shieldTimer) {
				var d = this.shieldTimer.delta();
				if (d > 0) {
					this.shieldTimer = null;
				} else if (d < -1) {
					this.vel.y = d.map(-2, -1, -200, 0);
					this.parent();
					return;
				}
			}
			if (this.currentAnim.loopCount > 0) {
				this.currentAnim = this.anims.idle;
			}
			if (this.crosshair) {
				this.handleDesktopInput();
			} else {
				this.handleTouchInput();
			}
			this.currentAnim.angle = this.angle + Math.PI / 2;
			this.parent();
			if (this.pos.x < 0) {
				this.pos.x = 0;
			} else if (this.pos.x > ig.system.width) {
				this.pos.x = ig.system.width;
			}
			if (this.pos.y < 0) {
				this.pos.y = 0;
			} else if (this.pos.y > ig.system.height) {
				this.pos.y = ig.system.height;
			}
		},
		handleDesktopInput: function() {
			if (ig.input.state('left')) {
				this.vel.x = -this.speed;
			} else if (ig.input.state('right')) {
				this.vel.x = this.speed;
			} else {
				this.vel.x = 0;
			}
			if (ig.input.state('up')) {
				this.vel.y = -this.speed;
			} else if (ig.input.state('down')) {
				this.vel.y = this.speed;
			} else {
				this.vel.y = 0;
			}
			this.angle = this.angleTo(this.crosshair);
			var isShooting = ig.input.state('shoot');
			if (isShooting && this.lastShootTimer.delta() > 0) {
				this.shoot();
				this.lastShootTimer.set(0.05);
			}
			if (isShooting && !this.wasShooting) {
				this.wasShooting = true;
				this.soundShoot.play();
				if (!this.soundShoot.currentClip.iloop) {
					this.soundShoot.currentClip.iloop = true;
					this.soundShoot.currentClip.addEventListener('ended', (function() {
						this.currentTime = 0;
						this.play();
					}).bind(this.soundShoot.currentClip), false);
				}
			} else if (this.wasShooting && !isShooting) {
				this.soundShoot.stop();
				this.wasShooting = false;
			}
		},
		handleTouchInput: function() {
			var lstick = ig.game.stickLeft;
			this.vel.x = lstick.input.x * this.speed;
			this.vel.y = lstick.input.y * this.speed;
			var rstick = ig.game.stickRight;
			if (rstick.amount) {
				this.angle = rstick.angle - Math.PI / 2;
				if (this.lastShootTimer.delta() > 0) {
					this.shoot();
					this.lastShootTimer.set(0.05);
				}
			}
		},
		kill: function() {
			this.soundShoot.stop();
			this.soundExplode.play();
			ig.game.lastKillTimer.set(0.5);
			ig.game.spawnEntity(EntityExplosionParticleBlue, this.pos.x, this.pos.y, {
				count: 40
			});
			this.pos.y = ig.system.height + 300;
			this.parent();
			ig.game.loseLive();
		},
		shoot: function() {
			this.currentAnim = this.anims.shoot.rewind();
			var angle = this.angle + Math.random() * 0.1 - 0.05;
			ig.game.spawnEntity(EntityPlasma, this.pos.x - 1, this.pos.y - 1, {
				angle: angle
			});
		}
	});
	window.EntityPlasma = ig.Entity.extend({
		speed: 1000,
		maxVel: {
			x: 1000,
			y: 1000
		},
		image: new ig.Image('media/sprites/plasma.png'),
		size: {
			x: 4,
			y: 4
		},
		offset: {
			x: 46,
			y: 46
		},
		checkAgainst: ig.Entity.TYPE.B,
		init: function(x, y, settings) {
			this.parent(x, y, settings);
			this.vel.x = Math.cos(this.angle) * this.speed;
			this.vel.y = Math.sin(this.angle) * this.speed;
		},
		update: function() {
			this.pos.x += this.vel.x * ig.system.tick;
			this.pos.y += this.vel.y * ig.system.tick;
			if (this.pos.x > ig.system.width + 200 || this.pos.y > ig.system.height + 200 || this.pos.x < -200 || this.pos.y < -200) {
				this.kill();
			}
		},
		draw: function() {
			ig.system.context.save();
			ig.system.context.translate(this.pos.x - ig.game._rscreen.x, this.pos.y - ig.game._rscreen.y);
			ig.system.context.rotate(this.angle + Math.PI / 2);
			ig.system.context.drawImage(this.image.data, -this.offset.x, -this.offset.y);
			ig.system.context.restore();
		},
		check: function(other) {
			if (other instanceof EntityEnemy) {
				other.receiveDamage(10, this);
				this.kill();
			}
		}
	});
	window.EntityExplosionParticleBlue = EntityParticles.extend({
		lifetime: 1,
		fadetime: 1,
		vel: {
			x: 360,
			y: 360
		},
		image: new ig.Image('media/sprites/exp-blue.png')
	});
});

// lib/game/menus.js
ig.baked = true;
ig.module('game.menus').requires('impact.font').defines(function() {
	"use strict";
	window.MenuItem = ig.Class.extend({
		getText: function() {
			return 'none'
		},
		left: function() {},
		right: function() {},
		ok: function() {},
		click: function() {
			ig.system.canvas.style.cursor = 'auto';
			this.ok();
		}
	});
	window.Menu = ig.Class.extend({
		clearColor: null,
		name: null,
		font: new ig.Font('media/fonts/tungsten-48.png'),
		fontSelected: new ig.Font('media/fonts/tungsten-48-orange.png'),
		fontTitle: new ig.Font('media/fonts/tungsten-48.png'),
		current: 0,
		itemClasses: [],
		items: [],
		init: function() {
			this.y = ig.system.height / 4 + 160;
			for (var i = 0; i < this.itemClasses.length; i++) {
				this.items.push(new this.itemClasses[i]());
			}
		},
		update: function() {
			if (ig.input.pressed('up')) {
				this.current--;
			}
			if (ig.input.pressed('down')) {
				this.current++;
			}
			this.current = this.current.limit(0, this.items.length - 1);
			if (ig.input.pressed('left')) {
				this.items[this.current].left();
			}
			if (ig.input.pressed('right')) {
				this.items[this.current].right();
			}
			var margin = ig.ua.mobile ? this.font.height / 2 : 0;
			var ys = this.y;
			var xs = ig.system.width / 2;
			var hoverItem = null;
			for (var i = 0; i < this.items.length; i++) {
				var item = this.items[i];
				var w = this.font.widthForString(item.getText()) / 2 + margin;
				if (ig.input.mouse.x > xs - w && ig.input.mouse.x < xs + w && ig.input.mouse.y > ys - margin && ig.input.mouse.y < ys + this.font.height + margin) {
					hoverItem = item;
					this.current = i;
				}
				ys += this.font.height + 20;
			}
			if (hoverItem) {
				ig.system.canvas.style.cursor = 'pointer';
				if (ig.input.pressed('shoot')) {
					hoverItem.click();
				}
			} else {
				ig.system.canvas.style.cursor = 'auto';
			}
			if (ig.input.pressed('ok')) {
				this.items[this.current].ok();
			}
		},
		draw: function() {
			if (this.clearColor) {
				ig.system.context.fillStyle = this.clearColor;
				ig.system.context.fillRect(0, 0, ig.system.width, ig.system.height);
			}
			var xs = ig.system.width / 2;
			var ys = this.y;
			if (this.name) {
				this.fontTitle.draw(this.name, xs, ys - 160, ig.Font.ALIGN.CENTER);
			}
			for (var i = 0; i < this.items.length; i++) {
				var t = this.items[i].getText();
				if (i == this.current) {
					this.fontSelected.draw(t, xs, ys, ig.Font.ALIGN.CENTER);
				} else {
					this.font.draw(t, xs, ys, ig.Font.ALIGN.CENTER);
				}
				ys += this.font.height + 20;
			}
		}
	});
	window.MenuItemSoundVolume = MenuItem.extend({
		getText: function() {
			return 'Sound Volume: < ' + (ig.soundManager.volume * 100).round() + '% >';
		},
		left: function() {
			ig.soundManager.volume = (ig.soundManager.volume - 0.1).limit(0, 1);
		},
		right: function() {
			ig.soundManager.volume = (ig.soundManager.volume + 0.1).limit(0, 1);
		},
		click: function() {
			if (ig.input.mouse.x > 336) {
				this.right();
			} else {
				this.left();
			}
		}
	});
	window.MenuItemMusicVolume = MenuItem.extend({
		getText: function() {
			return 'Music Volume: < ' + (ig.music.volume * 100).round() + '% >';
		},
		left: function() {
			ig.music.volume = (ig.music.volume - 0.1).limit(0, 1);
		},
		right: function() {
			ig.music.volume = (ig.music.volume + 0.1).limit(0, 1);
		},
		click: function() {
			if (ig.input.mouse.x > 336) {
				this.right();
			} else {
				this.left();
			}
		}
	});
	window.MenuItemResume = MenuItem.extend({
		getText: function() {
			return 'Resume';
		},
		ok: function() {
			ig.game.toggleMenu();
		}
	});
	window.MenuItemBlank = MenuItem.extend({
		getText: function() {
			return '';
		}
	});
	window.PauseMenu = Menu.extend({
		init: function() {
			if (ig.Sound.enabled) {
				this.itemClasses.push(MenuItemSoundVolume);
				this.itemClasses.push(MenuItemMusicVolume);
			}
			this.itemClasses.push(MenuItemResume);
			if (ig.game.mode == XType.MODE.GAME) {
				this.itemClasses.push(MenuItemBlank);
				this.itemClasses.push(MenuItemBack);
			}
			this.parent();
		},
		name: 'Menu',
		clearColor: 'rgba(0,0,0,0.9)'
	});
	window.MenuItemPlay = MenuItem.extend({
		getText: function() {
			return 'Start Game!';
		},
		ok: function() {
			ig.game.setGame();
		}
	});
	window.MenuItemScores = MenuItem.extend({
		getText: function() {
			return 'Highscores';
		},
		ok: function() {
			ig.game.mode = XType.MODE.SCORES;
			ig.game.menu = new MenuScores();
		}
	});
	window.MenuItemSoundMenu = MenuItem.extend({
		getText: function() {
			return 'Sound Menu/Pause (ESC Key)';
		},
		ok: function() {
			ig.game.toggleMenu();
		}
	});
	window.TitleMenu = Menu.extend({
		init: function() {
			this.itemClasses.push(MenuItemPlay);
			if (ig.Sound.enabled) {
				this.itemClasses.push(MenuItemSoundMenu);
			}
			this.itemClasses.push(MenuItemScores);
			this.parent();
		}
	});
	window.MenuScores = Menu.extend({
		loaded: '',
		mode: 'Desktop',
		init: function() {
			ig.$('#scores').style.display = 'block';
			if (!MenuScores.initialized) {
				ig.$('#scoresBack').onclick = this.cancel.bind(this);
				ig.$('#showScoresDesktop').onclick = this.loadDesktop.bind(this);
				ig.$('#showScoresMobile').onclick = this.loadMobile.bind(this);
				MenuScores.initialized = true;
			}
			this.loadMode(ig.ua.mobile ? 'Mobile' : 'Desktop');
		},
		loadDesktop: function() {
			this.loadMode('Desktop');
			return false;
		},
		loadMobile: function() {
			this.loadMode('Mobile');
			return false;
		},
		loadMode: function(mode) {
			this.mode = mode;
			ig.$('#showScoresDesktop').className = '';
			ig.$('#showScoresMobile').className = '';
			ig.$('#showScores' + mode).className = 'active';
			ig.$('#scoresTable').innerHTML = '';
			ig.$('#scoreNotice').innerHTML = 'Loading...';
			ig.game.xhr('scores/index.php', {
				mode: mode
			}, this.loadCallback.bind(this));
		},
		cancel: function() {
			ig.$('#scores').style.display = 'none';
			ig.game.setTitle();
			return false;
		},
		loadCallback: function(scores) {
			if (!scores.length) {
				ig.$('#scoreNotice').innerHTML = 'No Scores Found.';
				return;
			}
			var html = '<table id="scoresTable"><tr class="head"><td></td><td>Name</td>' + '<td class="score">Score</td><td class="stage">Stage</td><td class="platform">Platform</td></tr>';
			for (var i = 0; i < scores.length; i++) {
				var s = scores[i];
				html += '<tr>' + '<td class="rank">' + (i + 1) + '.</td>' + '<td>' + this.escapeHTML(s.name) + '</a>' + '</td>' + '<td class="score">' + s.score + '</td>' + '<td class="stage">' + s.stage + '</td>' + '<td class="platform">' + s.platform + '</td>' + '</tr>';
			}
			html += '</table>';
			ig.$('#scoresTable').innerHTML = html;
			ig.$('#scoreNotice').innerHTML = '';
		},
		escapeHTML: function(s) {
			return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
		},
		draw: function() {},
		update: function() {}
	});
	window.MenuScores.initialized = false;
	window.MenuItemBack = MenuItem.extend({
		getText: function() {
			return 'Back to Title';
		},
		ok: function() {
			ig.game.setTitle();
		}
	});
	window.GameOverMenu = Menu.extend({
		init: function() {
			this.parent();
			this.y = 500;
		},
		itemClasses: [MenuItemBack],
		draw: function() {
			var ypos = 100;
			this.fontTitle.draw('Game Over', ig.system.width / 2, ypos, ig.Font.ALIGN.CENTER);
			this.fontTitle.draw('Score: ' + ig.game.score.zeroFill(6), ig.system.width / 2, ypos + 60, ig.Font.ALIGN.CENTER);
			this.parent();
		}
	});
});

// lib/game/entities/enemy.js
ig.baked = true;
ig.module('game.entities.enemy').requires('impact.entity', 'game.entities.particle').defines(function() {
	"use strict";
	window.EntityEnemy = ig.Entity.extend({
		speed: 0,
		hitTimer: null,
		dead: false,
		angle: 0,
		killScore: 10,
		hitScore: 10,
		children: [],
		parentNode: null,
		nodeOffset: {
			x: 0,
			y: 0
		},
		pivot: {
			x: 0,
			y: 0
		},
		maxVel: {
			x: 1000,
			y: 1000
		},
		explodeParticles: 10,
		attachmentPoints: [],
		soundExplode: new ig.Sound('media/sounds/explosion.ogg'),
		type: ig.Entity.TYPE.B,
		checkAgainst: ig.Entity.TYPE.A,
		killTimerTime: 0.3,
		init: function(x, y, settings) {
			this.parent(x, y, settings);
			this.hitTimer = new ig.Timer(0);
			this.dieTimer = new ig.Timer(0);
			this.ownAngle = this.angle;
		},
		angleToPoint: function(x, y) {
			return Math.atan2(y - (this.pos.y + this.size.y / 2), x - (this.pos.x + this.size.x / 2));
		},
		update: function() {
			if (!this.isChild) {
				this.vel.x = Math.cos(this.angle) * this.speed;
				this.vel.y = Math.sin(this.angle) * this.speed;
				this.parent();
				if (this.pos.x < -this.image.width || this.pos.x > ig.system.width + 10 || this.pos.y > ig.system.height + 10 || this.pos.y < -this.image.height - 30) {
					this.kill();
				}
			}
		},
		attachChild: function(entityClass) {
			var ap = this.attachmentPoints.shift();
			var c = this.addChild(entityClass, ap.x, ap.y, {
				angle: (ap.angle * Math.PI) / 180
			});
			return c;
		},
		addChild: function(entityClass, x, y, settings) {
			var c = ig.game.spawnEntity(entityClass, 0, 0, settings);
			c.entityType = entityClass;
			c.nodeOffset.x = x;
			c.nodeOffset.y = y;
			c.isChild = true;
			c.parentNode = this;
			this.children.push(c);
			return c;
		},
		updateChildren: function() {
			if (!this.children.length) return;
			var sv = Math.sin(this.angle - Math.PI / 2),
				cv = Math.cos(this.angle - Math.PI / 2);
			for (var i = 0; i < this.children.length; i++) {
				var c = this.children[i];
				var cx = c.nodeOffset.x,
					cy = c.nodeOffset.y;
				c.pos.x = this.pos.x + cv * cx - sv * cy - c.size.x / 2 + this.size.x / 2;
				c.pos.y = this.pos.y + cv * cy + sv * cx - c.size.y / 2 + this.size.y / 2;
				c.angle = this.angle + c.ownAngle;
				c.updateChildren();
			}
		},
		draw: function() {
			var sx = this.image.width / 2,
				sy = this.image.height / 2;
			ig.system.context.save();
			ig.system.context.translate(this.pos.x - ig.game._rscreen.x - this.offset.x + sx, this.pos.y - ig.game._rscreen.y - this.offset.y + sy);
			ig.system.context.rotate(this.angle - Math.PI / 2);
			ig.system.context.drawImage(this.image.data, -sx, -sy);
			ig.system.context.restore();
		},
		receiveDamage: function(amount, other) {
			var childTookDamage = false;
			if (this.health <= 10 && this.children.length) {
				for (var i = 0; i < this.children.length; i++) {
					childTookDamage = this.children[i].receiveSilentDamage(amount);
					if (childTookDamage) break;
				}
			}
			if (!childTookDamage) {
				this.parent(amount);
			}
			this.hitTimer.set(0.3);
			ig.game.score += this.hitScore;
			if (this.health <= 0) {
				this.soundExplode.play();
				this.explode();
				ig.game.lastKillTimer.set(this.killTimerTime);
				ig.game.score += this.killScore;
			} else {
				var px = other.pos.x - other.size.x / 2;
				var py = other.pos.y - other.size.y / 2;
				ig.game.spawnEntity(EntityExplosionParticleLargeSlow, px, py, {
					count: 1
				});
			}
		},
		receiveSilentDamage: function(amount) {
			if (this.health <= 10 && this.children.length) {
				for (var i = 0; i < this.children.length; i++) {
					var childTookDamage = this.children[i].receiveSilentDamage(amount);
					if (childTookDamage) {
						return true;
					}
				}
			} else if (this.health > 10) {
				this.health -= amount;
				return true;
			}
			return false;
		},
		explode: function() {
			var px = this.pos.x + this.size.x / 2;
			var py = this.pos.y + this.size.y / 2;
			ig.game.spawnEntity(EntityExplosionParticleLarge, px, py, {
				count: this.explodeParticles
			});
		},
		kill: function(killedByParent) {
			for (var i = 0; i < this.children.length; i++) {
				this.children[i].explode();
				this.children[i].kill(true);
			}
			if (killedByParent) {
				ig.game.score += this.killScore;
			}
			if (this.parentNode && !killedByParent) {
				this.parentNode.children.erase(this);
			}
			this.parent();
		},
		check: function(other) {
			if (!other.shieldTimer) {
				other.kill();
				this.kill();
			} else {
				this.receiveDamage(1000, other);
			}
		}
	});
	window.EntityExplosionParticleLarge = EntityParticles.extend({
		lifetime: 1,
		fadetime: 1,
		vel: {
			x: 150,
			y: 150
		},
		image: new ig.Image('media/sprites/enemy-explosion.png')
	});
	window.EntityExplosionParticleLargeSlow = EntityParticles.extend({
		lifetime: 1,
		fadetime: 1,
		vel: {
			x: 20,
			y: 20
		},
		image: new ig.Image('media/sprites/enemy-explosion.png')
	});
});

// lib/game/entities/enemy-bullet.js
ig.baked = true;
ig.module('game.entities.enemy-bullet').requires('game.entities.enemy').defines(function() {
	"use strict";
	window.EntityEnemyBullet = EntityEnemy.extend({
		size: {
			x: 16,
			y: 16
		},
		offset: {
			x: 2,
			y: 4
		},
		image: new ig.Image('media/sprites/bullet.png'),
		explodeParticles: 3,
		killTimerTime: 0,
		health: 10,
		speed: 170,
		killScore: 0,
		hitScore: 0
	});
});

// lib/game/entities/enemy-heart.js
ig.baked = true;
ig.module('game.entities.enemy-heart').requires('game.entities.enemy', 'game.entities.enemy-bullet').defines(function() {
	"use strict";
	window.EntityEnemyHeart = EntityEnemy.extend({
		size: {
			x: 64,
			y: 64
		},
		offset: {
			x: 0,
			y: 12
		},
		image: new ig.Image('media/sprites/heart.png'),
		health: 400,
		bullets: 16,
		killScore: 10000,
		moveTarget: {
			x: 0,
			y: 0
		},
		angleTarget: {
			x: 0,
			y: 0
		},
		explodeParticles: 40,
		killTimerTime: 0.3,
		attachmentPoints: [{
			x: 40,
			y: 42,
			angle: -45
		}, {
			x: 44,
			y: -20,
			angle: -110
		}],
		init: function(x, y, settings) {
			this.parent(x, y - 18, settings);
			this.shootTimer = new ig.Timer(2);
			this.angle = Math.PI / 2;
			this.moveTimer = new ig.Timer(4);
			this.angleTarget = {
				x: ig.system.width / 2,
				y: ig.system.height / 2
			};
			this.moveTarget = {
				x: ig.system.width / 2,
				y: ig.system.height / 6
			};
		},
		speed: 20,
		maxVel: {
			x: 60,
			y: 70
		},
		friction: {
			x: 20,
			y: 20
		},
		update: function() {
			if (this.moveTimer.delta() > 0) {
				this.moveTarget = {
					x: (Math.random().map(0, 1, ig.system.width / 3, ig.system.width - ig.system.width / 3)),
					y: (Math.random().map(0, 1, ig.system.height / 8, ig.system.height / 6))
				};
				this.moveTimer.set(Math.random() * 6 + 12);
				this.angleTarget = {
					x: ig.game.player.pos.x,
					y: ig.game.player.pos.y
				};
			}
			var a = (this.angle - this.angleToPoint(this.angleTarget.x, this.angleTarget.y)) * ig.system.tick;
			this.angle -= a;
			if (Math.abs(this.pos.x - this.moveTarget.x) > 20) {
				this.accel.x = (this.pos.x - this.moveTarget.x) < 0 ? this.speed : -this.speed;
			} else {
				this.accel.x = 0;
			}
			if (Math.abs(this.pos.y - this.moveTarget.y) > 20) {
				this.accel.y = (this.pos.y - this.moveTarget.y) < 0 ? this.speed : -this.speed;
			} else {
				this.accel.y = 0;
			}
			this.last.x = this.pos.x;
			this.last.y = this.pos.y;
			this.vel.x = this.getNewVelocity(this.vel.x, this.accel.x, this.friction.x, this.maxVel.x);
			this.vel.y = this.getNewVelocity(this.vel.y, this.accel.y, this.friction.y, this.maxVel.y);
			this.pos.x += this.vel.x * ig.system.tick;
			this.pos.y += this.vel.y * ig.system.tick;
			if (this.children.length == 0 && this.shootTimer.delta() > 0) {
				var inc = 140 / (this.bullets - 1);
				var a2 = 20;
				var radius = 22;
				for (var i = 0; i < this.bullets; i++) {
					var angle = a2 * Math.PI / 180;
					var x = this.pos.x + 24 + Math.cos(angle) * radius;
					var y = this.pos.y + 44 + Math.sin(angle) * radius;
					ig.game.spawnEntity(EntityEnemyBullet, x, y, {
						angle: angle
					});
					a2 += inc;
				}
				this.shootTimer.reset();
			}
			this.updateChildren();
		},
		kill: function() {
			this.parent();
			ig.game.spawnEntity(EntityExplosionHuge, this.pos.x, this.pos.y);
			ig.game.heart = null;
		}
	});
	window.EntityExplosionHuge = ig.Entity.extend({
		lifetime: 1,
		fadetime: 1,
		alpha: 0,
		img: new ig.Image('media/sprites/explosion-huge.jpg', 512, 512),
		init: function(x, y, settings) {
			this.parent(x, y, settings);
			this.idleTimer = new ig.Timer();
		},
		update: function() {
			if (this.idleTimer.delta() > this.lifetime) {
				this.kill();
				return;
			}
			this.alpha = this.idleTimer.delta().map(this.lifetime - this.fadetime, this.lifetime, 1, 0);
		},
		draw: function() {
			var ctx = ig.system.context;
			ctx.save();
			var scale = this.alpha.map(0, 1, 10, 0);
			ctx.translate(this.pos.x - ig.game._rscreen.x, this.pos.y - ig.game._rscreen.y);
			ctx.scale(scale, scale);
			ctx.globalAlpha = this.alpha;
			this.img.draw(-256, -256);
			ctx.globalAlpha = 1;
			ig.system.context.restore();
		}
	});
});

// lib/game/entities/enemy-missilebox.js
ig.baked = true;
ig.module('game.entities.enemy-missilebox').requires('game.entities.enemy', 'game.entities.enemy-bullet').defines(function() {
	"use strict";
	window.EntityEnemyMissilebox = EntityEnemy.extend({
		size: {
			x: 44,
			y: 44
		},
		offset: {
			x: 2,
			y: 2
		},
		image: new ig.Image('media/sprites/missilebox.png'),
		health: 120,
		bullets: 8,
		reloadTime: 3,
		explodeParticles: 10,
		killScore: 300,
		init: function(x, y, settings) {
			this.parent(x, y - 18, settings);
			this.moveTimer = new ig.Timer();
			this.angle = Math.PI / 2;
			this.startAngle = this.ownAngle;
			this.shootTimer = new ig.Timer(Math.random() * this.reloadTime * 2);
		},
		update: function() {
			this.parent();
			if (this.shootTimer.delta() > 0) {
				var inc = 140 / (this.bullets - 1);
				var a = 20 + (this.angle - Math.PI / 2) * 180 / Math.PI;
				var radius = 22;
				for (var i = 0; i < this.bullets; i++) {
					var angle = a * Math.PI / 180;
					var x = this.pos.x + 20 + Math.cos(angle) * radius;
					var y = this.pos.y + 20 + Math.sin(angle) * radius;
					ig.game.spawnEntity(EntityEnemyBullet, x, y, {
						angle: angle
					});
					a += inc;
				}
				this.shootTimer.set(this.reloadTime);
			}
		}
	});
});

// lib/game/entities/enemy-plasmabox.js
ig.baked = true;
ig.module('game.entities.enemy-plasmabox').requires('game.entities.enemy', 'game.entities.enemy-bullet').defines(function() {
	"use strict";
	window.EntityEnemyPlasmabox = EntityEnemy.extend({
		size: {
			x: 44,
			y: 44
		},
		offset: {
			x: 2,
			y: 2
		},
		image: new ig.Image('media/sprites/plasmabox.png'),
		health: 180,
		reloadTime: 4,
		bullets: 32,
		explodeParticles: 10,
		killScore: 400,
		init: function(x, y, settings) {
			this.parent(x, y - 18, settings);
			this.moveTimer = new ig.Timer();
			this.angle = Math.PI / 2;
			this.startAngle = this.ownAngle;
			this.shootTimer = new ig.Timer(Math.random() * this.reloadTime * 2);
		},
		update: function() {
			this.parent();
			if (this.shootTimer.delta() > 0) {
				var inc = 360 / (this.bullets - 1);
				var a = 0;
				var radius = 0;
				for (var i = 0; i < this.bullets; i++) {
					var angle = a * Math.PI / 180;
					var x = this.pos.x + 18;
					var y = this.pos.y + 18;
					ig.game.spawnEntity(EntityEnemyPlasmaBullet, x, y, {
						angle: angle
					});
					a += inc;
				}
				this.shootTimer.set(this.reloadTime);
			}
		}
	});
	window.EntityEnemyPlasmaBullet = EntityEnemy.extend({
		size: {
			x: 8,
			y: 8
		},
		offset: {
			x: 28,
			y: 28
		},
		image: new ig.Image('media/sprites/pbullet.png'),
		health: 10,
		speed: 10,
		maxSpeed: 160,
		type: ig.Entity.TYPE.NONE,
		update: function() {
			this.speed = Math.min(this.maxSpeed, this.speed + ig.system.tick * 100);
			this.vel.x = Math.cos(this.angle) * this.speed;
			this.vel.y = Math.sin(this.angle) * this.speed;
			this.pos.x += this.vel.x * ig.system.tick;
			this.pos.y += this.vel.y * ig.system.tick;
			if (this.pos.x > ig.system.width + 200 || this.pos.y > ig.system.height + 200 || this.pos.x < -200 || this.pos.y < -200) {
				this.kill();
			}
		},
		draw: function() {
			ig.system.context.drawImage(this.image.data, this.pos.x - ig.game._rscreen.x - this.offset.x, this.pos.y - ig.game._rscreen.y - this.offset.y);
		}
	});
});

// lib/game/entities/enemy-arm.js
ig.baked = true;
ig.module('game.entities.enemy-arm').requires('game.entities.enemy', 'game.entities.enemy-bullet').defines(function() {
	"use strict";
	window.EntityEnemyArm = EntityEnemy.extend({
		size: {
			x: 44,
			y: 44
		},
		offset: {
			x: 2,
			y: 2
		},
		image: new ig.Image('media/sprites/arm.png'),
		health: 70,
		killScore: 50,
		explodeParticles: 5,
		attachmentPoints: [{
			x: -8,
			y: 42,
			angle: 20
		}, {
			x: 32,
			y: 6,
			angle: -70
		}, {
			x: -32,
			y: 6,
			angle: 70
		}],
		init: function(x, y, settings) {
			this.parent(x, y - 18, settings);
			this.moveTimer = new ig.Timer();
			this.angle = Math.PI / 2;
			this.startAngle = this.ownAngle;
		},
		update: function() {
			this.parent();
			this.ownAngle = this.startAngle + Math.cos(this.moveTimer.delta()) * 0.05;
		}
	});
});

// lib/plugins/analog-stick.js
ig.baked = true;
ig.module('plugins.analog-stick').requires('impact.system').defines(function() {
	ig.AnalogStick = ig.Class.extend({
		stickSize: 30,
		baseSize: 70,
		stickColor: 'rgba(255,255,255,0.3)',
		baseColor: 'rgba(255,255,255,0.3)',
		pos: {
			x: 0,
			y: 0
		},
		input: {
			x: 0,
			y: 0
		},
		pressed: false,
		angle: 0,
		amount: 0,
		_touchId: null,
		init: function(x, y, baseSize, stickSize) {
			this.pos = {
				x: x,
				y: y
			};
			this.baseSize = baseSize || this.baseSize;
			this.stickSize = stickSize || this.stickSize;
			this.max = this.baseSize - this.stickSize / 3;
			ig.system.canvas.addEventListener('touchstart', this.touchStart.bind(this), false);
			document.addEventListener('touchmove', this.touchMove.bind(this), false);
			document.addEventListener('touchend', this.touchEnd.bind(this), false);
			ig.input.isUsingMouse = true;
		},
		touchStart: function(ev) {
			ev.preventDefault();
			if (this.pressed) {
				return;
			}
			for (var i = 0; i < ev.touches.length; i++) {
				var touch = ev.touches[i];
				var ip = ig.input;
				ip.mouse.x = touch.pageX * ig.internalScale;
				ip.mouse.y = touch.pageY * ig.internalScale;
				ip.actions['shoot'] = true;
				if (!ip.locks['shoot']) {
					ip.presses['shoot'] = true;
					ip.locks['shoot'] = true;
				}
				var xd = this.pos.x - touch.pageX * ig.internalScale;
				var yd = this.pos.y - touch.pageY * ig.internalScale;
				if (Math.sqrt(xd * xd + yd * yd) < this.baseSize) {
					this.pressed = true;
					this._touchId = touch.identifier;
					this._moved(touch);
					return;
				}
			}
		},
		touchMove: function(ev) {
			ev.preventDefault();
			for (var i = 0; i < ev.changedTouches.length; i++) {
				if (ev.changedTouches[i].identifier == this._touchId) {
					this._moved(ev.changedTouches[i]);
					return;
				}
			}
		},
		_moved: function(touch) {
			var x = touch.pageX * ig.internalScale - this.pos.x;
			var y = touch.pageY * ig.internalScale - this.pos.y;
			this.angle = Math.atan2(x, -y);
			this.amount = Math.min(1, Math.sqrt(x * x + y * y) / this.max);
			this.input.x = Math.sin(this.angle) * this.amount;
			this.input.y = -Math.cos(this.angle) * this.amount;
		},
		touchEnd: function(ev) {
			ig.input.delayedKeyup['shoot'] = true;
			for (var i = 0; i < ev.changedTouches.length; i++) {
				if (ev.changedTouches[i].identifier == this._touchId) {
					this.pressed = false;
					this.input.x = 0;
					this.input.y = 0;
					this.amount = 0;
					this._touchId = null;
					return;
				}
			}
		},
		draw: function() {
			var ctx = ig.system.context;
			ctx.beginPath();
			ctx.arc(this.pos.x, this.pos.y, this.baseSize, 0, (Math.PI * 2), true);
			ctx.lineWidth = 3;
			ctx.strokeStyle = this.baseColor;
			ctx.stroke();
			ctx.beginPath();
			ctx.arc(this.pos.x + this.input.x * this.max, this.pos.y + this.input.y * this.max, this.stickSize, 0, (Math.PI * 2), true);
			ctx.fillStyle = this.stickColor;
			ctx.fill();
		}
	});
});

// lib/game/main.js
ig.baked = true;
ig.module('game.main').requires('impact.game', 'impact.font', 'plugins.impact-splash-loader', 'game.entities.player', 'game.menus', 'game.entities.enemy-heart', 'game.entities.enemy-missilebox', 'game.entities.enemy-plasmabox', 'game.entities.enemy-arm', 'plugins.analog-stick').defines(function() {
	"use strict";
	Number.zeroes = '000000000000';
	Number.prototype.zeroFill = function(d) {
		var s = this.toString();
		return Number.zeroes.substr(0, d - s.length) + s;
	};
	window.XType = ig.Game.extend({
		menu: null,
		mode: 0,
		font: new ig.Font('media/fonts/tungsten-48.png'),
		fontSmall: new ig.Font('media/fonts/tungsten-18.png'),
		backdrop: new ig.Image('media/background/backdrop.png'),
		grid: new ig.Image('media/background/grid.png'),
		music: new ig.Sound('media/music/xtype.ogg', false),
		title: new ig.Image('media/xtype-title.png'),
		pauseButton: new ig.Image('media/pause-button.png'),
		madeWithImpact: new ig.Image('media/made-with-impact.png'),
		instructions: new ig.Image('media/instructions-' + (ig.ua.mobile ? 'mobile' : 'desktop') + '.png'),
		score: 0,
		lives: 3,
		level: {
			level: 0,
			support: 1,
			plasma: 0,
			missile: 0
		},
		stickLeft: null,
		stickRight: null,
		init: function() {
			var bgmap = new ig.BackgroundMap(620, [
				[1]
			], this.grid);
			bgmap.repeat = true;
			this.backgroundMaps.push(bgmap);
			if (!ig.ua.mobile) {
				ig.input.bind(ig.KEY.MOUSE1, 'shoot');
				ig.input.bind(ig.KEY.UP_ARROW, 'up');
				ig.input.bind(ig.KEY.DOWN_ARROW, 'down');
				ig.input.bind(ig.KEY.LEFT_ARROW, 'left');
				ig.input.bind(ig.KEY.RIGHT_ARROW, 'right');
				ig.input.bind(ig.KEY.W, 'up');
				ig.input.bind(ig.KEY.S, 'down');
				ig.input.bind(ig.KEY.A, 'left');
				ig.input.bind(ig.KEY.D, 'right');
				ig.input.bind(ig.KEY.ENTER, 'ok');
				ig.input.bind(ig.KEY.ESC, 'menu');
				ig.music.volume = 0.6;
				ig.music.add(this.music);
			} else {
				var radius = 60;
				var margin = 20;
				var y = ig.system.height - radius - margin;
				var x1 = radius + margin;
				var x2 = ig.system.width - radius - margin;
				this.stickLeft = new ig.AnalogStick(x1, y, radius, 30);
				this.stickRight = new ig.AnalogStick(x2, y, radius, 30);
			}
			this.reset();
			this.setTitle();
			XType.initialized = true;
		},
		reset: function() {
			this.heart = null;
			this.lastKillTimer = new ig.Timer(-2);
			this.entities = [];
			this.entitiesSortedByPosTypeA = [];
			this.entitiesSortedByPosTypeB = [];
			this.score = 0, this.lives = 3, this.level = {
				level: 0,
				support: 1,
				plasma: 0,
				missile: 0
			};
		},
		setGame: function() {
			window.scrollTo(0, 0);
			ig.music.play();
			ig.system.canvas.style.cursor = '';
			this.menu = null;
			this.initTimer = new ig.Timer(3);
			this.lastKillTimer.reset();
			if (!ig.ua.mobile) {
				this.crosshair = this.spawnEntity(EntityCrosshair, 0, 0);
			}
			this.bossEndTimer = null;
			this.player = this.spawnEntity(EntityPlayer, ig.system.width / 2, ig.system.height + 24);
			this.mode = XType.MODE.GAME;
		},
		setTitle: function() {
			this.reset();
			this.mode = XType.MODE.TITLE;
			this.menu = new TitleMenu();
			ig.$('#scoreBox').style.display = 'none';
		},
		setGameOver: function() {
			if (this.score > 0) {
				var name = this.getCookie('scoreName');
				if (name) {
					ig.$('#scoreName').value = name;
				}
				ig.$('#scoreBox').style.display = 'block';
				ig.$('#scoreForm').style.display = 'block';
				ig.$('#scoreResponse').style.display = 'none';
			}
			if (ig.ua.android) {
				ig.$('#scoreButton').focus();
			}
			this.mode = XType.MODE.GAME_OVER;
			this.menu = new GameOverMenu();
		},
		toggleMenu: function() {
			if (this.mode == XType.MODE.TITLE) {
				if (this.menu instanceof TitleMenu) {
					this.menu = new PauseMenu();
				} else {
					this.menu = new TitleMenu();
				}
			} else {
				if (this.menu) {
					ig.system.canvas.style.cursor = '';
					this.menu = null;
				} else {
					this.menu = new PauseMenu();
				}
			}
		},
		checkBoss: function() {
			if (!this.heart && !this.initTimer) {
				if (!this.bossEndTimer) {
					this.bossEndTimer = new ig.Timer(2);
				} else if (this.bossEndTimer && this.bossEndTimer.delta() > 0) {
					this.bossEndTimer = null;
					this.spawnBoss();
				}
			}
		},
		spawnBoss: function() {
			this.heart = this.spawnEntity(EntityEnemyHeart, ig.system.width / 2, 0);
			this.level.level += 1;
			this.level.support += 1;
			this.level.plasma += this.level.level % 2 ? 0 : 1;
			this.level.missile += this.level.level % 2 ? 1 : 0;
			for (var i = 0; i < this.level.support; i++) {
				this.spawEntityRandom(EntityEnemyArm);
			}
			for (i = 0; i < this.level.missile; i++) {
				this.spawEntityRandom(EntityEnemyMissilebox);
			}
			for (i = 0; i < this.level.plasma; i++) {
				this.spawEntityRandom(EntityEnemyPlasmabox);
			}
			this.mirrorChildren(this.heart, this.heart);
			this.heart.update();
			var ents = this.getEntitiesByType(EntityEnemyArm);
			var maxY = 0;
			for (i = 0; i < ents.length; i++) {
				maxY = Math.max(ents[i].pos.y, maxY);
			}
			this.heart.pos.y = -maxY - 120;
			this.heart.vel.y = 70;
			this.heart.update();
		},
		mirrorChildren: function(src, dest) {
			var l = src.children.length
			for (var i = 0; i < l; i++) {
				var srcEnt = src.children[i];
				var settings = {
					angle: -srcEnt.ownAngle
				};
				var destEnt = dest.addChild(srcEnt.entityType, -srcEnt.nodeOffset.x, srcEnt.nodeOffset.y, settings);
				this.mirrorChildren(srcEnt, destEnt);
			}
		},
		spawEntityRandom: function(type) {
			var ents = this.getEntitiesByType(EntityEnemyArm);
			ents.push(this.heart);
			for (var i = 0; i < 20; i++) {
				var e = ents.random();
				if (!e.attachmentPoints || !e.attachmentPoints.length) {
					continue;
				}
				if (type == EntityEnemyArm && e instanceof EntityEnemyArm && e.attachmentPoints.length != 3 && e.parentNode instanceof EntityEnemyHeart) {
					continue;
				}
				e.attachChild(type);
				return;
			}
		},
		update: function() {
			if (!this.menu && (ig.input.pressed('menu') || (ig.ua.mobile && ig.input.pressed('shoot') && ig.input.mouse.x < 100 && ig.input.mouse.y < 100))) {
				this.toggleMenu();
			}
			if (this.menu) {
				this.backgroundMaps[0].scroll.y -= 100 * ig.system.tick;
				this.menu.update();
				if (this.mode == XType.MODE.TITLE && ig.input.pressed('shoot') && ig.input.mouse.x > ig.system.width - 154 && ig.input.mouse.y > ig.system.height - 56) {
					window.location = 'http://impactjs.com/';
				}
				if (!(this.menu instanceof GameOverMenu)) {
					return;
				}
			}
			this.parent();
			this.backgroundMaps[0].scroll.y -= 100 * ig.system.tick;
			if (this.mode == XType.MODE.GAME) {
				this.checkBoss();
			}
		},
		loseLive: function() {
			this.lives--;
			if (this.lives > 0) {
				this.player = this.spawnEntity(EntityPlayer, ig.system.width / 2, ig.system.height + 24);
				this.livesRemainingTimer = new ig.Timer(2);
			} else {
				this.setGameOver();
			}
		},
		draw: function() {
			this.backdrop.draw(0, 0);
			var d = this.lastKillTimer.delta();
			ig.system.context.globalAlpha = d < 0 ? d * -3 + 0.3 : 0.3;
			for (var i = 0; i < this.backgroundMaps.length; i++) {
				this.backgroundMaps[i].draw();
			}
			ig.system.context.globalAlpha = 1;
			if (d < 0.5) {
				this._rscreen.x = Math.random() * 10 * (d - 0.5);
				this._rscreen.y = Math.random() * 10 * (d - 0.5);
			} else {
				this._rscreen.x = this._rscreen.y = 0;
			}
			ig.system.context.globalCompositeOperation = 'lighter';
			for (var i = 0; i < this.entities.length; i++) {
				this.entities[i].draw();
			}
			ig.system.context.globalCompositeOperation = 'source-over';
			if (this.mode == XType.MODE.GAME) {
				this.drawUI();
			} else if (this.mode == XType.MODE.TITLE) {
				this.drawTitle();
			}
			if (this.menu) {
				this.menu.draw();
			}
		},
		drawUI: function() {
			if (ig.ua.mobile) {
				this.stickLeft.draw();
				this.stickRight.draw();
				this.pauseButton.draw(16, 10);
			}
			this.font.draw(this.score.zeroFill(6), ig.system.width - 32, 32, ig.Font.ALIGN.RIGHT);
			if (this.bossEndTimer) {
				var d = -this.bossEndTimer.delta();
				var a = d > 1.7 ? d.map(2, 1.7, 0, 1) : d < 1 ? d.map(1, 0, 1, 0) : 1;
				var xs = ig.system.width / 2;
				var ys = ig.system.height / 3 + (d < 1 ? Math.cos(1 - d).map(1, 0, 0, 250) : 0);
				var b = this.level.level;
				this.font.alpha = a;
				this.font.draw('Stage ' + b + ' Clear', xs, ys, ig.Font.ALIGN.CENTER);
				this.font.alpha = 1;
			}
			if (this.livesRemainingTimer) {
				var d2 = -this.livesRemainingTimer.delta();
				var a2 = d2 > 1.7 ? d2.map(2, 1.7, 0, 1) : (d2 < 1 ? d2 : 1);
				var xs2 = ig.system.width / 2;
				var ys2 = ig.system.height / 3 + (d2 < 1 ? Math.cos(1 - d2).map(1, 0, 0, 250) : 0);
				this.font.alpha = Math.max(a2, 0);
				if (this.lives > 1) {
					this.font.draw(this.lives + ' Ships Remaining', xs2, ys2, ig.Font.ALIGN.CENTER);
				} else {
					this.font.draw(this.lives + ' Ship Remaining', xs2, ys2, ig.Font.ALIGN.CENTER);
				}
				this.font.alpha = 1;
				if (d2 < 0) {
					this.livesRemainingTimer = null;
				}
			}
			if (this.initTimer) {
				var initTime = this.initTimer.delta();
				if (initTime > 0) {
					this.initTimer = null;
					this.spawnBoss();
				}
				ig.system.context.globalAlpha = initTime.map(-0.5, 0, 1, 0).limit(0, 1);
				if (ig.ua.mobile) {
					this.instructions.draw(100, ig.system.height - 210);
				} else {
					this.instructions.draw(25, 260);
				}
				ig.system.context.globalAlpha = 1;
			}
		},
		drawTitle: function() {
			var xs = ig.system.width / 2;
			var ys = ig.system.height / 4;
			this.title.draw(96, 96);
			var xc = 8;
			var yc = ig.system.height - 40;
			ig.system.context.globalAlpha = 0.6;
			this.fontSmall.draw('Dominic Szablewski: Graphics & Programming', xc, yc);
			if (ig.Sound.enabled) {
				this.fontSmall.draw('Andreas Loesch: Music', xc, yc + 20);
			}
			ig.system.context.globalAlpha = 1;
			this.madeWithImpact.draw(ig.system.width - 154, ig.system.height - 56);
		},
		entitiesSortedByPosTypeA: [],
		entitiesSortedByPosTypeB: [],
		sortByYPos: function(a, b) {
			return a.pos.y - b.pos.y;
		},
		sortByYPosSize: function(a, b) {
			return (a.pos.y + a.size.y) - (b.pos.y + b.size.y);
		},
		spawnEntity: function(type, x, y, settings) {
			var entityClass = typeof(type) === 'string' ? ig.global[type] : type;
			if (!entityClass) {
				throw ("Can't spawn entity of type " + type);
			}
			var ent = new(entityClass)(x, y, settings || {});
			this.entities.push(ent);
			if (ent.name) {
				this.namedEntities[ent.name] = ent;
			}
			if (ent.type || ent.checkAgainst) {
				if (ent.type == ig.Entity.TYPE.A || (ent.checkAgainst & ig.Entity.TYPE.B)) {
					this.entitiesSortedByPosTypeA.push(ent);
				} else {
					this.entitiesSortedByPosTypeB.push(ent);
				}
			}
			return ent;
		},
		removeEntity: function(ent) {
			if (ent.name) {
				delete this.namedEntities[ent.name];
			}
			if (ent.type || ent.checkAgainst) {
				if (ent.type == ig.Entity.TYPE.A || (ent.checkAgainst & ig.Entity.TYPE.B)) {
					this.entitiesSortedByPosTypeA.erase(ent);
				} else {
					this.entitiesSortedByPosTypeB.erase(ent);
				}
			}
			ent._killed = true;
			ent.checkAgainst = ig.Entity.TYPE.NONE;
			ent.collides = ig.Entity.COLLIDES.NEVER;
			this._deferredKill.push(ent);
		},
		checkEntities: function() {
			var seB = this.entitiesSortedByPosTypeA;
			var seA = this.entitiesSortedByPosTypeB;
			seA.sort(this.sortByYPosSize);
			seB.sort(this.sortByYPos);
			var c1 = 0,
				c2 = 0;
			var k = 0,
				e1 = null,
				e2 = null,
				my = 0,
				noskip = true;
			for (var i = 0; i < seA.length; i++) {
				e1 = seA[i];
				noskip = true;
				my = e1.pos.y + e1.size.y;
				for (var j = k; j < seB.length && (e2 = seB[j]) && (e2.pos.y < my); j++) {
					if (noskip && e2.pos.y + e2.size.y < e1.pos.y) {
						k = j;
					} else {
						noskip = false;
					}
					if (e1.touches(e2)) {
						ig.Entity.checkPair(e1, e2);
					}
				}
			}
		},
		submitScore: function() {
			var name = ig.$('#scoreName').value;
			if (!name) return;
			ig.$('#scoreName').blur();
			ig.$('#scoreForm').style.display = 'none';
			ig.$('#scoreResponse').style.display = 'block';
			ig.$('#scoreResponse').innerHTML = 'Sending...';
			this.setCookie('scoreName', name, 100);
			var so = {
				stage: this.level.level,
				score: Math.floor(this.score),
				name: name
			};
			so.sh = (so.score + so.stage) ^ 0x8d525a2f;
			this.xhr('scores/index.php', so, this.scoreResponse.bind(this));
		},
		scoreResponse: function(data) {
			if (data.success) {
				ig.$('#scoreResponse').innerHTML = 'Your Rank: #' + data.rank;
			} else {
				ig.$('#scoreResponse').innerHTML = 'Failed. Sorry.';
			}
		},
		xhr: function(url, data, callback) {
			var post = [];
			if (data) {
				for (var key in data) {
					post.push(key + '=' + encodeURIComponent(data[key]));
				}
			}
			var postString = post.join('&');
			var xhr = new XMLHttpRequest();
			if (callback) {
				xhr.onreadystatechange = function() {
					if (xhr.readyState == 4) {
						callback(JSON.parse(xhr.responseText));
					}
				};
			}
			xhr.open('POST', url);
			xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
			xhr.send(postString);
		},
		setCookie: function(name, value, days) {
			days = days || 1;
			var expire = new Date();
			expire.setTime(Date.now() + 3600000 * 24 * days);
			document.cookie = name + "=" + escape(value) + ";expires=" + expire.toGMTString();
		},
		getCookie: function(name) {
			var re = new RegExp('[; ]' + name + '=([^\\s;]*)');
			var match = (' ' + document.cookie).match(re);
			if (name && match) {
				return unescape(match[1]);
			} else {
				return null;
			}
		}
	});
	window.XType.MODE = {
		TITLE: 0,
		GAME: 1,
		GAME_OVER: 2,
		SCORES: 3
	};
	window.XType.paused = false;
	window.XType.startGame = function() {
		ig.Sound.channels = 2;
		ig.System.drawMode = ig.System.DRAW.SUBPIXEL;
		var width = 480;
		var height = 720;
		if (ig.ua.mobile) {
			ig.Sound.enabled = false;
			var wpw = window.innerWidth * ig.ua.pixelRatio;
			var wph = window.innerHeight * ig.ua.pixelRatio;
			var scale = width / wpw;
			height = wph * scale;
			ig.internalScale = scale * ig.ua.pixelRatio;
			var canvas = ig.$('#canvas');
			canvas.style.width = Math.floor(window.innerWidth) + 'px';
			canvas.style.height = Math.floor(window.innerHeight) + 'px';
			ig.$('#scoreBox').style.width = Math.floor(window.innerWidth) + 'px';
			ig.$('#scoreBox').style.top = (240 / ig.internalScale) + 'px';
			ig.$('#scores').style.width = (410 / ig.internalScale) + 'px';
			ig.$('#scores').style.height = Math.floor(window.innerHeight) + 'px';
		} else {
			ig.$('#canvas').className = 'desktop';
			ig.$('#making-of').style.display = 'block';
			ig.$('#scoreBox').style.bottom = 0;
			ig.$('#scores').style.bottom = 0;
		}
		ig.$('#scoreForm').onsubmit = function() {
			if (ig.game) {
				ig.game.submitScore();
			}
			return false;
		}
		ig.main('#canvas', XType, 60, width, height, 1, ig.ImpactSplashLoader);
	};
	window.XType.checkOrientation = function() {
		var isPortrait = XType.isPortrait();
		if (isPortrait === XType.wasPortrait) {
			return;
		}
		XType.wasPortrait = isPortrait;
		ig.$('#loading').style.display = 'none';
		if (isPortrait) {
			ig.$('#canvas').style.display = 'block';
			ig.$('#rotate').style.display = 'none';
			if (XType.initialized && XType.paused) {
				ig.system.startRunLoop();
				XType.paused = false;
			} else if (!XType.initialized) {
				window.scrollTo(0, 0);
				window.setTimeout(XType.startGame, 1);
			}
		} else {
			if (XType.initialized) {
				ig.system.stopRunLoop();
				XType.paused = true;
			}
			ig.$('#canvas').style.display = 'none';
			ig.$('#rotate').style.display = 'block';
		}
	};
	window.XType.tweetPopup = function() {
		var text = 'I just scored ' + ig.game.score + ' in #xtype!';
		window.open('http://twitter.com/share' + '?url=' + encodeURIComponent('http://www.phoboslab.org/xtype/') + '&text=' + encodeURIComponent(text), 'tweet', 'height=450,width=550,resizable=1');
		return false;
	};
	window.XType.wasPortrait = -1;
	window.XType.isPortrait = function() {
		return (!ig.ua.mobile || window.innerHeight > window.innerWidth);
	};
	window.addEventListener('orientationchange', XType.checkOrientation, false);
	window.addEventListener('resize', XType.checkOrientation, false);
	window.XType.checkOrientation();
});
