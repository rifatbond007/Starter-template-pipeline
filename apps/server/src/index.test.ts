import { describe, it, expect } from 'vitest';
import { ok } from '@hackathon/shared';

describe('Server', () => {
  it('should produce ok response', () => {
    const result = ok({ status: 'healthy' });
    expect(result.success).toBe(true);
    expect(result.data?.status).toBe('ok');
  });
});
