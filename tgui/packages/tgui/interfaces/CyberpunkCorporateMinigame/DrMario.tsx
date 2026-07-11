import { Box, Stack } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { pillColor } from './colors';
import type { CorporateMinigameData } from './types';

export const DrMario = () => {
  const { act, data } = useBackend<CorporateMinigameData>();

  return (
    <div className="StyleGuide__blockShell" style={{ display: 'inline-block' }}>
      <div className="StyleGuide__blockTitle">Capsule alignment</div>
      <div className="StyleGuide__trapezoidNote">
        Move and rotate falling capsules. Four same-color cells in a row or column clear. Reach 20 clears.
      </div>
      <div className="StyleGuide__twoColumnLayout">
        <div className="StyleGuide__innerPanel">
          <div className="StyleGuide__blockTitle">Next</div>
          <Stack mb={1}>
            {data.nextPill?.colors.map((color, index) => (
              <Stack.Item key={index}>
                <Box
                  width={3}
                  height={2}
                  backgroundColor={pillColor(color)}
                  textAlign="center"
                />
              </Stack.Item>
            ))}
          </Stack>
          <div className="StyleGuide__actionRow">
            <button
              type="button"
              className="StyleGuide__iconButton StyleGuide__iconButton--cyan"
              onClick={() => act('dr_move', { direction: 'left' })}
            >
              <i className="fas fa-arrow-left" />
            </button>
            <button
              type="button"
              className="StyleGuide__iconButton StyleGuide__iconButton--cyan"
              onClick={() => act('dr_rotate')}
            >
              <i className="fas fa-rotate-right" />
            </button>
            <button
              type="button"
              className="StyleGuide__iconButton StyleGuide__iconButton--cyan"
              onClick={() => act('dr_move', { direction: 'right' })}
            >
              <i className="fas fa-arrow-right" />
            </button>
            <button
              type="button"
              className="StyleGuide__iconButton StyleGuide__iconButton--green"
              onClick={() => act('dr_soft_drop')}
            >
              <i className="fas fa-arrow-down" />
            </button>
            <button
              type="button"
              className="StyleGuide__iconButton StyleGuide__iconButton--green"
              onClick={() => act('dr_hard_drop')}
            >
              <i className="fas fa-angle-double-down" />
            </button>
          </div>
        </div>
        <div className="StyleGuide__innerPanel">
          {data.drBoard?.map((row, y) => (
            <Stack key={y} mb={0.25}>
              {row.map((cell, x) => (
                <Stack.Item key={`${x}-${y}`}>
                  <Box
                    width={4}
                    height={2}
                    textAlign="center"
                    backgroundColor={cell ? pillColor(cell.color) : '#071016'}
                    style={{
                      border: cell?.kind === 'virus' ? '1px solid #f02c42' : '1px solid #245f80',
                      boxShadow: cell?.kind === 'active' ? '0 0 6px #14c6ee' : undefined,
                    }}
                  >
                    {cell?.kind === 'virus' ? 'v' : ''}
                  </Box>
                </Stack.Item>
              ))}
            </Stack>
          ))}
        </div>
      </div>
    </div>
  );
};
