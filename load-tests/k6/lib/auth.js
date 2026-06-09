import { SharedArray } from 'k6/data';

export const jwtPool = new SharedArray('jwts', () =>
  JSON.parse(open('../seed/jwt-pool.json'))
);

export function pickJwt(vuIndex) {
  if (!jwtPool || jwtPool.length === 0) {
      throw new Error("jwtPool is empty or not loaded properly.");
  }
  return jwtPool[vuIndex % jwtPool.length];
}
