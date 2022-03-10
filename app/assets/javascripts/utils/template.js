
export function fillTemplate(obj, template) {
  Object.keys(obj).forEach(key => {
    template = template.replace(new RegExp(`{${key}}`, 'g'), obj[key]);
  });
  return template;
}
