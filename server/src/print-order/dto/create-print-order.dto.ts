import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreatePrintOrderDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  book_id: string;

  @ApiProperty({ example: 4, description: '인쇄 부수 (4권부터)' })
  @IsInt()
  @Min(4)
  @Max(50)
  quantity: number;

  @ApiPropertyOptional({ description: '배송 요청사항' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
