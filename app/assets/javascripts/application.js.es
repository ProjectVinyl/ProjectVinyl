// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require rails-ujs
//
//  Due to ERB parsing (this can be eliminated later)
//= require data/all

// Not part of the codebase
import './vendor/all.js';

// Our code (this can be shortened to 1-2 imports later)
import './pageload.js';
import './components/comments.js';
import './components/search.js';
import './components/share.js';
import './components/uploader.js';
import './components/usercard.js';
import './components/vote.js';
import './components/notifier.js';
import './ui/infiniscroll.js';
import './ui/confirmation.js';
import './ui/dropdown.js';
import './ui/form.js';
import './ui/grid.js';
import './ui/lazy.js';
import './ui/reorder.js';
import './ui/slide.js';
import './ui/subtable.js';
import './ui/tabset.js';
import './ui/toggle.js';
import './utils/autocomplete.js';
import './utils/jslim.js';

import './callbacks.js';
