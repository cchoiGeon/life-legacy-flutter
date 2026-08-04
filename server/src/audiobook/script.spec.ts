import { chunkTextForTts, splitParagraphsForTts } from './script';
import { concatMp3Buffers } from './mp3';

describe('audiobook script/mp3 (lifelegacy port)', () => {
  it('문단을 분리한다', () => {
    expect(splitParagraphsForTts('a\n\nb\n\n\nc')).toEqual(['a', 'b', 'c']);
  });

  it('1800자 초과 시 문장 경계로 청크한다', () => {
    const sentence = '안녕하세요. '.repeat(400);
    const chunks = chunkTextForTts(sentence, 1800);
    expect(chunks.length).toBeGreaterThan(1);
    expect(chunks.every((c) => c.length <= 1800)).toBe(true);
  });

  it('MP3 버퍼를 이어 붙인다', () => {
    const a = Buffer.from([1, 2, 3]);
    const b = Buffer.from([4, 5]);
    expect(concatMp3Buffers([a, b])).toEqual(Buffer.from([1, 2, 3, 4, 5]));
  });
});
