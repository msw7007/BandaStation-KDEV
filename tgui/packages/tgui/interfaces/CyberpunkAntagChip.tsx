import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type ChipAction = {
  id: string;
  label: string;
  description?: string;
  cost?: number;
};

type ResourceData = {
  influence?: number;
  funds?: number;
  supplies?: number;
  manpower?: number;
  total?: number;
};

type SpyTask = {
  text: string;
};

type CyberpunkAntagChipData = {
  valid: BooleanLike;
  mode: string;
  title: string;
  subtitle: string;
  briefing?: string;
  progress?: number;
  goal?: number;
  complete?: BooleanLike;
  team?: string;
  resources?: ResourceData;
  balance?: number;
  ordered?: BooleanLike;
  drop?: string;
  tasks?: SpyTask[];
  completedToday?: number;
  damageScore?: number;
  actions?: ChipAction[];
};

const actionIcon = (action: ChipAction) => {
  const id = action.id.toLowerCase();

  if (id.includes('sync') || id.includes('upload')) {
    return 'upload';
  }
  if (id.includes('status')) {
    return 'info-circle';
  }
  if (id.includes('gang') || id.includes('recruit')) {
    return 'users';
  }
  if (id.includes('sabotage')) {
    return 'wrench';
  }
  if (id.includes('knife') || id.includes('rifle') || id.includes('sidearm')) {
    return 'crosshairs';
  }
  if (id.includes('breacher')) {
    return 'hammer';
  }
  if (id.includes('heavy')) {
    return 'box';
  }
  return 'bolt';
};

const actionColor = (action: ChipAction) => {
  const id = action.id.toLowerCase();

  if (id.includes('sabotage') || id.includes('heavy')) {
    return 'bad';
  }
  if (id.includes('sync') || id.includes('upload') || id.includes('status')) {
    return 'good';
  }
  return undefined;
};

const ActionSection = (props: {
  actions: ChipAction[];
  ordered?: BooleanLike;
  onAction: (id: string) => void;
  onClaim: () => void;
}) => {
  const { actions, ordered, onAction, onClaim } = props;

  if (ordered) {
    return (
      <Section title="Actions">
        <Button fluid icon="parachute-box" color="good" onClick={onClaim}>
          Claim marked drop
        </Button>
      </Section>
    );
  }

  return (
    <Section title="Actions">
      <Stack vertical>
        {actions.map((action) => (
          <Stack.Item key={action.id}>
            <Stack align="center">
              <Stack.Item grow>
                <Box bold>{action.label}</Box>
                {!!action.description && (
                  <Box color="label" mt={0.5}>
                    {action.description}
                  </Box>
                )}
                {!!action.cost && (
                  <Box color="average" mt={0.5}>
                    {action.cost} credits
                  </Box>
                )}
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon={actionIcon(action)}
                  color={actionColor(action)}
                  onClick={() => onAction(action.id)}
                >
                  Run
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

export const CyberpunkAntagChip = () => {
  const { act, data } = useBackend<CyberpunkAntagChipData>();
  const {
    valid,
    title,
    subtitle,
    briefing,
    progress = 0,
    goal = 1,
    complete,
    team,
    resources,
    balance,
    ordered,
    drop,
    tasks = [],
    completedToday,
    damageScore,
    actions = [],
  } = data;

  const maxGoal = Math.max(goal || 1, 1);
  const progressValue = Math.min(progress, maxGoal);

  return (
    <Window title={subtitle || 'Antagonist Chip'} width={560} height={520}>
      <Window.Content scrollable>
        {!valid ? (
          <NoticeBox danger>Access denied.</NoticeBox>
        ) : (
          <Stack vertical>
            <Stack.Item>
              <Section
                title={title || subtitle}
                buttons={
                  <Button
                    icon="sync"
                    tooltip="Refresh"
                    onClick={() => act('refresh')}
                  />
                }
              >
                <LabeledList>
                  {!!team && (
                    <LabeledList.Item label="Team">{team}</LabeledList.Item>
                  )}
                  {balance !== undefined && (
                    <LabeledList.Item label="Balance">
                      {balance} credits
                    </LabeledList.Item>
                  )}
                  {drop && <LabeledList.Item label="Drop">{drop}</LabeledList.Item>}
                  {damageScore !== undefined && (
                    <LabeledList.Item label="Damage score">
                      {damageScore}
                    </LabeledList.Item>
                  )}
                  {completedToday !== undefined && (
                    <LabeledList.Item label="Uploaded today">
                      {completedToday}
                    </LabeledList.Item>
                  )}
                  <LabeledList.Item label="Progress">
                    <ProgressBar
                      value={progressValue}
                      minValue={0}
                      maxValue={maxGoal}
                      ranges={{
                        good: [maxGoal, maxGoal],
                        average: [maxGoal * 0.5, maxGoal],
                        bad: [0, maxGoal * 0.5],
                      }}
                    >
                      {progress} / {goal || '-'}
                    </ProgressBar>
                  </LabeledList.Item>
                </LabeledList>
                {!!complete && (
                  <NoticeBox mt={1} color="green">
                    Objective complete.
                  </NoticeBox>
                )}
              </Section>
            </Stack.Item>

            {!!briefing && (
              <Stack.Item>
                <Section title="Directive">
                  <NoticeBox info>{briefing}</NoticeBox>
                </Section>
              </Stack.Item>
            )}

            {!!resources && (
              <Stack.Item>
                <Section title="Resources">
                  <LabeledList>
                    <LabeledList.Item label="Influence">
                      {resources.influence || 0}
                    </LabeledList.Item>
                    <LabeledList.Item label="Funds">
                      {resources.funds || 0}
                    </LabeledList.Item>
                    <LabeledList.Item label="Supplies">
                      {resources.supplies || 0}
                    </LabeledList.Item>
                    <LabeledList.Item label="Manpower">
                      {resources.manpower || 0}
                    </LabeledList.Item>
                  </LabeledList>
                </Section>
              </Stack.Item>
            )}

            {!!tasks.length && (
              <Stack.Item>
                <Section title="Current Tasks">
                  <Stack vertical>
                    {tasks.map((task, index) => (
                      <Stack.Item key={`${index}-${task.text}`}>
                        <Box>
                          {index + 1}. {task.text}
                        </Box>
                      </Stack.Item>
                    ))}
                  </Stack>
                </Section>
              </Stack.Item>
            )}

            <Stack.Item>
              <ActionSection
                actions={actions}
                ordered={ordered}
                onAction={(id) => act('run_action', { id })}
                onClaim={() => act('claim_drop')}
              />
            </Stack.Item>
          </Stack>
        )}
      </Window.Content>
    </Window>
  );
};
