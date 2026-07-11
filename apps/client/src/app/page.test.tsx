import { describe, it, expect } from 'vitest';
import { ok } from '@hackathon/shared';

describe('Home', () => {
  it('should produce ok response', () => {
    const result = ok({ message: 'test' });
    expect(result.success).toBe(true);
    expect(result.data?.message).toBe('test');
  });
});
