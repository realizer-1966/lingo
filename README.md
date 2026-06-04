# Lingo 학습 — 여행 & 골프 구문 학습 PWA + Live Translate

여행·골프 등 실전에서 바로 써먹는 영어 구문을 4개국어(영어/일본어/한국어/중국어)로 학습하는 오프라인 우선 PWA. 백엔드 없이 정적 파일만으로 동작하며, 홈 화면에 설치해서 플래시카드/퀴즈/음성학습을 즉시 사용할 수 있다.  
**M1부터 Live Translate(실시간 음성 번역) 통합** — 랜딩 카드를 탭하면 Gemini Live API 기반 97개 언어 번역기(`live-translator`)가 iframe으로 임베드된다.

🌐 **배포**: <https://realizer-1966.github.io/lingo/>
🛠️ **저장소**: <https://github.com/realizer-1966/lingo>

## 주요 기능

### 학습
- **플래시카드 학습** — 카테고리/난이도별 구문 학습, 카드 탭으로 뜻 보기
- **SRS 간격 반복** — SM-2 알고리즘 (😵/🤔/🙂/😊 4단계 평가), 자동 복습 일정
- **TTS (Web Speech API)** — 원어민 발음 재생, 재생 속도 조절
- **STT (음성인식)** — 발음 평가, 정답/오답 피드백, 언어별 정규화
- **4지선다 퀴즈** — 자동 출제, 결과 화면, 점수 저장

### 콘텐츠
- **9개 카테고리** — 기타, 여행 회화, 골프, 쇼핑, 레스토랑, 길찾기, 호텔, 공항, 응급상황
- **3개 난이도** — 초급/중급/고급
- **총 675개 구문** (9×3×25)
- **4개 언어** — 영어, 일본어, 한국어, 중국어
- **AI 구문 생성** — OpenRouter API 연동, 5단계 모델 자동 fallback

### UX
- **다국어 UI (G2)** — 한국어/English/日本語 즉시 전환, localStorage 영구 저장
- **효과음 (G3)** — 카드/퀴즈 상호작용음 (Web Audio API, 토글 가능)
- **스트릭 캘린더** — 최근 30일 학습 히트맵, 연속 학습일 추적
- **주간 학습 차트 (G4)** — 7일 막대 그래프, 총/평균 학습량
- **오프라인 폴백** — `navigator.onLine` 감지, 노란/빨간 배너 표시

### PWA / 인프라
- **오프라인 동작** — Service Worker v4 (3-tier 캐시: network-first/cache-first/stale-while-revalidate)
- **PWA 설치** — manifest.json + 아이콘으로 홈 화면에 앱처럼 추가
- **SW 업데이트 알림** — 새 버전 자동 감지, 토스트 알림
- **모바일 반응형** — 태블릿/휴대폰/터치 디바이스 최적화
- **데이터 편집 도구** — data-gen.html에서 청크 단위 편집, AI로 새 구문 생성, 병합·배포

## SRS (간격 반복 학습)

`lingo_srs_v1` localStorage 키에 카드별 학습 이력 저장:

```javascript
{
  "여권::I lost my passport.": {
    "interval": 3,        // 현재 간격 (일)
    "easeFactor": 2.5,    // 난이도 계수 (1.3~3.0)
    "nextReview": "2026-06-05",  // 다음 복습일
    "lastReview": "2026-06-02",
    "reviewCount": 1
  }
}
```

**평가 → 간격 변화**:
| 평가 | 다음 간격 | easeFactor |
|---|---|---|
| 😵 모르겠어요 (0) | 리셋 (1일) | -0.2 |
| 🤔 어려움 (1) | 1.2배 | -0.15 |
| 🙂 쉬움 (2) | easeFactor 배 | -0.05 |
| 😊 완벽 (3) | easeFactor 배 | +0.1 |

## 다국어 UI (i18n)

`lingo_ui_lang` localStorage 키에 언어 저장 (`ko` / `en` / `ja`). **60+개** UI 문자열 번역:

