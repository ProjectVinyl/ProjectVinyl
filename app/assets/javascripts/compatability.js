/* Polyfills, browser fixes, etc... */
if (navigator.userAgent.indexOf("OPR") !== -1) $('html').addClass('opera');
if (!Object.freeze) Object.freeze = function(o) { return o };