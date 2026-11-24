package com.umc.movie.controller;
import io.swagger.v3.oas.annotations.Parameter;

import com.umc.movie.auth.LoginMember;
import com.umc.movie.dto.ApiResponse;
import com.umc.movie.dto.CreateFavoriteRequest;
import com.umc.movie.dto.FavoriteResponse;
import com.umc.movie.dto.FavoriteStatusResponse;
import com.umc.movie.service.FavoriteService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/favorites")
@RequiredArgsConstructor
public class FavoriteController {
    private final FavoriteService favorites;

    @com.umc.movie.docs.FavoriteCreateDocs
    @PostMapping
    public ResponseEntity<ApiResponse<FavoriteResponse>> create(
        @Parameter(hidden = true) @LoginMember Long memberId, @Valid @RequestBody CreateFavoriteRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.created("즐겨찾기를 등록했습니다.", favorites.create(memberId, request.movieId())));
    }

    @io.swagger.v3.oas.annotations.Operation(summary="내 즐겨찾기 목록", description="최신 등록 순서이며, 없으면 result는 빈 배열입니다.")
    @GetMapping
    public ApiResponse<List<FavoriteResponse>> list(@Parameter(hidden = true) @LoginMember Long memberId) {
        return ApiResponse.ok("즐겨찾기 목록을 조회했습니다.", favorites.list(memberId));
    }

    @io.swagger.v3.oas.annotations.Operation(summary="즐겨찾기 여부", description="즐겨찾기하지 않은 영화는 오류가 아니라 200/isFavorite=false입니다.")
    @GetMapping("/{movieId}")
    public ApiResponse<FavoriteStatusResponse> status(
        @Parameter(hidden = true) @LoginMember Long memberId, @PathVariable @Positive Long movieId
    ) {
        return ApiResponse.ok("즐겨찾기 여부를 조회했습니다.",
            new FavoriteStatusResponse(favorites.isFavorite(memberId, movieId)));
    }

    @io.swagger.v3.oas.annotations.Operation(summary="즐겨찾기 해제", description="성공은 200/result=null이며 없는 즐겨찾기는 404/FAVORITE404_1입니다.")
    @DeleteMapping("/{movieId}")
    public ApiResponse<Void> delete(@Parameter(hidden = true) @LoginMember Long memberId, @PathVariable @Positive Long movieId) {
        favorites.delete(memberId, movieId);
        return ApiResponse.ok("즐겨찾기를 해제했습니다.", null);
    }
}
