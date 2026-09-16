#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="$(mktemp -d /tmp/vipm-check.XXXXXX)"
trap 'rm -rf "$OUTPUT"' EXIT
cp "$ROOT/Tests/questions.fixture.json" "$OUTPUT/questions.json"
SOURCES=("$ROOT"/vipm/Domain/*.swift "$ROOT"/vipm/Data/*.swift "$ROOT"/vipm/Presentation/ViewModels/*.swift "$ROOT/vipm/App/AppComposition.swift" "$ROOT/Tests/SelfCheck.swift")
if grep -En 'SwiftUI|UIKit|Observation|UserDefaults|Bundle|JSONDecoder|JSONEncoder|ViewModel|#if DEBUG' "$ROOT"/vipm/Domain/*.swift; then
    echo 'Domain must not depend on presentation, storage adapters, or build configuration.' >&2
    exit 1
fi
if grep -En 'JSONQuestionBankRepository|UserDefaultsStudyProgressRepository|UserDefaults|Bundle|QuestionDTO|QuestionBankDTO' "$ROOT"/vipm/Presentation/{Views,ViewModels}/*.swift; then
    echo 'Presentation must not depend on concrete data adapters.' >&2
    exit 1
fi
xcrun swiftc -parse-as-library -emit-module -module-name StudyDomain "$ROOT"/vipm/Domain/*.swift -emit-module-path "$OUTPUT/StudyDomain.swiftmodule"
printf '\nChecks without DEBUG\n'
xcrun swiftc -parse-as-library "${SOURCES[@]}" -o "$OUTPUT/check"
"$OUTPUT/check" "$OUTPUT/questions.json" "$ROOT/vipm/questions.json"
printf '\nChecks with DEBUG\n'
xcrun swiftc -D DEBUG -parse-as-library "${SOURCES[@]}" -o "$OUTPUT/check-debug"
"$OUTPUT/check-debug" "$OUTPUT/questions.json" "$ROOT/vipm/questions.json"
