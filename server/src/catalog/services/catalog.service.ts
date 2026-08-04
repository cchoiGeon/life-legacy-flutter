import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { BookAccessService } from 'src/book/services/book-access.service';
import { UserChapterModel } from 'src/chapters/entities/user-chapter.entity';
import { ChapterTemplateModel } from '../entities/chapter-template.entity';
import { QuestionTemplateModel } from '../entities/question-template.entity';

@Injectable()
export class CatalogService {
  constructor(
    private readonly bookAccess: BookAccessService,
    @InjectRepository(ChapterTemplateModel)
    private readonly templates: Repository<ChapterTemplateModel>,
    @InjectRepository(QuestionTemplateModel)
    private readonly questions: Repository<QuestionTemplateModel>,
    @InjectRepository(UserChapterModel)
    private readonly userChapters: Repository<UserChapterModel>,
  ) {}

  async listChaptersForBook(userId: string, bookId: string) {
    await this.bookAccess.requireOwnedBook(userId, bookId);

    const templates = await this.templates.find({
      where: { isActive: true },
      order: { sortOrder: 'ASC' },
    });

    const existing = await this.userChapters.find({
      where: { bookId },
      relations: { chapterTemplate: true },
    });
    const addedTemplateIds = new Set(
      existing
        .map((c) => c.chapterTemplate?.id)
        .filter((id): id is string => !!id),
    );

    return Promise.all(
      templates.map(async (t) => {
        const questionCount = await this.questions.count({
          where: { chapterTemplate: { id: t.id }, isActive: true },
        });
        return {
          id: t.id,
          title: t.title,
          question_count: questionCount,
          already_added: addedTemplateIds.has(t.id),
        };
      }),
    );
  }
}
