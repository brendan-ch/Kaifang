# Attribution

`KaifangSpacedRepetition` is an independent Swift implementation of the
**FSRS-6** spaced-repetition algorithm. It was written by referencing the
following open-source projects. No source was copied verbatim; the algorithm
is the published FSRS-6 specification and the numeric test fixtures are taken
from the canonical ts-fsrs test suite.

## Algorithm specification (and test fixtures)

**ts-fsrs** — <https://github.com/open-spaced-repetition/ts-fsrs> (MIT,
Copyright (c) 2026 Open Spaced Repetition). The canonical TypeScript reference
for FSRS-6. The expected values in this package's test suite are taken
byte-for-byte from ts-fsrs's `packages/fsrs/__tests__` (notably
`algorithm.test.ts` and `FSRS-6.test.ts`).

## Swift ports consulted while implementing

- **open-spaced-repetition/swift-fsrs** —
  <https://github.com/open-spaced-repetition/swift-fsrs> (MIT, Copyright (c)
  2023 Ben Smiley).
- **bitbemol/swift-fsrs** — <https://github.com/bitbemol/swift-fsrs> (MIT,
  Copyright (c) 2026 Bemol).

Both are MIT licensed; their permission notices are reproduced below in
acknowledgement.

```
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
