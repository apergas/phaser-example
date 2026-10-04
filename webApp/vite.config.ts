import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { defineConfig, type Plugin } from 'vite';

// The LPC art lives once in shared/assets/lpc (also read by the Android and iOS apps).
const LPC_DIR = join(import.meta.dirname, '../shared/assets/lpc');
const LPC_URL = 'assets/lpc';

/** Serves shared/assets/lpc at assets/lpc in dev and copies it there in the build, like public/ would. */
function sharedLpcAssets(): Plugin {
  return {
    name: 'shared-lpc-assets',
    configureServer(server) {
      server.middlewares.use(`/${LPC_URL}`, (req, res, next) => {
        const name = decodeURIComponent((req.url ?? '').split('?')[0]).replace(/^\//, '');
        if (!readdirSync(LPC_DIR).includes(name)) return next();
        res.end(readFileSync(join(LPC_DIR, name)));
      });
    },
    generateBundle() {
      for (const name of readdirSync(LPC_DIR)) {
        this.emitFile({ type: 'asset', fileName: `${LPC_URL}/${name}`, source: readFileSync(join(LPC_DIR, name)) });
      }
    },
  };
}

export default defineConfig({
  // Relative asset paths, so the build works under any sub-path (e.g. GitHub Pages /<repo>/).
  base: './',
  plugins: [sharedLpcAssets()],
});
