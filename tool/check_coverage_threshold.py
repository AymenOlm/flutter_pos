from pathlib import Path
import sys


def main() -> int:
    coverage_file = Path('coverage/lcov.info')
    if not coverage_file.exists():
        print('coverage/lcov.info not found', file=sys.stderr)
        return 1

    covered = 0
    total = 0
    for line in coverage_file.read_text().splitlines():
        if line.startswith('LH:'):
            covered += int(line[3:])
        elif line.startswith('LF:'):
            total += int(line[3:])

    if total == 0:
        print('No coverage data found', file=sys.stderr)
        return 1

    percent = covered / total * 100
    print(f'Line coverage: {percent:.2f}% ({covered}/{total})')
    if percent < 70:
        print('Coverage threshold not met: minimum 70%', file=sys.stderr)
        return 1

    return 0


if __name__ == '__main__':
    raise SystemExit(main())