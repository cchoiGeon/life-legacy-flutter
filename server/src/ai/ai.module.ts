import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { AdminPromptController } from './admin-prompt.controller';
import { AiGenerationLogModel } from './entities/ai-generation-log.entity';
import { PromptTemplateModel } from './entities/prompt-template.entity';
import { AiService } from './services/ai.service';

@Module({
  imports: [
    HttpModule.register({ timeout: 60_000 }),
    TypeOrmModule.forFeature([PromptTemplateModel, AiGenerationLogModel]),
    AuthGuardModule,
  ],
  controllers: [AdminPromptController],
  providers: [AiService],
  exports: [AiService],
})
export class AiModule {}
