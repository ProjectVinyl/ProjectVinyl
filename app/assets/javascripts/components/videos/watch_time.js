import { cookies } from '../../utils/cookies';

export function getWatchTime(videoId) {
  const time = cookies.get(`watch_time_${videoId}`, 0);
  if (time >= 1) {
    return 0;
  }
  return time;
}

export function setWatchTime(videoId, percentage) {
  cookies.set(`watch_time_${videoId}`, percentage || 0);
}
