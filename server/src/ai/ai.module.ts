import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AiGenerationLogModel } from './entities/ai-generation-log.entity';
import { PromptTemplateModel } from './entities/prompt-template.entity';
import { AiService } from './services/ai.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([PromptTemplateModel, AiGenerationLogModel]),
  ],
  providers: [AiService],
  exports: [AiService],
})
export class AiModule {}
