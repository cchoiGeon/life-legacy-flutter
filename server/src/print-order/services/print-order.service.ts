import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { BookAccessService } from 'src/book/services/book-access.service';
import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { SettingsService } from 'src/settings/services/settings.service';
import { CreatePrintOrderDto } from '../dto/create-print-order.dto';
import { PrintOrderResponseDto } from '../dto/print-order-response.dto';
import { PrintOrderModel } from '../entities/print-order.entity';

@Injectable()
export class PrintOrderService {
  constructor(
    @InjectRepository(PrintOrderModel)
    private readonly orders: Repository<PrintOrderModel>,
    private readonly books: BookAccessService,
    private readonly settings: SettingsService,
  ) {}

  async create(
    userId: string,
    dto: CreatePrintOrderDto,
  ): Promise<PrintOrderResponseDto> {
    await this.books.requireOwnedBook(userId, dto.book_id);

    const address = await this.settings.getAddress(userId);
    if (
      !address.recipient?.trim() ||
      !address.phone?.trim() ||
      !address.postal_code?.trim() ||
      !address.line1?.trim()
    ) {
      throw new ApiException(
        ERROR_CODE.COMMON.INVALID_REQUEST,
        '인쇄본 배송지를 먼저 등록해 주세요',
      );
    }

    const saved = await this.orders.save(
      this.orders.create({
        userId,
        bookId: dto.book_id,
        quantity: dto.quantity,
        note: dto.note?.trim() || null,
        status: 'requested',
        addressSnapshot: {
          recipient: address.recipient,
          phone: address.phone,
          postal_code: address.postal_code,
          line1: address.line1,
          line2: address.line2 ?? '',
        },
      }),
    );

    return this.toDto(saved);
  }

  private toDto(row: PrintOrderModel): PrintOrderResponseDto {
    return {
      id: row.id,
      book_id: row.bookId,
      quantity: row.quantity,
      status: row.status,
      note: row.note,
      created_at: row.createdAt.toISOString(),
    };
  }
}
