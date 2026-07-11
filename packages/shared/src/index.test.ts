import { describe, it, expect } from 'vitest';
import { ok, err } from './index';

describe('shared', () => {
  it('ok returns success true', () => {
    expect(ok('data').success).toBe(true);
  });
  it('err returns success false', () => {
    expect(err('error').success).toBe(false);
  });
});
