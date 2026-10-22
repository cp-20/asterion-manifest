import { expect, test } from 'bun:test';
import { readFileSync } from 'node:fs';

test('fetch uses only the patched CA bundle and keeps request options', async () => {
  const originalFetch = globalThis.fetch;
  const originalCAFile = process.env.SSL_CERT_FILE;
  process.env.SSL_CERT_FILE = '/etc/ssl/certs/ca-certificates.crt';
  let received;
  const preconnect = () => {};
  globalThis.fetch = Object.assign(async (...args) => {
    received = args;
    return new Response('ok');
  }, { preconnect });
  try {
    await import('./bun-ca-preload.js');
    const headers = { Authorization: 'test-token' };
    const response = await fetch('https://example.test', {
      method: 'POST', headers, body: 'test',
      tls: { ca: 'outdated CA', rejectUnauthorized: false },
    });
    expect(await response.text()).toBe('ok');
    expect(received[0]).toBe('https://example.test');
    expect(received[1]).toMatchObject({ method: 'POST', headers, body: 'test' });
    expect(received[1].tls).toEqual({
      ca: readFileSync(process.env.SSL_CERT_FILE, 'utf8'), rejectUnauthorized: true,
    });
    expect(fetch.preconnect).toBe(preconnect);
  } finally {
    globalThis.fetch = originalFetch;
    if (originalCAFile === undefined) delete process.env.SSL_CERT_FILE;
    else process.env.SSL_CERT_FILE = originalCAFile;
  }
});
