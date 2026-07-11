import { Stack } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { tileColor } from './colors';
import type { CorporateMinigameData } from './types';

const tripleLabel = (level: number) => {
  if (level === -1) {
    return 'M';
  }
  if (level === -2) {
    return 'P';
  }
  return level ? String.fromCharCode(64 + Math.min(level, 26)) : '+';
};

const tripleColor = (level: number) => {
  if (level < 0) {
    return '#5f4a66';
  }
  return level ? tileColor(level) : undefined;
};

export const TripleTown = () => {
  const { act, data } = useBackend<CorporateMinigameData>();

  return (
    <div className="StyleGuide__blockShell" style={{ display: 'inline-block' }}>
      <div className="StyleGuide__blockTitle">Next biological element: {tripleLabel(data.nextLevel || 0)}</div>
      <div className="StyleGuide__trapezoidNote">
        Place elements on empty squares. Three connected matching letters merge into the next letter. M and P are blockers.
      </div>
      {data.tripleBoard?.map((row, y) => (
        <Stack key={y} mb={0.5}>
          {row.map((level, x) => (
            <Stack.Item key={`${x}-${y}`}>
              <button
                type="button"
                className="StyleGuide__iconButton StyleGuide__iconButton--large StyleGuide__iconButton--cyan"
                style={{ backgroundColor: tripleColor(level) }}
                onClick={() => act('triple_place', { x, y })}
              >
                {tripleLabel(level)}
              </button>
            </Stack.Item>
          ))}
        </Stack>
      ))}
    </div>
  );
};
