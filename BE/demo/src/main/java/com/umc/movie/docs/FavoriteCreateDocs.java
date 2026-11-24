package com.umc.movie.docs;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import java.lang.annotation.*;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Operation(summary="즐겨찾기 등록", description="JWT에서 회원을 식별합니다. body에는 TMDB movieId만 보냅니다. 같은 회원·영화의 중복 등록은 409입니다.")
@ApiResponses({
    @ApiResponse(responseCode="201", description="COMMON201: 즐겨찾기 등록 성공", content=@Content(
        mediaType="application/json", examples=@ExampleObject(value="""
        {"isSuccess":true,"code":"COMMON201","message":"즐겨찾기를 등록했습니다.","result":{"favoriteId":1,"movieId":550,"createdAt":"2026-11-24T12:00:00"}}
        """))),
    @ApiResponse(responseCode="400", description="COMMON400: movieId 누락/양수가 아닌 값", content=@Content(mediaType="application/json", schema=@io.swagger.v3.oas.annotations.media.Schema(implementation=ApiErrorResponse.class), examples=@ExampleObject(value="""
        {"isSuccess":false,"code":"COMMON400","message":"영화 ID는 양수여야 합니다.","result":null}
        """))),
    @ApiResponse(responseCode="401", description="AUTH401_2: 토큰 없음 / AUTH401_3: 무효 / AUTH401_4: 만료", content=@Content(
        schema=@io.swagger.v3.oas.annotations.media.Schema(implementation=ApiErrorResponse.class), mediaType="application/json", examples={
          @ExampleObject(name="토큰 없음", value="""
          {"isSuccess":false,"code":"AUTH401_2","message":"로그인이 필요한 요청입니다.","result":null}
          """),
          @ExampleObject(name="무효 토큰", value="""
          {"isSuccess":false,"code":"AUTH401_3","message":"유효하지 않은 토큰입니다.","result":null}
          """),
          @ExampleObject(name="만료 토큰", value="""
          {"isSuccess":false,"code":"AUTH401_4","message":"토큰이 만료되었습니다. 다시 로그인해주세요.","result":null}
          """)
        })),
    @ApiResponse(responseCode="404", description="MEMBER404_1: 회원 없음", content=@Content(mediaType="application/json", schema=@io.swagger.v3.oas.annotations.media.Schema(implementation=ApiErrorResponse.class), examples=@ExampleObject(value="""
        {"isSuccess":false,"code":"MEMBER404_1","message":"해당 회원을 찾을 수 없습니다.","result":null}
        """))),
    @ApiResponse(responseCode="409", description="FAVORITE409_1: 이미 등록한 영화", content=@Content(
        schema=@io.swagger.v3.oas.annotations.media.Schema(implementation=ApiErrorResponse.class), mediaType="application/json", examples=@ExampleObject(value="""
        {"isSuccess":false,"code":"FAVORITE409_1","message":"이미 이 영화를 즐겨찾기하셨습니다.","result":null}
        """)))
})
public @interface FavoriteCreateDocs {}
