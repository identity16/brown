# Gantt Chart

기간이 있는 태스크와 그들 사이의 의존성으로 본 프로젝트 일정.

## 그리기 전에 물어볼 것 (AskUserQuestion)

1. **프로젝트 제목과 기간 단위** — 일(day) / 주(week) / 시간(hour) 중 무엇으로 표시할지. 시작일.
2. **섹션 구분** — 태스크를 어떤 묶음(섹션)으로 그룹화할지. (예: "설계", "구현", "QA"). 한두 개여도 됨.
3. **태스크 목록 + 각 태스크의 (시작 또는 의존성, 기간, 상태)** — 한꺼번에 받기 어려우면 표 형태로 적어달라고 한다.
4. **이정표(milestone) 여부** — 특정 시점(릴리스일 등)을 점으로 찍을지.

## 최소 문법

```mermaid
gantt
    title 출시 일정
    dateFormat  YYYY-MM-DD
    axisFormat  %m/%d

    section 설계
    요구 분석            :done,    a1, 2026-06-01, 5d
    아키텍처 확정         :done,    a2, after a1, 3d

    section 구현
    백엔드 API           :active,  b1, after a2, 10d
    프론트엔드 화면        :         b2, after a2, 12d

    section QA
    통합 테스트           :         c1, after b1, 5d
    릴리스                :milestone, m1, after c1, 0d
```

- 태스크 형식: `이름 : [상태], [id], [시작|after id], 기간`.
- 상태: `done`, `active`, `crit` (혹은 조합 `crit, active`).
- `milestone`은 기간 `0d`.
- `after id1 id2` 처럼 복수 의존성도 가능.

## 자주 하는 실수

- 의존성을 표시하지 않고 모든 태스크에 절대 날짜를 박음 → 일정 한 칸만 바뀌어도 전체 수정. 가능하면 `after`로 묶어라.
- 너무 잘게 쪼갠 태스크(>30개)를 한 차트에 → 읽기 어렵다. 상위 일정만 보이고 디테일은 별도.
- 한국어 태스크 이름에 `:` 들어가서 파싱 깨짐 → 콜론 제거하거나 다른 구분자로 대체.
