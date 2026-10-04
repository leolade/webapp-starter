import webpush from 'web-push';

// `pnpm --filter <api> vapid:generate` — prints a VAPID key pair to paste into .env / the deployment secrets.
const { publicKey, privateKey } = webpush.generateVAPIDKeys();
process.stdout.write(`VAPID_PUBLIC_KEY=${publicKey}\nVAPID_PRIVATE_KEY=${privateKey}\n`);
