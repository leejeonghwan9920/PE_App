package com.umc.movie.docs;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import java.lang.annotation.*;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Operation(summary = "회원가입", description = "공개 API입니다. 이메일·닉네임은 중복될 수 없으며 비밀번호는 bcrypt로 저장합니다.")
@ApiResponses({
    @ApiResponse(responseCode="201", description="COMMON201: 회원 생성", content=@Content(
        mediaType="application/json", examples=@ExampleObject(value="""
        {"isSuccess":true,"code":"COMMON201","message":"회원가입에 성공했습니다.","result":{"memberId":1,"nickname":"영화조아","email":"challenger@example.com"}}
        """))),
    @ApiResponse(responseCode="400", description="COMMON400: 입력 형식/필수값 검증 실패", content=@Content(mediaType="application/json", schema=@io.swagger.v3.oas.annotations.media.Schema(implementation=ApiErrorResponse.class), examples=@ExampleObject(value="""
        {"isSuccess":false,"code":"COMMON400","message":"입력값을 확인해주세요.","result":null}
        """))),
    @ApiResponse(responseCode="409", description="MEMBER4091: 이메일 중복 / MEMBER4092: 닉네임 중복", content=@Content(mediaType="application/json", schema=@io.swagger.v3.oas.annotations.media.Schema(implementation=ApiErrorResponse.class), examples=@ExampleObject(value="""
        {"isSuccess":false,"code":"MEMBER4091","message":"이미 사용 중인 이메일입니다.","result":null}
        """)))
})
public @interface SignupDocs {}
