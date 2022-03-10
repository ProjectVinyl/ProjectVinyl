
export function pushHistory(history, tag, action) {
  history[0].push({type: action, tag: tag});
  history[1].length = 0;
}

export function popHistory(sender, direction) {
  const source = sender.history[direction];
  const dest = sender.history[(direction + 1) % 2];
  if (!source.length) return;
  const item = source.pop();
  dest.push(item);
  if (item.type === direction) {
    sender.tags.push(item.tag);
  } else {
    sender.tags.remove(item.tag);
  }
  save(sender);
}