| 영역 | 키 예시 |
|---|---|
| 공통 UI | `appTitle`, `appSubtitle`, `selectLevel`, `selectPurpose`, `start`, `home`, `clear` |
| 학습 화면 | `learned`, `thisSession`, `streak1`, `tapToFlip`, `rateAgain`, `rateEasy` |
| 카테고리 | `cat_etc`, `cat_travel`, `cat_golf`, ... (9개) |
| 레벨 | `lvlName_beginner`, `lvlName_intermediate`, `lvlName_advanced` (3개) |
| 통계/기록 | `historySubtitle`, `totalLearned`, `maxStreak`, `quizCount`, `noHistory` |

## 효과음 (Sound)

Web Audio API로 생성된 톤 (오디오 파일 없음):
- 카드 뒤집기, SRS 평가 4종, 퀴즈 정답/오답, 세션 완료
- 랜딩 상단 `🔊/🔇` 버튼으로 토글
- `lingo_sfx` localStorage 키에 영구 저장

## Service Worker v4 캐시 전략

| 캐시 | 전략 | URL |
|---|---|---|
| `lingo-static-v4` | **cache-first** | HTML, JS, CSS, manifest, icons |
| `lingo-data-v4` | **network-first** | `phrases_ollama.json` |
| `lingo-runtime-v4` | **stale-while-revalidate** | 기타 GET |

- 외부 도메인 자동 스킵
- 오프라인 폴백 → `./index.html`
- 메시지 채널 (`SKIP_WAITING`, `CLEAR_CACHE`)

## localStorage 키 (13개)

| 키 | 용도 |
|---|---|
| `lingo_learned_v2` | 학습한 구문 키 |
| `lingo_history_v2` | 퀴즈 이력 |
| `lingo_stats_v2` | 누적 통계 |
| `lingo_activity_v1` | 일별 학습 (60일) |
| `lingo_srs_v1` | SRS 데이터 |
| `lingo_phrases_v1` | 병합된 phrases |
| `lingo_ui_lang` | UI 언어 |
| `lingo_sfx` | 효과음 on/off |
| `lingo_ollama_url` | OpenRouter URL |
| `lingo_ollama_model` | AI 모델명 |
| `lingo_selected_purpose` | 선택된 카테고리 |
| `lingo_selected_level` | 선택된 레벨 |
| `$OLLAMA_API_KEY` | OpenRouter API 키 |

## 지원 콘텐츠

### 카테고리 (9개)
- 📌 **기타** (etc)
- 🧳 **여행 회화** (travel)
- ⛳ **골프 용어** (golf)
- 🛍️ **쇼핑** (shop)
- 🍽️ **레스토랑** (restaurant)
- 🗺️ **길 찾기** (direction)
- 🏨 **호텔** (hotel)
- ✈️ **공항** (airport)
- 🚨 **응급상황** (emergency)

### 레벨 (3개)
- 🟢 **초급** (beginner)
- 🟡 **중급** (intermediate)
- 🔴 **고급** (advanced)

## 개발 가이드

### GitHub Pages
- **Lingo 앱**: <https://realizer-1966.github.io/lingo/>
- **Data Gen 도구**: <https://realizer-1966.github.io/lingo/data-gen.html>

### 로컬 개발
```bash
cd /data/data/com.termux/files/home/workspace
python3 -m http.server 8000
# http://localhost:8000/
```

### AI 구문 생성 (data-gen.html)
1. OpenRouter API Key 발급: <https://openrouter.ai/keys>
2. Data Gen 페이지 → "🤖 AI 생성" 탭
3. 카테고리/레벨 선택 → "✨ 생성 시작"

**기본 모델**: `nvidia/nemotron-3-super-120b-a12b:free`

**Fallback 체인** (rate limit 시 자동 전환):
1. `nvidia/nemotron-3-super-120b-a12b:free`
2. `meta-llama/llama-3.3-70b-instruct:free`
3. `nvidia/nemotron-3-nano-30b-a3b:free`
4. `openai/gpt-oss-120b:free`
5. `z-ai/glm-4.5-air:free`

### 데이터 편집

