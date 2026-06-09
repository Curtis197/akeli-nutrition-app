import { smokeSweep } from './scenarios/smoke-sweep.js';

export const options = {
  vus: 10,
  duration: '2m',
  thresholds: {
    'http_req_duration{scenario:smoke}': ['p(95)<5000'],
    'http_req_failed{scenario:smoke}':   ['rate<0.001'],  // 0% errors — any 5xx blocks the PR
  },
};

export default function () {
  smokeSweep();
}
