# Lingo 학습 — 여행 & 골프 구문 학습 PWA

여행·골프 등 실전에서 바로 써먹는 영어 구문을 4개국어(영어/일본어/한국어/중국어)로 학습하는 오프라인 우선 PWA. 백엔드 없이 정적 파일만으로 동작하며, 홈 화면에 설치해서 플래시카드/퀴즈/음성학습을 즉시 사용할 수 있다.

## 주요 기능

- **플래시카드 학습** — 카테고리/난이도별 구문 학습, 카드 탭으로 뜻 보기
- **TTS (Web Speech API)** — 원어민 발음 재생, 재생 속도 조절 (0.4x, 0.7x, 1.0x)
- **STT (음성인식)** — 발음 평가, 정답/오답 피드백, 언어별 정규화
- **4지선다 퀴즈** — 자동 출제, 결과 화면, 점수 저장
- **AI 구문 생성** — OpenRouter API 연동, 5단계 모델 자동 fallback
- **진도 저장** — localStorage에 학습한 구문·퀴즈 기록·통계 저장
- **오프라인 동작** — Service Worker v4 스마트 캐싱, 네트워크 없이 사용 가능
- **PWA 설치** — manifest.json + 아이콘으로 홈 화면에 앱처럼 추가
- **데이터 편집** — data-gen.html에서 청크 단위 편집, AI로 새 구문 생성, 병합·배포

## 지원 콘텐츠

- 언어: 영어(en), 일본어(jp), 한국어(ko), 중국어(zh) — 한 구문에 4개국어 모두 수록
- 카테고리(9): etc(기타), travel(여행), golf(골프), shop(쇼핑), restaurant(레스토랑), direction(길찾기), hotel(호텔), airport(공항), emergency(응급상황)
- 레벨(3): beginner(초급, 🟢), intermediate(중급, 🟡), advanced(고급, 🔴)
- **총 675개 구문** (9 카테고리 × 3 레벨 × 25 구문) ✅

## 디렉토리 구조

```
.
├── index.html          메인 PWA (학습·퀴즈·통계)
├── data-gen.html       구문 데이터 생성·관리 도구
├── phrases_ollama.json 구문 데이터 (675개, 4개국어 번역)
├── manifest.json       PWA 매니페스트
├── sw.js               Service Worker v4 (3-tier caching)
├── icons/
│   ├── icon-192.png    PWA 아이콘
│   ├── icon-512.png    PWA 아이콘
│   ├── icon-192.svg    벡터 원본
│   └── icon-512.svg    벡터 원본
└── README.md
```

## 실행 방법

정적 PWA이므로 로컬 HTTP 서버가 필요하다. 파일을 그냥 열어도 동작은 하지만 Service Worker·fetch 등이 제대로 작동하려면 서버로 띄우는 것을 권장한다.

### 1) Python 내장 서버 (가장 간단)
```bash
cd ~/workspace
python3 -m http.server 8000
```

### 2) Node 사용 (대안)
```bash
npx http-server -p 8000 -c-1
```

그 다음 브라우저에서 `http://localhost:8000` 접속. 모바일/태블릿에 설치하려면 manifest 아이콘이 정상 출력되는지 확인 후 브라우저 메뉴 → "홈 화면에 추가"로 설치한다.

## GitHub Pages

- **앱**: https://realizer-1966.github.io/lingo/
- **Data Gen**: https://realizer-1966.github.io/lingo/data-gen.html
- **원본 저장소**: https://github.com/realizer-1966/lingo

## 캐시 전략 (Service Worker v4)

SW는 3개의 분리된 캐시를 사용한다:

| 캐시 이름 | 용도 | 전략 | URL 패턴 |
|---|---|---|---|
| `lingo-static-v4` | 정적 파일 | **cache-first** | HTML, JS, CSS, manifest, icons |
| `lingo-data-v4` | 데이터 파일 | **network-first** | `phrases_ollama.json` |
| `lingo-runtime-v4` | 기타 GET | stale-while-revalidate | 기타 |

### 캐시 무효화

데이터나 코드를 수정한 뒤에는 Service Worker 캐시가 이전 버전을 들고 있을 수 있다. 3가지 방법:

1. **자동 알림**: 새 버전이 설치되면 하단에 "🔄 새 버전 사용 가능" 토스트가 표시됨 → "새로고침" 클릭
2. **수동 해제**: 개발자 도구(F12) → Application → Service Workers → "Unregister" 후 새로고침
3. **버전 증가**: `sw.js`의 `CACHE_VERSION` 변수를 `v4` → `v5`로 변경

## AI 구문 생성 (Data Gen)

`data-gen.html`에서 OpenRouter API를 통해 AI로 새 구문을 생성할 수 있다.

### 사용법

1. **API Key 발급**: https://openrouter.ai/keys (이메일 회원가입 후 무료 키 발급)
2. Data Gen 페이지에서 **OpenRouter API Key** 필드에 키 붙여넣기
3. 카테고리/레벨/개수 선택
4. **✨ 생성 시작** 클릭

### 5단계 자동 Fallback

rate limit(429) 또는 서버 오류(5xx) 발생 시 자동으로 다음 모델을 시도한다:

```
1. nvidia/nemotron-3-super-120b-a12b:free
2. meta-llama/llama-3.3-70b-instruct:free
3. nvidia/nemotron-3-nano-30b-a3b:free
4. openai/gpt-oss-120b:free
5. z-ai/glm-4.5-air:free
```

성공한 모델은 자동으로 기본값으로 저장된다.

### 프롬프트 템플릿

기본 프롬프트:
```
Generate {{count}} practical {{level}} Korean learning phrases for "{{category}}" scenario.
Output JSON array: [{"en":"...","jp":"...","ko":"...","zh":"..."}]
```

`{{count}}`, `{{level}}`, `{{category}}`는 자동으로 치환된다. 커스터마이징도 가능하다.

## 데이터 편집

### 방법 1: GitHub에서 직접 수정

1. https://github.com/realizer-1966/lingo/blob/main/phrases_ollama.json 접속
2. 연필 아이콘 클릭 → 수정
3. "Commit changes" 클릭 → 1-2분 후 GitHub Pages 자동 반영

### 방법 2: Data Gen 도구 사용

1. 브라우저에서 data-gen.html 열기
2. 카테고리/레벨별 청크 선택 → **📂 불러오기**
3. 구문 편집 / 추가 / 삭제
4. **💾 저장** → localStorage에 저장
5. **🔀 전체 병합** → **🚀 Lingo 앱에 배포**

### 새 구문 추가 시 형식

```json
{
  "en": "Excuse me",
  "jp": "すみません",
  "ko": "실례합니다",
  "zh": "不好意思"
}
```

en/jp/ko/zh 4개 필드 모두 필수.

## 번역 표기 원칙

- 일본어는 히라가나/가타카나/한자 그대로 (로마자·IPA 발음기호 표기 금지)
- 모든 발음 표기는 target 언어 자체의 script 사용
- TTS 재생 시에도 target 언어 코드(en-US, ja-JP, zh-CN) 사용

## 기술 스택

- HTML/CSS/JS (단일 파일, 외부 라이브러리 없음)
- Web Speech API (TTS/STT)
- Service Worker v4 (3-tier cache strategy)
- localStorage (학습 진도, 청크, AI 키)
- Web App Manifest (PWA 설치)
- OpenRouter API (AI 구문 생성, OpenAI-compatible)

## 라이선스

개인 학습용. 외부 배포 시 번역 데이터의 정확성 검토 권장.
