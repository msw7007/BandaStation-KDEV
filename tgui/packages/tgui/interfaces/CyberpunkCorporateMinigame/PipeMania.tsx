import { Box, Stack } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { pipeCorner, pipeStraight } from './assetData';
import type { CorporateMinigameData, PipePart } from './types';

const pipeAsset = (part: PipePart) =>
  part.type === 'straight' ? pipeStraight : pipeCorner;

export const PipeMania = () => {
  const { act, data } = useBackend<CorporateMinigameData>();

  return (
    <div className="StyleGuide__blockShell" style={{ display: 'inline-block' }}>
      <div className="StyleGuide__blockTitle">Energy contour</div>
      <div className="StyleGuide__trapezoidNote">
        Rotate pipes to connect the source in the top-left to the output in the bottom-left, then start the flow.
      </div>
      <div className="StyleGuide__actionRow">
        <button
          type="button"
          className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
          disabled={data.flowStarted}
          onClick={() => act('pipe_flow')}
        >
          Start flow
        </button>
      </div>
      <Box mt={1} className="StyleGuide__innerPanel">
        {data.pipeBoard?.map((row, y) => (
          <Stack key={y} mb={0.5}>
            {row.map((part, x) => (
              <Stack.Item key={`${x}-${y}`}>
                <button
                  type="button"
                  className="StyleGuide__iconButton StyleGuide__iconButton--large StyleGuide__iconButton--cyan"
                  onClick={() => act('pipe_rotate', { x, y })}
                >
                  <img
                    alt=""
                    src={pipeAsset(part)}
                    style={{
                      width: '44px',
                      height: '44px',
                      transform: `rotate(${part.rotation * 90}deg)`,
                    }}
                  />
                </button>
              </Stack.Item>
            ))}
          </Stack>
        ))}
      </Box>
    </div>
  );
};
