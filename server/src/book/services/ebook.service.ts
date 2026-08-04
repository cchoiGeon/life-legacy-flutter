import * as fs from 'fs';
import * as path from 'path';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';

import { BookAccessService } from 'src/book/services/book-access.service';
import { ChapterStatus } from 'src/chapters/const/chapter-status.enum';
import { ChaptersRepository } from 'src/chapters/repositories/chapters.repository';
import { JobStatus } from 'src/common/const/job-status.enum';
import { MediaKind } from 'src/common/const/media-kind.enum';
import { MediaSource } from 'src/common/const/media-source.enum';
import { ReviewStatus } from 'src/common/const/review-status.enum';
import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { EbookExportModel } from 'src/ebook/entities/ebook-export.entity';
import { MediaAssetModel } from 'src/media/entities/media-asset.entity';
import { ChapterReviewModel } from 'src/review/entities/chapter-review.entity';
import { BookModel } from '../entities/book.entity';
import { writeEbookPdf } from './ebook-pdf.util';

type SnapshotItem = { chapter_id: string; version: number };

@Injectable()
export class EbookService {
  constructor(
    private readonly bookAccess: BookAccessService,
    private readonly chaptersRepository: ChaptersRepository,
    @InjectRepository(ChapterReviewModel)
    private readonly reviews: Repository<ChapterReviewModel>,
    @InjectRepository(EbookExportModel)
    private readonly exports: Repository<EbookExportModel>,
    @InjectRepository(MediaAssetModel)
    private readonly media: Repository<MediaAssetModel>,
    @InjectRepository(BookModel)
    private readonly books: Repository<BookModel>,
  ) {}

  /** api-spec §10.1 */
  async eligibility(userId: string, bookId: string) {
    await this.bookAccess.requireOwnedBook(userId, bookId);
    const { included, pendingChapters, progress } =
      await this.reviewedPayload(bookId);

    if (included.length === 0) {
      return {
        allowed: false as const,
        reason: 'CHAPTER_NOT_REVIEWED',
        included_chapters: [] as typeof included,
        pending_chapters: pendingChapters,
        cover_kind: 'default' as const,
        downloadable: false,
        title_suggest_available: false,
        progress,
      };
    }

    return {
      allowed: true as const,
      included_chapters: included,
      pending_chapters: pendingChapters,
      cover_kind: 'default' as const,
      downloadable: true,
      title_suggest_available: progress >= 0.8,
      progress,
    };
  }

  /** api-spec §10.2 — 스냅샷이 같으면 재사용 */
  async generate(userId: string, bookId: string) {
    const book = await this.bookAccess.requireOwnedBook(userId, bookId);
    const { included, chapters, reviews } = await this.reviewedPayload(bookId);
    if (included.length === 0) {
      throw new ApiException(ERROR_CODE.EBOOK.CHAPTER_NOT_REVIEWED);
    }

    const snapshot: SnapshotItem[] = included.map((c) => ({
      chapter_id: c.id,
      version: c.version,
    }));

    const existing = await this.findReusableExport(bookId, snapshot);
    if (existing) {
      return {
        export_id: existing.id,
        status: existing.status,
        chapter_snapshot: existing.chapterSnapshot,
      };
    }

    const exportRow = await this.exports.save(
      this.exports.create({
        bookId,
        format: 'pdf',
        chapterSnapshot: snapshot,
        coverKind: 'default',
        status: JobStatus.PROCESSING,
      }),
    );

    try {
      const bodyByChapter = new Map(
        reviews.map((r) => [r.userChapterId, r.body]),
      );
      const pdfChapters = chapters
        .filter((c) => bodyByChapter.has(c.id))
        .map((c) => ({
          order: c.sortOrder,
          title: c.title,
          body: bodyByChapter.get(c.id) ?? '',
        }));

      const objectKey = path.join('ebooks', bookId, `${exportRow.id}.pdf`);
      const absolute = this.resolveStoragePath(objectKey);
      await writeEbookPdf({
        filePath: absolute,
        title: book.title,
        authorName: book.authorName,
        chapters: pdfChapters,
      });
      const stat = await fs.promises.stat(absolute);

      const asset = await this.media.save(
        this.media.create({
          bookId,
          kind: MediaKind.DOCUMENT,
          source: MediaSource.SYSTEM,
          objectKey,
          mimeType: 'application/pdf',
          byteSize: String(stat.size),
          checksum: null,
          durationMs: null,
          expiresAt: null,
          deletedAt: null,
        }),
      );

      exportRow.status = JobStatus.COMPLETED;
      exportRow.mediaAssetId = asset.id;
      exportRow.mediaAsset = asset;
      exportRow.errorCode = null;
      await this.exports.save(exportRow);

      return {
        export_id: exportRow.id,
        status: exportRow.status,
        chapter_snapshot: exportRow.chapterSnapshot,
      };
    } catch {
      exportRow.status = JobStatus.FAILED;
      exportRow.errorCode = 'EBOOK_GENERATE_FAILED';
      await this.exports.save(exportRow);
      throw new ApiException(ERROR_CODE.EBOOK.GENERATE_FAILED);
    }
  }

