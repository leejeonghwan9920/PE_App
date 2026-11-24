package com.umc.movie.docs;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "공통 실패 응답. result는 항상 null입니다.")
public record ApiErrorResponse(
    @Schema(example = "false", allowableValues = {"false"}) boolean isSuccess,
    @Schema(example = "COMMON400") String code,
    @Schema(example = "입력값을 확인해주세요.") String message,
    @Schema(nullable = true, description = "실패 시 null") Void result
) {}
