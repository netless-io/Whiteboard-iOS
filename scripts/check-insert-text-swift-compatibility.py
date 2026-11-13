#!/usr/bin/env python3
"""Typecheck existing Swift call sites against the released and current header."""
import json
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
header = "Whiteboard/Classes/Room/WhiteRoom.h"
released = subprocess.check_output(["git", "show", "2.16.149:" + header], cwd=root, text=True)
current = (root / header).read_text()


def signature(source):
    return re.search(r"- \(void\)insertText:.*?;", source).group(0)


with tempfile.TemporaryDirectory(prefix="whiteboard-swift-compat-") as directory:
    work = Path(directory)
    (work / "module.modulemap").write_text('module Probe { header "Probe.h" export * }\n')
    (work / "probe.swift").write_text('''import Foundation
import Probe
func use(_ room: ProbeRoom) {
    room.insertText(0, y: 0, textContent: "hello") { textId in
        print(textId.count)
        room.updateText(textId, textContent: "updated")
    }
    let callback: (String) -> Void = { print($0.count) }
    room.insertText(0, y: 0, textContent: "hello", completionHandler: callback)
}
''')
    results = []
    for name, method, should_pass in [
        ("released", signature(released), True),
        ("current", signature(current), True),
        ("nullable-regression-control", signature(released).replace("NSString * textId", "NSString * _Nullable textId"), False),
    ]:
        (work / "Probe.h").write_text(
            '#import <Foundation/Foundation.h>\nNS_ASSUME_NONNULL_BEGIN\n'
            '@interface ProbeRoom : NSObject\n' + method + '\n'
            '- (void)updateText:(NSString *)textId textContent:(NSString *)textContent;\n'
            '@end\nNS_ASSUME_NONNULL_END\n'
        )
        result = subprocess.run(["xcrun", "swiftc", "-typecheck", "-I", str(work), str(work / "probe.swift")], text=True, capture_output=True)
        assert (result.returncode == 0) == should_pass, result.stderr
        results.append({"header": name, "compiled": result.returncode == 0, "expected": should_pass})
    print(json.dumps(results, indent=2))
