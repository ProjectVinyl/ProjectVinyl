
export function insertTags(textarea, open, close, endSelect) {
  const start = textarea.selectionStart;
  if (start === undefined || start === null) {
    return;
  }

  const end = textarea.selectionEnd;
  
  let selected = textarea.value.substring(start, end);
  
  if ((open && selected.indexOf(open) > -1) || (close && selected.indexOf(close) > -1)) {
    selected = selected.replace(open, '').replace(close, '');
  } else {
    selected = open + selected + close;
  }
  
  const before = textarea.value.substring(0, start);
  const after = textarea.value.substring(end, textarea.value.length);
  
  textarea.value = `${before}${selected}${after}`;
  textarea.selectionStart = endSelect ? start + selected.length : start;
  textarea.selectionEnd = start + selected.length;
  textarea.focus();
}
