# Lingo 학습 — 여행 & 골프 구문 학습 PWA

여행·골프 등 실전에서 바로 써먹는 영어 구문을 4개국어(영어/일본어/한국어/중국어)로 학습하는 오프라인 우선 PWA. 백엔드 없이 정적 파일만으로 동작하며, 홈 화면에 설치해서 플래시카드/퀴즈/음성학습을 즉시 사용할 수 있다.

주요 기능
  - 플래시카드 학습 — 카테고리/난이도별 구문 학습, 카드 탭으로 뜻 보기
  - TTS (Web Speech API) — 원어민 발음 재생, 재생 속도 조절
  - STT (음성인식) — 발음 평가, 정답/오답 피드백
  - 4지선다 퀴즈 — 자동 출제, 결과 화면 제공
  - 진도 저장 — localStorage에 학습한 구문·퀴즈 기록·통계 저장
  - 오프라인 동작 — Service Worker 캐싱으로 네트워크 없이 사용 가능
  - PWA 설치 — manifest.json + 아이콘으로 홈 화면에 앱처럼 추가

지원 콘텐츠
  - 언어: 영어(en), 일본어(jp), 한국어(ko), 중국어(zh) — 한 구문에 4개국어 모두 수록
  - 카테고리(9): etc(기타), travel(여행), golf(골프), shop(쇼핑), restaurant(레스토랑), direction(길찾기), hotel(호텔), airport(공항), emergency(응급상황)
  - 레벨(3): beginner(초급, 🟢), intermediate(중급, 🟡), advanced(고급, 🔴)

디렉토리 구조
  .
  ├── index.html          메인 PWA (학습·퀴즈·히스토리)
  ├── data-gen.html       구문 데이터 에디터
  ├── phrases_ollama.json 구문 데이터 (4개국어 번역, 9 카테고리 × 3 레벨)
  ├── manifest.json       PWA 매니페스트
  │   ├── sw.js               Service Worker (캐시: lingo-cache-v2)
  ├── icons/
  │   ├── icon-192.png    PWA 아이콘
  │   ├── icon-512.png    PWA 아이콘
  │   ├── icon-192.svg    벡터 원본
  │   └── icon-512.svg    벡터 원본
  └── README.md

실행 방법
  정적 PWA이므로 로컬 HTTP 서버가 필요하다. 파일을 그냥 열어도 동작은 하지만 Service Worker·fetch 등이 제대로 작동하려면 서버로 띄우는 것을 권장한다. (Termux 기준)

  1) Python 내장 서버 사용 (가장 간단)
     cd ~/workspace
     python3 -m http.server 8000

  2) Node 사용 (대안)
     npx http-server -p 8000 -c-1

  그 다음 브라우저에서 http://localhost:8000 접속. 모바일/태블릿에 설치하려면 manifest 아이콘이 정상 출력되는지 확인 후 브라우저 메뉴 → "홈 화면에 추가"로 설치한다.

  캐시 무효화: 데이터나 코드를 수정한 뒤에는 Service Worker 캐시가 이전 버전을 들고 있을 수 있다. 개발자 도구 → Application → Service Workers → "Unregister" 후 새로고침하거나, sw.js의 CACHE_NAME 버전을 v2 → v3으로 올린다.

데이터 편집
  1) 브라우저에서 data-gen.html을 연다 (서버 실행 후 http://localhost:8000/data-gen.html).
  2) 현재 phrases_ollama.json 내용이 자동 로드되며, 카테고리/레벨별 구문을 추가·수정·삭제할 수 있다.
  3) 상단 "Export JSON" 버튼으로 갱신된 JSON을 다운로드한다.
  4) 다운로드한 파일을 phrases_ollama.json으로 덮어쓴다.
  5) PWA를 다시 열면 자동으로 새 데이터를 읽어온다 (페이지 진입 시 phrases_ollama.json을 fetch해 localStorage에 저장).

  새 구문 추가 시 형식 (en/jp/ko/zh 4개 필드 모두 필수):
    {
      "en": "Excuse me",
      "jp": "すみません",
      "ko": "실례합니다",
      "zh": "不好意思"
    }

  번역 표기 원칙
    - 일본어는 히라가나/가타카나/한자 그대로 (로마자·IPA 발음기호 표기 금지)
    - 모든 발음 표기는 target 언어 자체의 script 사용
    - TTS 재생 시에도 target 언어 코드(en-US, ja-JP, zh-CN) 사용

기술 스택
  - HTML/CSS/JS (단일 파일, 외부 라이브러리 없음)
  - Web Speech API (TTS/STT)
  - Service Worker (stale-while-revalidate)
  - localStorage (학습 진도)
  - Web App Manifest (PWA 설치)

데이터 출처
  phrases_ollama.json의 번역은 Ollama LLM으로 생성됨. 새 카테고리/구문 추가 시 data-gen.html을 통해 같은 형식으로 편집.

라이선스
  개인 학습용. 외부 배포 시 번역 데이터의 정확성 검토 권장.
