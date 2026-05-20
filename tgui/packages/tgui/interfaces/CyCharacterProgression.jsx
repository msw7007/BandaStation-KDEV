import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

export const CyCharacterProgression = (props) => {
  const { act, data } = useBackend();
  const {
    stat_points = 0,
    skill_points = 0,
    stats = [],
    skills = [],
    can_show_character_level,
    character_level,
  } = data;

  return (
    <Window title="Character" width={760} height={680}>
      <Window.Content scrollable>
        <Section
          title="Progression"
          buttons={
            <>
              <Button
                icon="exchange-alt"
                disabled={stat_points < 1}
                onClick={() => act('stat_to_skill')}
                tooltip="Convert 1 stat point into 2 skill points."
              >
                Stat to Skills
              </Button>
              <Button
                icon="exchange-alt"
                disabled={skill_points < 2}
                onClick={() => act('skill_to_stat')}
                tooltip="Convert 2 skill points into 1 stat point."
              >
                Skills to Stat
              </Button>
            </>
          }
        >
          <LabeledList>
            {!!can_show_character_level && (
              <LabeledList.Item label="Character level">
                {character_level}
              </LabeledList.Item>
            )}
            <LabeledList.Item label="Stat points">{stat_points}</LabeledList.Item>
            <LabeledList.Item label="Skill points">
              {skill_points}
            </LabeledList.Item>
          </LabeledList>
        </Section>

        <Section title="Characteristics">
          <Table>
            <Table.Row header>
              <Table.Cell>Name</Table.Cell>
              <Table.Cell textAlign="center">Base</Table.Cell>
              <Table.Cell textAlign="center">Current</Table.Cell>
              <Table.Cell textAlign="center">Action</Table.Cell>
            </Table.Row>
            {stats.map((stat) => (
              <Table.Row key={stat.path}>
                <Table.Cell>{stat.name}</Table.Cell>
                <Table.Cell textAlign="center">
                  {stat.value}/{stat.max_value}
                </Table.Cell>
                <Table.Cell textAlign="center">
                  {stat.effective_value}
                </Table.Cell>
                <Table.Cell textAlign="center">
                  <Button
                    icon="plus"
                    disabled={!stat.can_raise}
                    onClick={() => act('raise_stat', { stat: stat.path })}
                  >
                    Raise
                  </Button>
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>

        <Section title="Skills">
          {!skills.length && <NoticeBox>No skills available.</NoticeBox>}
          {!!skills.length && (
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell textAlign="center">Level</Table.Cell>
                <Table.Cell textAlign="center">Gate</Table.Cell>
                <Table.Cell textAlign="center">Cost</Table.Cell>
                <Table.Cell textAlign="center">Action</Table.Cell>
              </Table.Row>
              {skills.map((skill) => (
                <Table.Row key={skill.path}>
                  <Table.Cell>
                    <Stack vertical>
                      <Stack.Item>
                        <Box bold>{skill.name}</Box>
                      </Stack.Item>
                      {!!skill.desc && (
                        <Stack.Item color="label">{skill.desc}</Stack.Item>
                      )}
                    </Stack>
                  </Table.Cell>
                  <Table.Cell textAlign="center">
                    {skill.level_name} ({skill.level}/{skill.max_level})
                  </Table.Cell>
                  <Table.Cell textAlign="center">
                    {skill.unlocked_level}/{skill.max_level}
                  </Table.Cell>
                  <Table.Cell textAlign="center">
                    {skill.level >= skill.max_level ? '-' : skill.cost}
                  </Table.Cell>
                  <Table.Cell textAlign="center">
                    <Button
                      icon="plus"
                      disabled={!skill.can_raise}
                      onClick={() => act('raise_skill', { skill: skill.path })}
                    >
                      Raise
                    </Button>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
