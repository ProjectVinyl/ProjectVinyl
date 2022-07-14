import { cookies } from '../../utils/cookies';

const DEFAULT_SPEED = 2;
const DEFAULT_INCREMENTER = (on => !on);
const SPEEDS = [
  {name: '0.25x', value: 0.25},
  {name: '0.5x', value: 0.5},
  {name: 'Normal', value: 1},
  {name: '1.25x', value: 1.25},
  {name: '1.5x', value: 1.5},
  {name: 'Double', value: 2}
];

export function initContextMenu(el, player) {
  const actions = {};
  const menuItems = {};

  function createSetter(name, label, cookieName, def, applicator, incrementer) {
    menuItems[label] = {
      getter() {
        return player['__' + name.toLowerCase()];
      },
      incrementer: (incrementer || DEFAULT_INCREMENTER),
      setter(value) {
        player['__' + name.toLowerCase()] = value;
        if (!player.nonpersistent) {
          cookies.set(cookieName, value);
        }
        if (applicator) {
          value = applicator(value);
        }
        if (this.onChange) {
          this.onChange(value);
        }
      }
    };
    actions['set' + name] = value => menuItems[label].setter(value);
    menuItems[label].setter(cookies.get(cookieName, def === undefined ? false : def));
  }

  createSetter('Loop', 'Loop', 'loopplayback', false, on => {
    if (player.video) {
      player.video.loop = on;
    }
    return on;
  });
  createSetter('Speed', 'Speed', 'playbackspeed', DEFAULT_SPEED, speed => {
    player.__speed %= SPEEDS.length;
    speed = SPEEDS[player.__speed];
    if (player.video) {
      player.video.playbackRate = speed.value;
    }
    return speed.name;
  }, on => on + 1);
  createSetter('Autostart', 'Auto Play', 'autostart');
  createSetter('Autoplay', 'Auto Next', 'autoplay');

  player.dom.addEventListener('contextmenu:shown', ev => {
    ev.detail.data.buildMenu(menuItems);
  });

  return actions;
}
