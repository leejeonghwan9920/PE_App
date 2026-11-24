package com.umc.movie.docs;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import java.lang.annotation.*;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Operation(summary="로그인", description="공개 API입니다. 발급받은 accessToken을 Authorize에 입력하세요. Bearer 접두사는 Swagger가 붙입니다. 응답은 캐시하지 않습니다.")
@ApiResponses({
    @ApiResponse(responseCode="200", description="COMMON200: 로그인 성공", content=@Content(
        mediaType="application/json", examples=@ExampleObject(value="""
        {"isSuccess":true,"code":"COMMON200","message":"로그인에 성공했습니다.","result":{"nickname":"영화조아","accessToken":"<발급된 JWT>"}}
        """))),
    @ApiResponse(responseCode="400", description="COMMON400: 입력값 검증 실패", content=@Content(mediaType="application/json", schema=@io.swagger.v3.oas.annotations.media.Schema(implementation=ApiErrorResponse.class), examples=@ExampleObject(value="""
        {"isSuccess":false,"code":"COMMON400","message":"입력값을 확인해주세요.","result":null}
        """))),
    @ApiResponse(responseCode="401", description="AUTH401_1: 이메일 또는 비밀번호 불일치", content=@Content(
        schema=@io.swagger.v3.oas.annotations.media.Schema(implementation=ApiErrorResponse.class), mediaType="application/json", examples=@ExampleObject(value="""
        {"isSuccess":false,"code":"AUTH401_1","message":"이메일 또는 비밀번호가 올바르지 않습니다.","result":null}
        """)))
})
public @interface LoginDocs {}
