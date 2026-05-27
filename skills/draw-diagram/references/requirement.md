# Requirement Diagram

요구사항 ↔ 설계 요소 ↔ 검증 항목 간의 추적성(traceability)을 표현. SysML 기반.

## 그리기 전에 물어볼 것 (AskUserQuestion)

1. **요구사항 목록과 각각의 타입** — `requirement`, `functionalRequirement`, `performanceRequirement`, `interfaceRequirement`, `physicalRequirement`, `designConstraint` 중 무엇인지.
2. **각 요구사항의 ID / 텍스트 / risk(Low/Medium/High) / verifyMethod(Analysis/Inspection/Test/Demonstration)**.
3. **연결 대상 요소(`element`) 목록** — 어떤 컴포넌트/문서/모듈이 이 요구를 충족시키는가.
4. **관계 타입** — `satisfies` / `derives` / `refines` / `contains` / `copies` / `traces` / `verifies` 중 어느 것을 쓸지.

이 다이어그램은 SysML/Systems Engineering 맥락에서 주로 쓴다. 일반적인 "스펙 문서 표"가 필요한 경우에는 표(table) 또는 mindmap이 더 편할 수 있다.

## 최소 문법

```mermaid
requirementDiagram

    requirement performance_req {
        id: 1
        text: 결제 응답시간은 1초 이내여야 한다
        risk: high
        verifymethod: test
    }

    functionalRequirement auth_req {
        id: 2
        text: 사용자는 OAuth로 로그인할 수 있어야 한다
        risk: medium
        verifymethod: demonstration
    }

    element checkout_service {
        type: service
        docref: docs/checkout.md
    }

    element auth_module {
        type: module
    }

    checkout_service - satisfies -> performance_req
    auth_module - satisfies -> auth_req
    performance_req - derives -> auth_req
```

- 관계 화살표: `요소 - <relation> -> 요구사항`.
- `risk`: `low | medium | high`. `verifymethod`: `analysis | inspection | test | demonstration`.

## 자주 하는 실수

- 관계의 방향 헷갈림 → "어떤 element가 어떤 requirement를 satisfies한다" 식으로 자연어로 문장을 만들어 검증.
- 요구사항을 너무 잘게 쪼개서 다이어그램이 그물이 됨 → 상위 요구사항만 다이어그램에, 디테일은 문서로.
- 단순 기능 명세 시각화에 사용 → flowchart나 mindmap이 가독성 더 좋다. requirement는 추적성이 핵심일 때만.
