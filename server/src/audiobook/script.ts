/**
 * CLOVA TTS 청킹 — lifelegacy `app/lib/audiobook/script.ts` 이식.
 */

export const CLOVA_TTS_CHUNK_CHARS = 1800;

/** 문단 구분(`\n\n`)으로 분리 — 문단 사이 무음 삽입용 */
export function splitParagraphsForTts(text: string): string[] {
  return text
    .replace(/\r\n/g, '\n')
    .split(/\n\n+/)
    .map((p) => p.trim())
    .filter(Boolean);
}

/**
 * 문장 경계 우선으로 텍스트를 maxChars 이하 청크로 분할.
 * CLOVA TTS Premium 한국어 2000자 한도 (기본 1800자).
 */
export function chunkTextForTts(
  text: string,
  maxChars = CLOVA_TTS_CHUNK_CHARS,
): string[] {
  const normalized = text.replace(/\r\n/g, '\n').trim();
  if (!normalized) return [];
  if (normalized.length <= maxChars) return [normalized];

  const chunks: string[] = [];
  let remaining = normalized;

  while (remaining.length > maxChars) {
    const window = remaining.slice(0, maxChars);
    const breakAt = findBreakIndex(window);
    const piece = remaining.slice(0, breakAt).trim();
    if (piece) chunks.push(piece);
    remaining = remaining.slice(breakAt).trim();
  }
  if (remaining) chunks.push(remaining);
  return chunks;
}

function findBreakIndex(window: string): number {
  const candidates = [
    window.lastIndexOf('\n\n'),
    window.lastIndexOf('\n'),
    window.lastIndexOf('. '),
    window.lastIndexOf('。'),
    window.lastIndexOf('! '),
    window.lastIndexOf('？'),
    window.lastIndexOf('? '),
    window.lastIndexOf(' '),
  ];
  const best = Math.max(...candidates);
  if (best >= Math.floor(window.length * 0.4)) {
    return best + 1;
  }
  return window.length;
}

/** 챕터 제목 + 원고 body → TTS 대본 */
export function buildChapterScript(chapterTitle: string, body: string): string {
  const parts: string[] = [];
  const title = chapterTitle.trim();
  if (title) parts.push(title);
  const text = body.trim();
  if (text) parts.push(text);
  return parts.join('\n\n').trim();
}
