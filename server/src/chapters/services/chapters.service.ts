import { Injectable } from '@nestjs/common';

import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { ChapterStatus } from '../const/chapter-status.enum';
import { QuestionStatus } from '../const/question-status.enum';
import { ChapterResponseDto } from '../dto/response/chapter-response.dto';
import { QuestionResponseDto } from '../dto/response/question-response.dto';
import { UserQuestionModel } from '../entities/user-question.entity';
import { ChaptersRepository } from '../repositories/chapters.repository';

@Injectable()
export class ChaptersService {
  constructor(private readonly chaptersRepository: ChaptersRepository) {}

  async getChapters(userId: string): Promise<ChapterResponseDto[]> {
    const chapters = await this.chaptersRepository.findAllByUser(userId);

    const result: ChapterResponseDto[] = [];
    for (const chapter of chapters) {
      // 다음 질문 제목은 진행 중인 장에만 붙는다. 잠긴 장에 붙이면
      // 아직 못 여는 질문을 미리 보여주는 셈이다.
      const next =
        chapter.status === ChapterStatus.WRITING
          ? await this.chaptersRepository.findFirstPending(chapter.id)
          : null;
      result.push(ChapterResponseDto.from(chapter, next?.text ?? null));
    }

    return result;
  }

  /** 지금 답할 질문. 모든 장을 끝냈으면 null(컨트롤러가 204로 바꾼다) */
  async getCurrentQuestion(userId: string): Promise<UserQuestionModel | null> {
    const chapter = await this.chaptersRepository.findWritingChapter(userId);
    if (!chapter) {
      return null;
    }

    return await this.chaptersRepository.findFirstPending(chapter.id);
  }

  /**
   * 사용자의 질문을 집어 온다. 잠긴 장이면 막는다.
   *
   * 다른 사용자의 질문 id를 넣으면 **404**다 — 403으로 답하면 "그 id가
   * 있긴 하다"는 걸 알려 주는 셈이다.
   */
  async getOwnedQuestion(
    userId: string,
    questionId: string,
  ): Promise<UserQuestionModel> {
    const question = await this.chaptersRepository.findQuestionById(questionId);
    if (!question || question.userChapter.user.id !== userId) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    if (question.userChapter.status === ChapterStatus.LOCKED) {
      throw new ApiException(ERROR_CODE.WRITE.CHAPTER_LOCKED);
    }

    return question;
  }

  async updateQuestionText(
    userId: string,
    questionId: string,
    text: string,
  ): Promise<QuestionResponseDto> {
    const question = await this.getOwnedQuestion(userId, questionId);

    // 이미 답한 질문의 문구를 바꾸면 저장된 원고와 어긋난다.
    if (question.status !== QuestionStatus.PENDING) {
      throw new ApiException(ERROR_CODE.WRITE.ALREADY_ANSWERED);
    }

    question.text = text;
    question.isEdited = true;
    const saved = await this.chaptersRepository.saveQuestion(question);

    return QuestionResponseDto.from(saved);
  }
}