**옵션 A**: GitHub에서 직접 `phrases_ollama.json` 수정 후 commit
**옵션 B**: data-gen.html의 청크 관리 → AI 생성 → 병합 & 보내기

## 파일 구조

```
workspace/
├── icons/                  ← PWA 아이콘 (192, 512)
├── index.html              ← 메인 학습 앱 (1561줄, 72KB)
├── data-gen.html           ← 구문 생성/관리 도구 (546줄, 25KB)
├── sw.js                   ← Service Worker v5 (3-tier 캐시)
├── manifest.json           ← PWA 매니페스트
├── phrases_ollama.json     ← 학습 데이터 (675개 구문)
├── README.md               ← 이 문서
└── TESTING.md              ← 테스트 시나리오 매뉴얼
```

## 최신 기능 (2026-06-04 기준)

| 기능 | 날짜 | 설명 |
|---|---|---|
| **M1** | 6/4 | Live Translate 통합 — 랜딩에 🗣️ 카드, iframe 임베드 (lazy-load, 다국어 UI) |
| **K4** | 6/3 | 선택 상태 영구 저장 (`lingo_selected_*`) |
| **STT auto-next** | 6/3 | 내 발음 체크 후 "✅ 확인" 버튼 → 자동 다음 |
| **버튼 단순화** | 6/3 | 6개 → 3개 버튼 (발음/STT/다음) |
| **아이콘 재설계** | 6/3 | 블루/퍼플 그라데이션 (46% 감소) |
| **시작 버튼 고정** | 6/3 | "🚀 START" HTML 하드코딩 (깜빡림 0) |
| **TTS 속도 0.9x** | 6/3 | '🗣️ 발음 듣기' TTS 속도 0.7x → 0.9x |

## Live Translate 통합 (M1)

랜딩 페이지의 **🗣️ Live Translate** 카드를 탭하면 [kazunori279/live-translator](https://github.com/kazunori279/live-translator)(Apache-2.0)가 iframe으로 임베드된다. **Lingo 자체는 정적 PWA로 GitHub Pages에서 서빙**되고, live-translator는 별도 Cloud Run에 배포한 뒤 그 URL을 `index.html`의 `#liveFrame[data-live-url]`에 박으면 된다.

**설정 방법**:
1. [kazunori279/live-translator](https://github.com/kazunori279/live-translator#deployment-to-cloud-run) 가이드대로 Cloud Run 배포
2. `index.html`의 iframe 찾기:
   ```html
   <iframe id="liveFrame" data-live-url="https://YOUR-LIVE-TRANSLATOR-URL.run.app" ...></iframe>
   ```
3. `data-live-url` 을 Cloud Run URL로 교체
4. `git push` → GitHub Pages 자동 재배포

**특징**:
- 🚀 **Lazy-load**: 첫 진입 시점에만 iframe src 설정 (초기 로드 부담 0)
- 🌐 **다국어**: 3개국어(ko/en/ja) UI 번역
- 🎤 **마이크 권한**: `allow="microphone;autoplay"` 속성 사용
- 🛡️ **로컬 작동**: `data-live-url` 미설정 시 "URL 미설정" 안내 표시 (앱 깨지지 않음)

## GitHub 커밋 히스토리

```
fcc0a53 chore: update TTS speed from 0.7 to 0.9
507a053 fix: STT auto-next 확인 버튼 클릭 시 nextCard() 실행
85ff76e docs: update README with latest features (K4, STT auto-next, simplified buttons)
2ee45bc refactor: remove '🐢 천천히' button
6b3bf14 feat: STT auto-next + simplified button layout
a3a8393 refactor: update manifest & sw.js for PWA installability
178af09 perf: Lingo PWA icon redesign
3bd9436 fix: hardcode '🚀 START' in HTML for zero-flicker load
3a4f86c simplify: start button always shows '🚀 START' (language-agnostic)
0188275 fix: K4 persist category/level selection across refresh
...
```

總: **50개 커밋**, **8,022줄 삽입**, **1,009줄 삭제**

## 라이선스

MIT License — 자유롭게 사용, 수정, 배포 가능
