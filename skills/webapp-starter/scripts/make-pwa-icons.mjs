#!/usr/bin/env node
// Writes neutral, brand-free placeholder PWA icons (dark square, white disc) without any image library,
// so a fresh project is installable immediately. Replace them with the real brand icons before shipping.
//
//   node make-pwa-icons.mjs --out <dir>      # writes icon-192.png, icon-512.png, icon-512-maskable.png

import { mkdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { deflateSync } from 'node:zlib';

const args = process.argv.slice(2);
const out = resolve(args.includes('--out') ? args[args.indexOf('--out') + 1] : 'icons');
mkdirSync(out, { recursive: true });

const crcTable = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
const crc32 = (buffer) => {
  let c = 0xffffffff;
  for (const byte of buffer) c = crcTable[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
};
const chunk = (type, data) => {
  const body = Buffer.concat([Buffer.from(type), data]);
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const checksum = Buffer.alloc(4);
  checksum.writeUInt32BE(crc32(body));
  return Buffer.concat([length, body, checksum]);
};

const png = (size, discRadius) => {
  const [bg, fg] = [[15, 23, 42], [255, 255, 255]];
  const rows = [];
  const centre = (size - 1) / 2;
  for (let y = 0; y < size; y++) {
    const row = Buffer.alloc(1 + size * 3); // filter byte 0 + RGB pixels
    for (let x = 0; x < size; x++) {
      const inside = Math.hypot(x - centre, y - centre) <= size * discRadius;
      row.set(inside ? fg : bg, 1 + x * 3);
    }
    rows.push(row);
  }
  const header = Buffer.alloc(13);
  header.writeUInt32BE(size, 0);
  header.writeUInt32BE(size, 4);
  header.set([8, 2, 0, 0, 0], 8); // 8-bit, truecolour, default compression/filter/interlace
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', header),
    chunk('IDAT', deflateSync(Buffer.concat(rows))),
    chunk('IEND', Buffer.alloc(0)),
  ]);
};

for (const [name, size, radius] of [['icon-192.png', 192, 0.3], ['icon-512.png', 512, 0.3], ['icon-512-maskable.png', 512, 0.26]]) {
  writeFileSync(join(out, name), png(size, radius));
}
process.stdout.write(`wrote 3 icons to ${out}\n`);
