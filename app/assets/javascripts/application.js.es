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
import './vendor/all';

// Our code (this can be shortened to 1-2 imports later)
import './pageload';
import './callbacks';
import './components/comments';
import './components/search';
import './components/share';
import './components/uploader';
import './components/usercard';
import './components/vote';
import './components/notifier';
import './ui/infiniscroll';
import './ui/confirmation';
import './ui/dragtarget';
import './ui/dropdown';
import './ui/form';
import './ui/grid';
import './ui/lazy';
import './ui/reorder';
import './ui/slide';
import './ui/subtable';
import './ui/tabset';
import './ui/toggle';
import './utils/autocomplete';
import './utils/jslim';

import './callbacks';
