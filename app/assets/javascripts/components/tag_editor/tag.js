import { fillTemplate } from '../../utils/template';
import { pushHistory } from './history';
import { save } from './save_handler';

export function asTag(ans) {
  if (ans.name) {
    return ans;
  }
  const namespace = ans.indexOf(':') == -1 ? '' : ans.split(':')[0];
  return {
    name: ans,
    slug: ans.replace(`${namespace}:`, ''),
    namespace,
    members: -1,
    flags: '',
    link: ans
  };
}

export function addTag(editor, tag) {
  tag = asTag(tag);
  if (!tag.name.length
    || tag.name.indexOf('uploader:') === 0
    || tag.name.indexOf('title:') === 0
    || editor.tags.indexOf(tag) > -1) {
    return;
  }

  editor.tags.push(tag);
  pushHistory(editor.history, tag, 1);
}

export function removeTag(editor, item) {
  const tag = editor.tags.find(a => a.namespace == item.dataset.namespace && a.slug == item.dataset.slug);
  if (!tag) {
    return console.error(`tag "${tag}" not found.`);
  }
  editor.tags.remove(tag);
  
  pushHistory(editor.history, tag, 0);
  save(editor);
}
