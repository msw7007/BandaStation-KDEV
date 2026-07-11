import { Stack } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { docBad, docGood } from './assetData';
import type { CorporateMinigameData } from './types';

export const Research = () => {
  const { act, data } = useBackend<CorporateMinigameData>();

  return (
    <div className="StyleGuide__blockShell" style={{ display: 'inline-block' }}>
      <div className="StyleGuide__blockTitle">Research</div>
      <div className="StyleGuide__trapezoidNote">
        Find the bad report. A wrong theory appears briefly among clean documents. Click it for 1 data.
      </div>
      {[0, 1, 2].map((row) => (
        <Stack key={row} mb={0.5}>
          {[1, 2, 3].map((offset) => {
            const cell = row * 3 + offset;
            const active = data.activeCell === cell;
            return (
              <Stack.Item key={cell} grow>
                <button
                  type="button"
                  className="StyleGuide__iconButton StyleGuide__iconButton--large StyleGuide__iconButton--cyan"
                  onClick={() => act('research_click', { cell })}
                >
                  <img alt="" src={active ? docBad : docGood} style={{ width: '44px', height: '44px' }} />
                </button>
              </Stack.Item>
            );
          })}
        </Stack>
      ))}
    </div>
  );
};
