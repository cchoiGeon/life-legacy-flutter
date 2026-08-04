import { Module } from '@nestjs/common';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { BookAccessModule } from 'src/book/book-access.module';
import { ChaptersModule } from 'src/chapters/chapters.module';
import { HomeController } from './home.controller';
import { HomeService } from './services/home.service';

@Module({
  imports: [AuthGuardModule, BookAccessModule, ChaptersModule],
  controllers: [HomeController],
  providers: [HomeService],
})
export class HomeModule {}
