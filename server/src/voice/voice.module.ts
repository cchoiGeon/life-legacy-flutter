import { Module } from '@nestjs/common';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { ClovaVoiceClient } from './clova-voice.client';
import { VoiceController } from './voice.controller';
import { VoiceService } from './voice.service';

@Module({
  imports: [AuthGuardModule],
  controllers: [VoiceController],
  providers: [ClovaVoiceClient, VoiceService],
  exports: [VoiceService, ClovaVoiceClient],
})
export class VoiceModule {}
