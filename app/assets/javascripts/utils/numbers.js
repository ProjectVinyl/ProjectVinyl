import { round } from './math';

export const MAX_DISPLAYED_VALUE = 9999;

export function formatNumber(number, max) {
  number = number || 0;
  if (max != undefined && number > max) {
    return formatWithDelimiters(max) + '+';
  }
  return formatWithDelimiters(number);
}

export function formatWithDelimiters(number) {
  return (number || 0).toString().replace(/,/g, "").replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

export function formatFuzzyBigNumber(number) {
  const units = {
    thousand: 'K',
    million: 'M',
    billion: 'B',
    trillion: 'T',
    quadrillion: 'Q'
  };
  const denom = getDenomination(number);
  if (denom.denom != 'unit') {
    number /= denom.multiplex;
  }
  const unit = units[denom.denom] ? ' ' + units[denom.denom] : '';
  return formatWithDelimiters(round(number, 2)) + unit;
}

function getDenomination(number) {
  const lengths = {
    2: 'ten',
    3: 'hundred',
    4: 'thousand',
    7: 'million',
    10: 'billion',
    13: 'trillion',
    16: 'quadrillion'
  };
  let len = Math.round(Math.abs(number || 0)).toString().length;
  while (len > 0 && !lengths[len]) {
    len--;
  }
  
  return {
    denom: lengths[len] || 'unit',
    multiplex: Math.pow(10, len - 1)
  };
}