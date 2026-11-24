package com.umc.movie.service;
import com.umc.movie.entity.Favorite;
import com.umc.movie.entity.Member;
import com.umc.movie.exception.ApiException;
import com.umc.movie.repository.FavoriteRepository;
import com.umc.movie.repository.MemberRepository;
import java.util.Optional;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FavoriteServiceTest {
    @Mock FavoriteRepository favorites;
    @Mock MemberRepository members;
    @InjectMocks FavoriteService service;
    final Member member = new Member("week09-unit@example.com", "not-a-login-password", "단위회원");

    @Test @DisplayName("9주차: 새 즐겨찾기는 저장하고 movieId를 반환한다")
    void createsNewFavorite() {
        // given
        given(members.findById(1L)).willReturn(Optional.of(member));
        given(favorites.existsByMember_MemberIdAndMovieId(1L, 550L)).willReturn(false);
        given(favorites.saveAndFlush(any(Favorite.class))).willAnswer(call -> call.getArgument(0));
        // when
        var result = service.create(1L, 550L);
        // then
        assertThat(result.movieId()).isEqualTo(550L);
        verify(favorites).saveAndFlush(any(Favorite.class));
    }

    @Test @DisplayName("9주차: 중복이면 FAVORITE409_1이고 DB 저장을 시도하지 않는다")
    void rejectsDuplicateBeforeSaving() {
        // given
        given(members.findById(1L)).willReturn(Optional.of(member));
        given(favorites.existsByMember_MemberIdAndMovieId(1L, 550L)).willReturn(true);
        // when / then
        assertThatThrownBy(() -> service.create(1L, 550L)).isInstanceOfSatisfying(ApiException.class,
            error -> { assertThat(error.getStatus()).isEqualTo(HttpStatus.CONFLICT);
                assertThat(error.getCode()).isEqualTo("FAVORITE409_1"); });
        verify(favorites, never()).saveAndFlush(any(Favorite.class));
    }
}
