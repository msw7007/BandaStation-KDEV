import { Box, Stack } from 'tgui-core/components';

import { useBackend } from '../../backend';
import type { CorporateMinigameData, MineCell } from './types';

const mineLabel = (cell: MineCell) => {
  if (cell.open && cell.bomb) {
    return 'X';
  }
  if (cell.flag) {
    return 'F';
  }
  if (cell.open && cell.around > 0) {
    return cell.around;
  }
  return '';
};

export const Minesweeper = () => {
  const { act, data } = useBackend<CorporateMinigameData>();

  return (
    <div className="StyleGuide__blockShell" style={{ display: 'inline-block' }}>
      <div className="StyleGuide__blockTitle">Survey grid: {data.bombs} hazards</div>
      <div className="StyleGuide__trapezoidNote">
        Open safe cells. Numbers show nearby hazards. Right-click a cell to mark it.
      </div>
      <Box className="StyleGuide__innerPanel" style={{ display: 'inline-block' }}>
        {data.mineBoard?.map((row, y) => (
          <Stack key={y} mb={0.25}>
            {row.map((cell, x) => (
              <Stack.Item key={`${x}-${y}`}>
                <button
                  type="button"
                  className="StyleGuide__iconButton StyleGuide__iconButton--cyan"
                  onClick={() => act('mine_open', { x, y })}
                  onContextMenu={(event) => {
                    event.preventDefault();
                    act('mine_flag', { x, y });
                  }}
                  style={{
                    width: '38px',
                    height: '38px',
                    minWidth: '38px',
                    color: cell.open && cell.bomb ? '#f02c42' : '#ffffff',
                    fontWeight: 900,
                    background: cell.open
                      ? 'rgba(5, 12, 16, 0.95)'
                      : 'rgba(36, 95, 128, 0.85)',
                  }}
                >
                  {mineLabel(cell)}
                </button>
              </Stack.Item>
            ))}
          </Stack>
        ))}
      </Box>
    </div>
  );
};
