package com.umc.movie.config;

import com.umc.movie.auth.LoginMember;
import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import java.util.Arrays;
import org.springdoc.core.customizers.OperationCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
public class OpenApiConfig {
    @Bean
    OpenAPI movieLogOpenApi() {
        return new OpenAPI().info(new Info().title("MovieLog API")
            .description("UMC 9주차: 회원가입·로그인·즐겨찾기 API 문서와 테스트")
            .version("week09"))
            .components(new Components().addSecuritySchemes("bearerAuth",
                new SecurityScheme().type(SecurityScheme.Type.HTTP)
                    .scheme("bearer").bearerFormat("JWT")));
    }

    /** Apply the lock only to methods that actually resolve an authenticated member. */
    @Bean
    OperationCustomizer loginMemberSecurity() {
        return (operation, handler) -> {
            boolean authenticated = Arrays.stream(handler.getMethodParameters())
                .anyMatch(parameter -> parameter.hasParameterAnnotation(LoginMember.class));
            if (authenticated) operation.addSecurityItem(new SecurityRequirement().addList("bearerAuth"));
            return operation;
        };
    }
}
