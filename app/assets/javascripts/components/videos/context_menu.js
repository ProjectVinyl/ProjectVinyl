import { cookies } from '../../utils/cookies';

const speeds = [
  {name: '0.25x', value: 0.25},
  {name: '0.5x', value: 0.5},
  {name: 'Normal', value: 1},
  {name: '1.25x', value: 1.25},
  {name: '1.5x', value: 1.5},
  {name: 'Double', value: 2}
];

export function initContextMenu(el, player) {
  const actions = {
    setAutostart(on) {
      player.__autostart = on;
      if (!player.nonpersistent) {
        cookies.set('autostart', on);
      }
      return on;
    },
    setAutoplay(on) {
      player.__autoplay = on;
      if (!player.nonpersistent) {
        cookies.set('autoplay', on);
      }
      if (on) {
        actions.setLoop(false);
      }

      return on;
    },
    setLoop(on) {
      player.__loop = on;

      if (player.video) {
        player.video.loop = on;
      }

      return on;
    },
    setSpeed(speed) {
      player.__speed = speed % speeds.length;
      speed = speeds[player.__speed];

      if (player.video) {
        player.video.playbackRate = speed.value;
      }

      return speed.name;
    }
  };
  const menuItems = {
    'Loop': {
      initial: actions.setLoop(false),
      callback: () => actions.setLoop(!player.__loop)
    },
    'Speed': {
      initial: actions.setSpeed(2),
      callback: () => actions.setSpeed(player.__speed + 1)
    },
    'Auto Play': {
      initial: actions.setAutostart(!!cookies.get('autostart')),
      callback: () => actions.setAutostart(!player.__autostart)
    },
    'Auto Next': {
      initial: actions.setAutoplay(!!cookies.get('autoplay')),
      display: player.params.autoplay,
      callback: ()  => actions.setAutoplay(!player.__autoplay)
    }
  };
  player.dom.addEventListener('contextmenu:shown', ev => {
    console.log(ev);
    ev.detail.data.buildMenu(menuItems);
  });

  return actions;
}
