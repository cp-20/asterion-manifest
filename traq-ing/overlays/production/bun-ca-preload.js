import { readFileSync } from 'node:fs';

// Temporary mitigation until Bun ships the eMudhra CA removal.
// SSL_CERT_FILE alone adds to Bun's bundled roots rather than replacing them.
const ca = readFileSync(process.env.SSL_CERT_FILE, 'utf8');
const originalFetch = globalThis.fetch;
globalThis.fetch = Object.assign(
  (input, init) => originalFetch(input, {
    ...init,
    tls: { ...init?.tls, ca, rejectUnauthorized: true },
  }),
  originalFetch,
);
