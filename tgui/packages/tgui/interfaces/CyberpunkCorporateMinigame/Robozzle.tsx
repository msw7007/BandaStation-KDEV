import { Box, Button, Stack } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { roboRobot, roboStar } from './assetData';
import { pillColor } from './colors';
import type { CorporateMinigameData } from './types';

export const Robozzle = () => {
  const { act, data } = useBackend<CorporateMinigameData>();
  const commands = ['forward', 'left', 'right'];
  const conditions = ['red', 'green', 'blue'];
  const commandLabel = {
    forward: 'forward',
    left: 'turn left',
    right: 'turn right',
  };

  return (
    <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'flex-start' }}>
      <div className="StyleGuide__blockShell" style={{ width: '365px' }}>
        <div className="StyleGuide__blockTitle">Program</div>
        <div className="StyleGuide__trapezoidNote">
          Add color-bound commands. Turn left and turn right rotate the robot in place. Forward moves one square. Collect all points.
        </div>
        {conditions.map((condition) => (
          <Stack key={condition} mb={0.5} align="center">
            <Stack.Item width={5}>{condition}</Stack.Item>
            {commands.map((command) => (
              <Stack.Item key={`${condition}-${command}`}>
                <Button
                  icon="plus"
                  onClick={() => act('robo_add', { command, condition })}
                >
                  {commandLabel[command]}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        ))}
        <Stack mt={1}>
          <Stack.Item grow>
            <Box color="label">{data.program?.join(' -> ') || 'empty'}</Box>
          </Stack.Item>
          <Stack.Item>
            <Button icon="trash" onClick={() => act('robo_clear')} />
          </Stack.Item>
          <Stack.Item>
            <Button icon="play" color="good" onClick={() => act('robo_run')} />
          </Stack.Item>
        </Stack>
      </div>
      <div className="StyleGuide__blockShell" style={{ width: '280px' }}>
        <div className="StyleGuide__blockTitle">Robot heading {data.robot?.direction}</div>
        {[0, 1, 2, 3, 4].map((y) => (
          <Stack key={y} mb={0.25}>
            {[0, 1, 2, 3, 4].map((x) => {
              const robot = data.robot?.x === x && data.robot?.y === y;
              const star = data.stars?.[`${x},${y}`];
              return (
                <Stack.Item key={`${x}-${y}`}>
                  <Box
                    width="46px"
                    height="46px"
                    textAlign="center"
                    backgroundColor={pillColor(data.tiles?.[y]?.[x] || '')}
                    style={{ position: 'relative', border: '1px solid #14c6ee' }}
                  >
                    {star && <img alt="" src={roboStar} style={{ width: '24px', height: '24px', marginTop: '10px' }} />}
                    {robot && (
                      <img
                        alt=""
                        src={roboRobot}
                        style={{ width: '34px', height: '34px', position: 'absolute', left: '6px', top: '6px' }}
                      />
                    )}
                  </Box>
                </Stack.Item>
              );
            })}
          </Stack>
        ))}
      </div>
    </div>
  );
};
