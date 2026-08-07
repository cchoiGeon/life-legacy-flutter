import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { CreatePrintOrderDto } from './dto/create-print-order.dto';
import { PrintOrderResponseDto } from './dto/print-order-response.dto';
import { PrintOrderService } from './services/print-order.service';

@ApiTags('Print Orders API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('print-orders')
export class PrintOrderController {
  constructor(private readonly printOrders: PrintOrderService) {}

  @ApiOperation({
    summary: '종이책(인쇄본) 신청 stub — 앱 결제 없음, 신청만 접수',
  })
  @ApiResponse({ status: 201, type: PrintOrderResponseDto })
  @HttpCode(201)
  @Post()
  create(@UserId() userId: string, @Body() dto: CreatePrintOrderDto) {
    return this.printOrders.create(userId, dto);
  }
}
