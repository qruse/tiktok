# 기술 테스트용 효과 가져오기

2026-09-06 사용자 지침: 이 시제품은 기술 테스트 전용이다. 아래 게시 관련 설명은 참고 기록이며 실행하지 않는다. 실제 제작 후보는 트렌드 조사 후 별도로 선정한다.

아래 메뉴는 공식 Randomizer 2D 문서 기준이며 설치 버전에 따라 다를 수 있다. 임의의 프로젝트 파일을 생성하지 않고 공식 템플릿에 에셋을 연결한다.

## 프로젝트

1. Effect House에 로그인하고 Templates → Randomizer 2D를 연다.
2. 프로젝트를 이 폴더 아래 `projects/career-2027`에 저장한다. 템플릿이 만든 파일 형식은 유지한다.
3. Assets의 [+] → Import → Texture Sequence로 `effects/01-career-2027/assets/answers` 안 PNG 8개만 선택한다. 순서와 프레임 수 8개를 확인한다.
4. Import → From Computer로 `assets/title.png`를 별도 가져온다.
5. Hierarchy의 Title을 선택해 제목 텍스처를 교체한다.
6. RandomAnimationSequence의 Animation Sequence 컴포넌트에 새 Texture Sequence를 연결한다. Image.Texture만 바꾸면 애니메이션이 다시 덮어쓸 수 있다.
7. 두 카드 모두 2:1 비율을 유지한다. 머리 위에 배치하되 화면 상단이 잘리거나 눈·입을 가리지 않게 조정한다.

문서: https://effecthouse.tiktok.com/learn/guides/tutorials/template-tutorials/randomizer-2d

## 시제품 설정안 — 성능 검증 전

- TapToSpin을 켜고 화면 탭으로 시작하도록 한다. 실제 노드 이름이 다르면 버전별 설명을 확인한다.
- 스핀은 약 2초부터 시험한다. 이를 실제 설정했거나 검증했다고 간주하지 않는다.
- 결과는 표정 반응을 찍을 수 있도록 유지하고, 재시작 동작을 시험한다.
- 제목은 탭 안내를 표시한다. 결과에는 랜덤 놀이임을 표시한다.
- 타이밍 기반 템플릿이므로 결과가 엄밀히 동일 확률이라고 홍보하지 않는다.

## 휴대폰에서 확인할 것

- Preview in TikTok QR로 로드한 뒤 얼굴 정면·좌우 회전·밝은/어두운 배경을 확인한다.
- 제목 전체와 긴 결과인 ‘스마트팜 사장’이 읽히는가?
- 화면 탭, 녹화 시작, 재촬영 때 시작·초기화가 자연스러운가?
- 10회 이상 돌려 결과가 바뀌고 멈추는가? 이는 균등 확률 검증은 아니다.
- 얼굴이 잠깐 사라졌다 돌아올 때 카드 위치가 정상인가?
- 카메라 UI·자막·상단 영역과 겹치지 않는가?
- 실제 기기 성능 검사와 앱이 계산하는 최종 패키지 크기를 확인한다. PNG 합계가 작아도 템플릿 전체 크기는 별개다.

## 제출용 초안

- 이름: 내 2027년 직업은
- 유형/카테고리: 앱에 표시되는 일반 Randomizer에 해당하는 항목. 임의로 다른 분류를 선택하지 않는다.
- 아이콘: `assets/icon-162.png` → 앱 Effect Icon Creator에서 크롭/여백 점검.
- 촬영 팁: ‘화면을 탭해 직업을 뽑아보세요. 재미로 보는 랜덤 결과입니다.’
- 데모: 실제 효과를 적용한 휴대폰 영상. PNG 시안을 실제 효과 영상처럼 제출하지 않는다.
- 개인 홍보 영상 초안: ‘2027년 출근지는 여기인가요? 내 결과는…’

직업 결과를 실질적인 예측·얼굴 분석이라고 표현하지 않는다. 승인·보상은 보장하지 않는다.

아이콘 규격 출처: https://effecthouse.tiktok.com/learn/guides/publishing/effect-icon-creation

제출 화면 출처: https://effecthouse.tiktok.com/learn/guides/publishing/submit-your-effect

최종 게시·데모 촬영은 아직 진행하지 않았다. 게시 전 이름·계정·미리보기를 확인한다.
