/**
 * MP3 버퍼 병합 — lifelegacy `app/lib/audiobook/mp3.ts` 이식.
 */

function id3v2TagLength(buf: Buffer): number {
  if (buf.length < 10) return 0;
  if (buf.toString('ascii', 0, 3) !== 'ID3') return 0;
  const size =
    ((buf[6] & 0x7f) << 21) |
    ((buf[7] & 0x7f) << 14) |
    ((buf[8] & 0x7f) << 7) |
    (buf[9] & 0x7f);
  const total = 10 + size;
  return total <= buf.length ? total : 0;
}

export function stripLeadingId3(buf: Buffer): Buffer {
  const skip = id3v2TagLength(buf);
  return skip > 0 ? buf.subarray(skip) : buf;
}

export function concatMp3Buffers(buffers: Buffer[]): Buffer {
  if (buffers.length === 0) return Buffer.alloc(0);
  if (buffers.length === 1) return buffers[0];

  const parts: Buffer[] = [];
  for (let i = 0; i < buffers.length; i++) {
    const buf = buffers[i];
    if (!buf || buf.length === 0) continue;
    parts.push(i === 0 ? buf : stripLeadingId3(buf));
  }

  if (parts.length === 0) return Buffer.alloc(0);
  if (parts.length === 1) return parts[0];
  return Buffer.concat(parts);
}
