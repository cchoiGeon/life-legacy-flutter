import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PrintOrderResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  book_id: string;

  @ApiProperty()
  quantity: number;

  @ApiProperty()
  status: string;

  @ApiPropertyOptional()
  note: string | null;

  @ApiProperty()
  created_at: string;
}
