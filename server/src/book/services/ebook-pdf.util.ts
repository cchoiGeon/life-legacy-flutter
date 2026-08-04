import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import PDFDocument from 'pdfkit';

/** Windows 맑은 고딕 등 — 없으면 null (헬베티카 폴백) */
export function resolveEbookFontPath(): string | null {
  const fromEnv = process.env.EBOOK_FONT_PATH?.trim();
  if (fromEnv && fs.existsSync(fromEnv)) return fromEnv;

  const candidates = [
    path.join('C:', 'Windows', 'Fonts', 'malgun.ttf'),
    path.join('C:', 'Windows', 'Fonts', 'malgunbd.ttf'),
    path.join('C:', 'Windows', 'Fonts', 'NotoSansKR-Regular.otf'),
    path.join('C:', 'Windows', 'Fonts', 'NotoSansKR-Regular.ttf'),
    '/usr/share/fonts/truetype/noto/NotoSansKR-Regular.otf',
    '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
    '/usr/share/fonts/truetype/nanum/NanumGothic.ttf',
    path.join(os.homedir(), 'Library', 'Fonts', 'NotoSansKR-Regular.otf'),
    '/Library/Fonts/AppleGothic.ttf',
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

export async function writeEbookPdf(input: {
  filePath: string;
  title: string;
  authorName: string;
  chapters: Array<{ order: number; title: string; body: string }>;
}): Promise<{ byteSize: number }> {
  await fs.promises.mkdir(path.dirname(input.filePath), { recursive: true });

  const fontPath = resolveEbookFontPath();
  const doc = new PDFDocument({
    size: 'A4',
    margins: { top: 56, bottom: 56, left: 56, right: 56 },
    info: {
      Title: input.title,
      Author: input.authorName,
      Creator: 'LifeLegacy',
    },
  });

  const stream = fs.createWriteStream(input.filePath);
  doc.pipe(stream);

  if (fontPath) {
    doc.registerFont('Body', fontPath);
    doc.font('Body');
  }

  // 표지
  doc.fontSize(28).text(input.title || '나의 이야기', { align: 'center' });
  doc.moveDown();
  doc.fontSize(16).text(input.authorName || '', { align: 'center' });
  doc.moveDown(2);
  doc
    .fontSize(11)
    .fillColor('#666666')
    .text('리뷰를 마친 장의 원고입니다', { align: 'center' });
  doc.fillColor('#000000');

  for (const chapter of input.chapters) {
    doc.addPage();
    if (fontPath) doc.font('Body');
    doc
      .fontSize(12)
      .fillColor('#888888')
      .text(`제 ${chapter.order} 장`, { align: 'center' });
    doc.moveDown(0.5);
    doc
      .fillColor('#000000')
      .fontSize(20)
      .text(chapter.title, { align: 'center' });
    doc.moveDown();
    doc.fontSize(12).text(chapter.body || '', {
      align: 'left',
      lineGap: 6,
    });
  }

  doc.end();

  await new Promise<void>((resolve, reject) => {
    stream.on('finish', () => resolve());
    stream.on('error', reject);
  });

  const stat = await fs.promises.stat(input.filePath);
  return { byteSize: stat.size };
}
