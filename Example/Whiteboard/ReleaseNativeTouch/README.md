KIF native touch support, test fixture only.

Pinned source: https://github.com/kif-framework/KIF/tree/357a70fe0ccfb8ae5097d6ac14d0f010b376787d

Only UITouch/UIEvent/IOHID helpers are compiled, guarded by DEBUG in WhiteReleaseE2EController.h. No KIF actors, XCTest runtime, JavaScript events or product rendering/storage code are used.

Vendored source differs only by trailing-whitespace normalization; the pinned implementation is unchanged.
