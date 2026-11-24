package com.umc.movie.controller;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties="spring.datasource.url=jdbc:h2:mem:movie-week09-docs;MODE=MySQL;DB_CLOSE_DELAY=-1")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OpenApiContractTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    JsonNode specification() throws Exception {
        return json.readTree(mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
    }
    @Test @DisplayName("9주차: 공개 API는 자물쇠가 없고 보호 API만 bearerAuth를 요구한다")
    void separatesPublicAndProtectedOperations() throws Exception {
        var spec=specification();
        assertThat(spec.at("/security").isMissingNode()).isTrue();
        assertThat(spec.at("/paths/~1members/post/security").isMissingNode()).isTrue();
        assertThat(spec.at("/paths/~1auth~1login/post/security").isMissingNode()).isTrue();
        assertThat(spec.at("/paths/~1favorites/post/security/0/bearerAuth").isArray()).isTrue();
        assertThat(spec.at("/components/securitySchemes/bearerAuth/scheme").asText()).isEqualTo("bearer");
        for(var parameter:spec.at("/paths/~1favorites/post/parameters")) {
            assertThat(parameter.path("name").asText()).isNotEqualTo("memberId");
        }
    }
    @Test @DisplayName("9주차: 문서에 성공/실패 코드와 요청 예시가 포함된다")
    void documentsResponsesAndRequestExamples() throws Exception {
        var spec=specification();
        var responses=spec.at("/paths/~1favorites/post/responses");
        for(var status:new String[]{"201","400","401","404","409"}) {
            assertThat(responses.has(status)).isTrue();
        }
        assertThat(responses.path("409").toString()).contains("FAVORITE409_1");
        assertThat(spec.at("/components/schemas/CreateFavoriteRequest/properties/movieId/example").asInt())
            .isEqualTo(550);
        assertThat(spec.at("/components/schemas/SignupRequest/properties").has("passwordWithinBcryptLimit")).isFalse();
        for(var path:new String[]{"~1members", "~1auth~1login", "~1favorites"}) {
            assertThat(spec.at("/paths/"+path+"/post/responses/400/content/application~1json/schema/$ref").asText())
                .endsWith("/ApiErrorResponse");
        }
        mvc.perform(get("/swagger-ui")).andExpect(status().is3xxRedirection());
    }
}
