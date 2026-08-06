import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { IsOptional, IsString, MinLength } from 'class-validator';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { AiService } from './services/ai.service';

class UpsertPromptDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsString()
  @MinLength(1)
  body: string;
}

class CreatePromptDto extends UpsertPromptDto {
  @IsString()
  @MinLength(1)
  key: string;
}

/**
 * 작성·종합 AI 프롬프트 관리. 웹 admin 연동 예정.
 * 지금은 AccessTokenGuard만 — 관리자 역할 가드는 추후 추가.
 */
@ApiTags('Admin Prompts API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('admin/prompts')
export class AdminPromptController {
  constructor(private readonly ai: AiService) {}

  @ApiOperation({ summary: '프롬프트 목록 (DB + 시드)' })
  @Get()
  async list() {
    return { items: await this.ai.listPrompts() };
  }

  @ApiOperation({ summary: '프롬프트 단건' })
  @Get(':key')
  get(@Param('key') key: string) {
    return this.ai.getPrompt(key);
  }

  @ApiOperation({ summary: '프롬프트 생성' })
  @Post()
  create(@UserId() userId: string, @Body() dto: CreatePromptDto) {
    return this.ai.upsertPrompt(dto.key, {
      title: dto.title,
      body: dto.body,
      updatedBy: userId,
    });
  }

  @ApiOperation({ summary: '프롬프트 수정' })
  @Patch(':key')
  update(
    @UserId() userId: string,
    @Param('key') key: string,
    @Body() dto: UpsertPromptDto,
  ) {
    return this.ai.upsertPrompt(key, {
      title: dto.title,
      body: dto.body,
      updatedBy: userId,
    });
  }
}
