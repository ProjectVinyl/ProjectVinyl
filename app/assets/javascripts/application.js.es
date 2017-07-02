// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery2
//= require jquery_ujs

//  Due to ERB parsing (this can be eliminated later)
//= require data/all

//= depend_on compat/all.js
//= depend_on compat/opera.js
//= depend_on compat/promise.polyfill.js
//= depend_on compat/fetch.polyfill.js
//= depend_on compat/closest.polyfill.js
//= depend_on compat/customevent.polyfill.js

//= depend_on callbacks
//= depend_on pageload

//= depend_on components/notifier
//= depend_on components/comments
//= depend_on components/fileinput
//= depend_on components/notifier
//= depend_on components/paginator
//= depend_on components/popup
//= depend_on components/search
//= depend_on components/share
//= depend_on components/tageditor
//= depend_on components/thumbnailpicker
//= depend_on components/uploader
//= depend_on components/usercard
//= depend_on components/videos
//= depend_on components/vote
//= depend_on ui/confirmation
//= depend_on ui/dropdown
//= depend_on ui/form
//= depend_on ui/grid
//= depend_on ui/lazy
//= depend_on ui/reorder
//= depend_on ui/resize
//= depend_on ui/scroll
//= depend_on ui/select
//= depend_on ui/slide
//= depend_on ui/subtable
//= depend_on ui/tabset
//= depend_on ui/toggle
//= depend_on utils/ajax
//= depend_on utils/autocomplete
//= depend_on utils/bbcode
//= depend_on utils/duration
//= depend_on utils/misc
//= depend_on utils/queryparameters
//= depend_on utils/requests
//= depend_on utils/jslim

// Utilities for use at top scope
import './compat/all.js';

// Our code (this can be shortened to 1-2 imports later)
import './pageload.js';
import './components/comments.js';
import './components/search.js';
import './components/share.js';
import './components/uploader.js';
import './components/usercard.js';
import './components/vote.js';
import './components/notifier.js';
import './ui/confirmation.js';
import './ui/dropdown.js';
import './ui/form.js';
import './ui/grid.js';
import './ui/lazy.js';
import './ui/reorder.js';
import './ui/select.js';
import './ui/slide.js';
import './ui/subtable.js';
import './ui/tabset.js';
import './ui/toggle.js';
import './utils/autocomplete.js';
import './utils/jslim.js';

import './callbacks.js';
