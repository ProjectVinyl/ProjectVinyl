
const RECAPTCHA_URL = 'https://www.recaptcha.net/recaptcha/api.js';

document.addEventListener('ajax:externalform', e => {
    const sc = document.createElement('SCRIPT');
    sc.src = RECAPTCHA_URL;
    document.head.insertAdjacentElement('beforeend', sc);
    requestAnimationFrame(() => sc.remove());
});
