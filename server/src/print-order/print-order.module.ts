import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { BookAccessModule } from 'src/book/book-access.module';
import { SettingsModule } from 'src/settings/settings.module';
import { PrintOrderModel } from './entities/print-order.entity';
import { PrintOrderController } from './print-order.controller';
import { PrintOrderService } from './services/print-order.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([PrintOrderModel]),
    AuthGuardModule,
    BookAccessModule,
    SettingsModule,
  ],
  controllers: [PrintOrderController],
  providers: [PrintOrderService],
})
export class PrintOrderModule {}
