package com.umc.movie.controller;
import com.umc.movie.auth.JwtService;
import com.umc.movie.entity.Favorite;
import com.umc.movie.entity.Member;
import com.umc.movie.repository.FavoriteRepository;
import com.umc.movie.repository.MemberRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties="spring.datasource.url=jdbc:h2:mem:movie-week09;MODE=MySQL;DB_CLOSE_DELAY=-1")
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class FavoriteApiTest {
    @Autowired MockMvc mvc;
    @Autowired JwtService jwt;
    @Autowired MemberRepository members;
    @MockitoSpyBean FavoriteRepository favorites;
    String auth;
    @BeforeEach
    void setup() {
        var member=members.save(new Member("week09-api@example.com","not-used-for-login","통합회원"));
        auth="Bearer "+jwt.issue(member.getMemberId());
        clearInvocations(favorites);
    }
    @Test @DisplayName("9주차: 토큰 없이 등록하면 401/AUTH401_2")
    void rejectsMissingToken() throws Exception {
        mvc.perform(post("/favorites").contentType(MediaType.APPLICATION_JSON).content("{\"movieId\":550}"))
            .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.isSuccess").value(false))
            .andExpect(jsonPath("$.code").value("AUTH401_2"));
    }
    @Test @DisplayName("9주차: 토큰으로 등록하면 201/COMMON201/movieId")
    void createsFavorite() throws Exception {
        mvc.perform(post("/favorites").header("Authorization",auth).contentType(MediaType.APPLICATION_JSON)
                .content("{\"movieId\":550}"))
            .andExpect(status().isCreated()).andExpect(jsonPath("$.code").value("COMMON201"))
            .andExpect(jsonPath("$.result.movieId").value(550));
    }
    @Test @DisplayName("9주차: 중복 등록은 409이며 불필요한 두 번째 DB 저장을 하지 않는다")
    void rejectsDuplicateBeforeWriting() throws Exception {
        mvc.perform(post("/favorites").header("Authorization",auth).contentType(MediaType.APPLICATION_JSON)
                .content("{\"movieId\":550}"))
            .andExpect(status().isCreated());
        clearInvocations(favorites);
        mvc.perform(post("/favorites").header("Authorization",auth).contentType(MediaType.APPLICATION_JSON)
                .content("{\"movieId\":550}"))
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("FAVORITE409_1"));
        verify(favorites,never()).saveAndFlush(any(Favorite.class));
    }
    @Test @DisplayName("9주차: 미등록 영화는 200/isFavorite=false")
    void returnsFalseForMissingFavorite() throws Exception {
        mvc.perform(get("/favorites/550").header("Authorization",auth))
            .andExpect(status().isOk()).andExpect(jsonPath("$.result.isFavorite").value(false));
    }
    @Test @DisplayName("9주차: API 문서는 토큰 없이 공개된다")
    void servesPublicApiDocs() throws Exception {
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk());
    }
}
