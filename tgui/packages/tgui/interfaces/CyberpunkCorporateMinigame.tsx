import { Box, NoticeBox } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { DrMario } from './CyberpunkCorporateMinigame/DrMario';
import { Minesweeper } from './CyberpunkCorporateMinigame/Minesweeper';
import { PapersPlease } from './CyberpunkCorporateMinigame/PapersPlease';
import { PipeMania } from './CyberpunkCorporateMinigame/PipeMania';
import { Research } from './CyberpunkCorporateMinigame/Research';
import { Robozzle } from './CyberpunkCorporateMinigame/Robozzle';
import { TripleTown } from './CyberpunkCorporateMinigame/TripleTown';
import type { CorporateMinigameData } from './CyberpunkCorporateMinigame/types';

export const CyberpunkCorporateMinigame = () => {
  const { act, data } = useBackend<CorporateMinigameData>();

  return (
    <Window width={680} height={640} theme="cyberpunk">
      <Window.Content scrollable className="CyberpunkPanel StyleGuide">
        <div className="StyleGuide__compactHeader">
          <div>
            <div className="StyleGuide__eyebrow">Corporate research</div>
            <h1>{data.title}</h1>
          </div>
          <div className={data.completed ? 'StyleGuide__statusPill' : 'StyleGuide__statusPill danger'}>
            {data.completed ? 'Complete' : 'Active'}
          </div>
        </div>

        <div
          className="StyleGuide__actionRow"
          style={{ alignItems: 'center', marginBottom: '0.6rem' }}
        >
          <div className="StyleGuide__statusPill">
            Progress: {data.progress} / {data.goal}
          </div>
          <div className="StyleGuide__actionRow" style={{ marginLeft: 'auto' }}>
            <button
              type="button"
              className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
              onClick={() => act('restart_game')}
            >
              Restart
            </button>
            <button
              type="button"
              className="StyleGuide__cutButton StyleGuide__cutButton--red-dark"
              onClick={() => act('PC_exit')}
            >
              Exit
            </button>
          </div>
        </div>

        {data.completed ? (
          <div className="StyleGuide__blockShell">
            <NoticeBox success={data.result.includes('complete')}>
              {data.result}
            </NoticeBox>
            <Box mt={1} className="StyleGuide__actionRow">
              <button
                type="button"
                className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
                onClick={() => act('restart_game')}
              >
                New session
              </button>
              <button
                type="button"
                className="StyleGuide__cutButton StyleGuide__cutButton--red-dark"
                onClick={() => act('PC_exit')}
              >
                Exit
              </button>
            </Box>
          </div>
        ) : (
          <GameBody game={data.game} />
        )}
      </Window.Content>
    </Window>
  );
};

const GameBody = (props: { game: string }) => {
  switch (props.game) {
    case 'dr_mario':
      return <DrMario />;
    case 'triple_town':
      return <TripleTown />;
    case 'pipe_mania':
      return <PipeMania />;
    case 'robozzle':
      return <Robozzle />;
    case 'minesweeper':
      return <Minesweeper />;
    case 'research':
      return <Research />;
    case 'papers_please':
    default:
      return <PapersPlease />;
  }
};
