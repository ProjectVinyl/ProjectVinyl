/* Polyfills, browser fixes, etc... */
if (navigator.userAgent.indexOf('OPR') !== -1) $('html').addClass('opera');
if (!Object.freeze) Object.freeze = function(o) { return o; };

function oneOf(on, member, prefixes, fallback) {
  while (++i < prefixes.length) {
    var key = prefixes[i] + member;
    key = key[0].toLowerCase() + key.slice(1);
    if (on[key]) return on[key];
  };
  return fallback;
} 

if (!Element.prototype.matches) {
  Element.prototype.matches = oneOf(Element.prototype, 'MatchesSelector', ['','moz','ms','o','webkit'], function(s) {
    var possibles = (this.document || this.ownerDocument).querySelectorAll(s);
    return Array.prototype.indexOf.call(possibles, this) > -1;
  });
}