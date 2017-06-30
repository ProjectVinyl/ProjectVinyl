/*
 * Callback methods executed after certain actions.
 * i.e. When the banner selection dialog is opened
 */

import { ajax } from './utils/ajax.js';
import { initFileSelect } from './components/fileinput.js';

const Callbacks = {
  callbackFunctions: {
    editVideo: function(sender, data) {
      sender.find('.tag-editor')[0].getTagEditorObj().reload(data.results);
      var source = sender[0].parentNode.querySelector('.normal.tiny-link a');
      source.innerText = source.href = data.source
    },
    loadBannerSelector: function() {
      var me = document.getElementById('banner-upload');
      var banner = document.getElementById('banner');
      var basePath = me.dataset.path;
      initFileSelect($(me)).on('accept', function(e) {
        ajax.form(this.closest('form'), e, {
          success: function() {
            this.classList.remove('uploading');
            banner.style.backgroundSize = 'cover';
            banner.style.backgroundImage = 'url(' + basePath + '?' + new Date().getTime() + ')';
          }
        });
      });
    }
  },
  execute: function(name, params) {
    if (callbackFunc && typeof this.callbackFunctions[callbackFunc] === 'function') {
      this.callbackFunctions[callbackFunc].call(window, params);
      return true;
    }
  }
};

export { Callbacks };