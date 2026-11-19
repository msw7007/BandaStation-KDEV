import {
  DmIcon,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import { capitalizeFirst } from 'tgui-core/string';

import { useBackend } from '../../backend';
import { TraitTooltip } from '../SeedExtractor';
import { Fallback } from './Fallback';
import { GrowthTimeBar } from './Seed';
import type { PlantAnalyzerData } from './types';

export function PlantAnalyzerGraft(props) {
  const { data } = useBackend<PlantAnalyzerData>();
  const { graft_data, cycle_seconds, stat_limits } = data;

  if (!graft_data) {
    // This shouldn't be rendered if graft_data is null
    return null;
  }

  return (
    <Section
      title={`Graft: ${capitalizeFirst(graft_data.name)}`}
      buttons={
        !!graft_data.graft_gene && (
          <TraitTooltip path={graft_data.graft_gene} trait_db={data.trait_db} />
        )
      }
    >
      <Stack>
        <Stack.Item mx={2}>
          <DmIcon
            fallback={Fallback}
            icon={graft_data.icon}
            icon_state={graft_data.icon_state}
            height="64px"
            width="64px"
          />
        </Stack.Item>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Выносливость">
              <ProgressBar
                value={graft_data.endurance / 100}
                ranges={{
                  good: [0.5, Infinity],
                  average: [0.1, 0.5],
                  bad: [0, 0.1],
                }}
              >
                {graft_data.endurance} / 100
              </ProgressBar>
            </LabeledList.Item>

            <LabeledList.Item label="Срок жизни">
              <GrowthTimeBar
                value={graft_data.lifespan}
                maxValue={stat_limits.lifespan}
                cycleSeconds={cycle_seconds}
              />
            </LabeledList.Item>

            <LabeledList.Item label="Урожайность">
              <ProgressBar
                value={graft_data.yield / 10}
                ranges={{
                  good: [0.7, Infinity],
                  average: [0.3, 0.7],
                  bad: [0, 0.3],
                }}
              >
                {graft_data.yield} / 10
              </ProgressBar>
            </LabeledList.Item>

            <LabeledList.Item label="Шанс роста сорняков">
              <ProgressBar
                value={graft_data.weed_chance}
                maxValue={100}
                ranges={{
                  good: [-Infinity, 20],
                  average: [20, 40],
                  bad: [40, Infinity],
                }}
              >
                {graft_data.weed_chance}%
              </ProgressBar>
            </LabeledList.Item>

            <LabeledList.Item label="Рост урожая">
              <GrowthTimeBar
                value={graft_data.production}
                maxValue={stat_limits.production}
                cycleSeconds={cycle_seconds}
              />
            </LabeledList.Item>

            <LabeledList.Item label="Прирост сорняков">
              <ProgressBar
                value={graft_data.weed_rate}
                maxValue={stat_limits.weed_rate}
              >
                {graft_data.weed_rate} / {stat_limits.weed_rate}
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
      </Stack>
    </Section>
  );
}
