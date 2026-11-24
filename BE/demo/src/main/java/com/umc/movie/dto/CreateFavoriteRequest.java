package com.umc.movie.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record CreateFavoriteRequest(
    @NotNull(message = "영화 ID는 필수입니다.")
    @Positive(message = "영화 ID는 양수여야 합니다.")
    @io.swagger.v3.oas.annotations.media.Schema(description="TMDB 영화 ID", example="550", minimum="1")
    Long movieId
) {}
