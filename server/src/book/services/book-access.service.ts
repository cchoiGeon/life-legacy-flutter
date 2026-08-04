import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { BookModel } from '../entities/book.entity';

/**
 * 모든 :bookId 조회의 단일 진입점.
 * 나중에 book_participant가 들어와도 여기만 고치면 된다.
 */
@Injectable()
export class BookAccessService {
  constructor(
    @InjectRepository(BookModel)
    private readonly books: Repository<BookModel>,
  ) {}

  /** 소유자에게만 허용. 없거나 남의 책이면 404. */
  async requireOwnedBook(
    userId: string,
    bookId: string,
  ): Promise<BookModel> {
    const book = await this.books.findOne({ where: { id: bookId } });
    if (!book || book.ownerUserId !== userId) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }
    return book;
  }

  async findOwnedBooks(userId: string): Promise<BookModel[]> {
    return await this.books.find({
      where: { ownerUserId: userId },
      order: { createdAt: 'DESC' },
    });
  }
}
