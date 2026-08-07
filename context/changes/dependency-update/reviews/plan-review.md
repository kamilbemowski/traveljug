<!-- PLAN-REVIEW-REPORT -->
# Plan Review: Dependency Update + KGP Fix + Vulnerability Scanner

- **Plan**: context/changes/dependency-update/plan.md
- **Mode**: Deep
- **Date**: 2026-08-07
- **Verdict**: REVISE
- **Findings**: 0 critical, 3 warnings, 2 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| End-State Alignment | PASS |
| Lean Execution | PASS |
| Architectural Fitness | PASS |
| Blind Spots | WARNING |
| Plan Completeness | WARNING |

## Grounding
5/5 paths ✓, osv-scanner supports pubspec.lock ✓, brief↔plan ✓

## Findings

### F1 — `flutter pub upgrade` bez strategii rollbacku

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Blind Spots
- **Location**: Phase 1 — Dependency update
- **Detail**: `flutter pub upgrade` aktualizuje wszystkie pakiety do najnowszych wersji. Brak backupu pubspec.lock przed upgrade.
- **Fix**: Dodaj krok backupu pubspec.lock przed upgrade. Po testach można przywrócić z gita.
- **Decision**: FIXED

### F2 — KGP suppress flag nieokreślony

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Plan Completeness
- **Location**: Phase 2
- **Detail**: Plan nie podaje konkretnej flagi, każe zgadywać.
- **Fix**: Podaj konkretną flagę: `android.suppressUnsupportedKotlinPluginVersionCheck=true`.
- **Decision**: FIXED

### F3 — `dart fix --apply` może zmodyfikować wygenerowane pliki

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Plan Completeness
- **Location**: Phase 4
- **Detail**: dart fix może dotknąć *.g.dart plików, które zostaną nadpisane przez build_runner.
- **Fix**: Po dart fix uruchom build_runner build ponownie.
- **Decision**: FIXED

### F4 — Phase 3 niezależny od Phases 1-2

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW
- **Dimension**: Lean Execution
- **Location**: Phase 3
- **Detail**: Vuln scanner może być dodany niezależnie, bez czekania na update pakietów.
- **Decision**: FIXED

### F5 — Duplikacja APK build w success criteria

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW
- **Dimension**: Plan Completeness
- **Location**: Phase 1 Success Criteria
- **Detail**: `flutter build apk` jest zarówno w Automated jak i Manual.
- **Fix**: Usuń z Manual Verification.
- **Decision**: FIXED
