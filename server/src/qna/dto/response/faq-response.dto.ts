import { ApiProperty } from '@nestjs/swagger';

export class FaqItemDto {
  @ApiProperty() question: string;
  @ApiProperty() answer: string;
}

export class FaqSectionDto {
  @ApiProperty() id: string;
  @ApiProperty() label: string;
  @ApiProperty({ type: [FaqItemDto] }) items: FaqItemDto[];
}

export class FaqCategoryDto {
  @ApiProperty() id: string;
  @ApiProperty() label: string;
}

export class FaqResponseDto {
  @ApiProperty({ type: [FaqCategoryDto] }) categories: FaqCategoryDto[];
  @ApiProperty({ type: [FaqSectionDto] }) sections: FaqSectionDto[];
}
