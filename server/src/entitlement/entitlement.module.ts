import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { ConfigModule } from '@nestjs/config';
import { EntitlementLedgerModel } from './entities/entitlement-ledger.entity';
import { UserEntitlementModel } from './entities/user-entitlement.entity';
import { EntitlementService } from './services/entitlement.service';

@Module({
  imports: [
    ConfigModule,
    TypeOrmModule.forFeature([UserEntitlementModel, EntitlementLedgerModel]),
  ],
  providers: [EntitlementService],
  exports: [EntitlementService, TypeOrmModule],
})
export class EntitlementModule {}