  /** 인증된 PDF 스트림용 절대 경로 */
  async resolveFilePath(userId: string, bookId: string): Promise<{
    absolutePath: string;
    exportId: string;
    fileName: string;
  }> {
    await this.bookAccess.requireOwnedBook(userId, bookId);
    const { included } = await this.reviewedPayload(bookId);
    if (included.length === 0) {
      throw new ApiException(ERROR_CODE.EBOOK.CHAPTER_NOT_REVIEWED);
    }

    const snapshot: SnapshotItem[] = included.map((c) => ({
      chapter_id: c.id,
      version: c.version,
    }));

    let exportRow = await this.findReusableExport(bookId, snapshot);
    if (!exportRow || exportRow.status !== JobStatus.COMPLETED) {
      // 파일이 없으면 한 번 생성
      await this.generate(userId, bookId);
      exportRow = await this.findReusableExport(bookId, snapshot);
    }

    if (
      !exportRow ||
      exportRow.status !== JobStatus.COMPLETED ||
      !exportRow.mediaAssetId
    ) {
      throw new ApiException(ERROR_CODE.EBOOK.NOT_READY);
    }

    const asset = await this.media.findOne({
      where: { id: exportRow.mediaAssetId },
    });
    if (!asset || asset.deletedAt) {
      throw new ApiException(ERROR_CODE.EBOOK.NOT_READY);
    }

    const absolute = this.resolveStoragePath(asset.objectKey);
    if (!fs.existsSync(absolute)) {
      throw new ApiException(ERROR_CODE.EBOOK.NOT_READY);
    }

    return {
      absolutePath: absolute,
      exportId: exportRow.id,
      fileName: `lifelegacy-${bookId.slice(0, 8)}.pdf`,
    };
  }

  /** api-spec §10.3 — 진행률 80% 이상 */
  async suggestTitles(userId: string, bookId: string) {
    const book = await this.bookAccess.requireOwnedBook(userId, bookId);
    const { progress } = await this.reviewedPayload(bookId);
    if (progress < 0.8) {
      throw new ApiException(ERROR_CODE.EBOOK.TITLE_PROGRESS);
    }

    const author = book.authorName?.trim() || '나';
    const base = book.title?.trim() || '나의 이야기';
    return {
      titles: [
        `${author}의 ${base}`,
        '볕이 좋던 날의 기록',
        '남겨 두고 싶은 이름',
        '우리가 걸어온 시간',
      ],
    };
  }

  async updateMetadata(
    userId: string,
    bookId: string,
    input: { title?: string },
  ) {
    const book = await this.bookAccess.requireOwnedBook(userId, bookId);
    if (input.title != null) {
      const next = input.title.trim();
      if (next.length === 0 || next.length > 100) {
        throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
      }
      book.title = next;
      await this.books.save(book);
    }
    return {
      id: book.id,
      title: book.title,
      author_name: book.authorName,
    };
  }

  private async reviewedPayload(bookId: string) {
    const chapters = await this.chaptersRepository.findAllByBook(bookId);
    const { total, answered } =
      await this.chaptersRepository.countByBook(bookId);
    const progress = total === 0 ? 0 : answered / total;

    const reviews = await this.reviews.find({
      where: {
        userChapterId: In(chapters.map((c) => c.id)),
        status: ReviewStatus.REVIEWED,
      },
    });
    const reviewedIds = new Set(reviews.map((r) => r.userChapterId));
    const versionByChapter = new Map(
      reviews.map((r) => [r.userChapterId, r.version]),
    );

    const included = chapters
      .filter((c) => reviewedIds.has(c.id))
      .map((c) => ({
        id: c.id,
        order: c.sortOrder,
        title: c.title,
        version: versionByChapter.get(c.id) ?? 1,
      }));

    return {
      chapters,
      reviews,
      included,
      pendingChapters: chapters.length - included.length,
      progress,
      firstChapterDone: chapters.some(
        (c) => c.sortOrder === 1 && c.status === ChapterStatus.DONE,
      ),
    };
  }

  private async findReusableExport(
    bookId: string,
    snapshot: SnapshotItem[],
  ): Promise<EbookExportModel | null> {
    const latest = await this.exports.findOne({
      where: { bookId, format: 'pdf', status: JobStatus.COMPLETED },
      order: { createdAt: 'DESC' },
    });
    if (!latest) return null;
    if (!this.sameSnapshot(latest.chapterSnapshot, snapshot)) return null;
    return latest;
  }

  private sameSnapshot(stored: unknown, next: SnapshotItem[]): boolean {
    if (!Array.isArray(stored)) return false;
    const normalize = (items: SnapshotItem[]) =>
      [...items]
        .map((i) => `${i.chapter_id}:${i.version}`)
        .sort()
        .join('|');
    const asItems = (stored as SnapshotItem[]).map((i) => ({
      chapter_id: String(i.chapter_id),
      version: Number(i.version),
    }));
    return normalize(asItems) === normalize(next);
  }

  private resolveStoragePath(objectKey: string): string {
    const root =
      process.env.EBOOK_STORAGE_DIR?.trim() ||
      path.join(process.cwd(), 'storage');
    return path.join(root, objectKey);
  }
}
