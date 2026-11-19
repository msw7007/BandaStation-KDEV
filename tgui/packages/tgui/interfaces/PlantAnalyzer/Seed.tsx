import {
  Blink,
  Box,
  Button,
  Collapsible,
  DmIcon,
  Icon,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Table,
  Tooltip,
} from 'tgui-core/components';
import { capitalizeFirst } from 'tgui-core/string';

import { useBackend } from '../../backend';
import { Fallback } from './Fallback';
import type { PlantAnalyzerData, ReagentData, SeedData } from './types';

export function PlantAnalyzerSeedStats(props) {
  const { data } = useBackend<PlantAnalyzerData>();
  const { seed_data, tray_data, cycle_seconds, stat_limits, trait_db } = data;

  if (!seed_data) {
    // This shouldn't be rendered if seed data is null
    return null;
  }

  const all_traits = [
    ...(seed_data.core_traits || []),
    ...(seed_data.removable_traits || []),
  ];

  return (
    <Section title={capitalizeFirst(seed_data.name)}>
      <Stack>
        <Stack.Item mx={1}>
          <Stack vertical align="center" width="150px">
            <Stack.Item>
              <DmIcon
                fallback={Fallback}
                icon={seed_data.icon}
                icon_state={seed_data.icon_state}
                height="64px"
                width="64px"
              />
            </Stack.Item>
            {seed_data.product_icon && seed_data.product_icon_state && (
              <Stack.Item>
                <DmIcon
                  mt={2}
                  fallback={Fallback}
                  icon={seed_data.product_icon}
                  icon_state={seed_data.product_icon_state}
                  height="64px"
                  width="64px"
                />
              </Stack.Item>
            )}
            <Stack.Item width="100%">
              <Button
                fluid
                icon="scissors"
                disabled={1}
                color="teal"
                ellipsis
                tooltip={
                  'Using secateurs on the plant will produce a graft \
                  containing the listed gene.'
                }
              >
                {getTraitInfo(seed_data.graft_gene, trait_db)?.name ||
                  'No graft gene'}
              </Button>
            </Stack.Item>
            {seed_data.mutatelist.length > 0 && (
              <Stack.Item width="100%">
                <Collapsible title="Mutations:" color="olive" textColor="black">
                  <Stack vertical>
                    {seed_data.mutatelist.map((mutation) => (
                      <Stack.Item key={`preview_${mutation}`} width="100%">
                        <Button
                          fluid
                          ellipsis
                          icon="dna"
                          disabled={1}
                          color="olive"
                          textColor="black"
                          tooltip={
                            'Once sufficiently unstable the plant may mutate \
                    into the listed plant.'
                          }
                        >
                          {mutation}
                        </Button>
                      </Stack.Item>
                    ))}
                  </Stack>
                </Collapsible>
              </Stack.Item>
            )}
          </Stack>
        </Stack.Item>
        <Stack.Item width="100%">
          <LabeledList>
            {tray_data && (
              <LabeledList.Item label="Здоровье">
                <ProgressBar
                  value={tray_data.plant_health / seed_data.endurance}
                  ranges={{
                    good: [0.7, Infinity],
                    average: [0.3, 0.7],
                    bad: [0, 0.3],
                  }}
                >
                  {tray_data.plant_health} / {seed_data.endurance}
                </ProgressBar>
              </LabeledList.Item>
            )}

            <LabeledList.Item
              label="Выносливость"
              tooltip="Определяет запас здоровья растения. Влияет на качество урожая."
            >
              <ProgressBar
                value={seed_data.endurance / 100}
                ranges={{
                  good: [0.7, Infinity],
                  average: [0.3, 0.7],
                  bad: [0, 0.3],
                }}
              >
                {seed_data.endurance} / 100
              </ProgressBar>
            </LabeledList.Item>

            {tray_data && (
              <LabeledList.Item label="Возраст">
                {tray_data.is_dead ? (
                  <NoticeBox color="red" align="center">
                    <Icon name="skull" mr={1} />
                    Растение погибло
                  </NoticeBox>
                ) : (
                  <ProgressBar
                    value={tray_data.plant_age}
                    maxValue={seed_data.lifespan}
                    ranges={{
                      average: [0, seed_data.maturation],
                      good: [seed_data.maturation, seed_data.lifespan],
                      bad: [seed_data.lifespan, Infinity],
                    }}
                  >
                    {formatGrowthTime(tray_data.plant_age, cycle_seconds)} /{' '}
                    {formatGrowthTime(seed_data.lifespan, cycle_seconds)}
                  </ProgressBar>
                )}
              </LabeledList.Item>
            )}

            <LabeledList.Item
              label="Созревание"
              tooltip="Возраст начала плодоношения. Полоса показывает долю срока жизни до созревания."
            >
              <GrowthTimeBar
                value={seed_data.maturation}
                maxValue={Math.max(seed_data.lifespan, seed_data.maturation, 1)}
                cycleSeconds={cycle_seconds}
              />
            </LabeledList.Item>

            <LabeledList.Item
              label="Рост урожая"
              tooltip="Время, за которое у зрелого растения вырастает урожай."
            >
              <GrowthTimeBar
                value={seed_data.production}
                maxValue={stat_limits.production}
                cycleSeconds={cycle_seconds}
              />
            </LabeledList.Item>

            <LabeledList.Item
              label="Срок жизни"
              tooltip="Возраст, с которого растение начинает увядать. Влияет на качество урожая."
            >
              <GrowthTimeBar
                value={seed_data.lifespan}
                maxValue={stat_limits.lifespan}
                cycleSeconds={cycle_seconds}
              />
            </LabeledList.Item>

            <LabeledList.Item
              label="Урожайность"
              tooltip="Количество плодов за один сбор."
            >
              <ProgressBar
                value={seed_data.yield / 10}
                ranges={{
                  good: [0.7, Infinity],
                  average: [0.3, 0.7],
                  bad: [0, 0.3],
                }}
              >
                {seed_data.yield} / 10
              </ProgressBar>
            </LabeledList.Item>

            <LabeledList.Item
              label="Потенция"
              tooltip="Влияет на массу урожая, количество реагентов и силу эффектов."
            >
              <ProgressBar
                value={seed_data.potency / 100}
                ranges={{
                  good: [0.7, Infinity],
                  average: [0.3, 0.7],
                  bad: [0, 0.3],
                }}
              >
                {seed_data.potency} / 100
              </ProgressBar>
            </LabeledList.Item>

            <LabeledList.Item
              label="Мутационный потенциал"
              tooltip="Вероятность закрепления признака в смешивателе. При извлечении следующего поколения уменьшается на 10 п. п."
            >
              <ProgressBar
                value={seed_data.mutation_potential}
                maxValue={100}
                ranges={{
                  good: [70, Infinity],
                  average: [30, 70],
                  bad: [0, 30],
                }}
              >
                {seed_data.mutation_potential}%
              </ProgressBar>
            </LabeledList.Item>

            <LabeledList.Item
              label="Нестабильность"
              tooltip="Влияет на вероятность случайных изменений и качество урожая."
            >
              <ProgressBar
                value={seed_data.instability}
                maxValue={100}
                ranges={{
                  good: [-Infinity, 20],
                  average: [20, 40],
                  bad: [40, Infinity],
                }}
              >
                {seed_data.instability} / 100
              </ProgressBar>
            </LabeledList.Item>

            <LabeledList.Item
              label="Шанс роста сорняков"
              tooltip={`Проверяется раз в ${cycle_seconds} с.`}
            >
              <ProgressBar value={seed_data.weed_chance} maxValue={100}>
                {seed_data.weed_chance}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item
              label="Прирост сорняков"
              tooltip="На сколько вырастут сорняки при успешной проверке."
            >
              <ProgressBar
                value={seed_data.weed_rate}
                maxValue={stat_limits.weed_rate}
              >
                {seed_data.weed_rate} / {stat_limits.weed_rate}
              </ProgressBar>
            </LabeledList.Item>
            {seed_data.unique_labels.map((label) => (
              <LabeledList.Item key={label.label} label={label.label}>
                {label.data}
              </LabeledList.Item>
            ))}
          </LabeledList>
          <Collapsible title="Traits:" open color="brown" width="100%" mt={1}>
            <Stack vertical>
              {all_traits.map((trait) => {
                const traitInfo = getTraitInfo(trait, trait_db);
                return (
                  <Stack.Item key={`${trait}_removable`} width="100%">
                    <Button
                      ellipsis
                      fluid
                      color={
                        seed_data.core_traits.includes(trait)
                          ? 'transparent'
                          : 'blue'
                      }
                      disabled={1}
                      tooltip={traitInfo?.description}
                      icon={traitInfo?.icon}
                    >
                      {traitInfo?.name || 'Unknown Trait'}
                    </Button>
                  </Stack.Item>
                );
              })}
            </Stack>
          </Collapsible>
          {seed_data.unique_collapsibles.map((collapsible) => (
            <Collapsible
              key={collapsible.label}
              title={collapsible.label}
              color="brown"
              width="100%"
              mt={1}
            >
              <Stack vertical>
                {Object.entries(collapsible.data).map(
                  ([dataText, dataTooltip]) => (
                    <Stack.Item key={dataText} width="100%">
                      <Button
                        ellipsis
                        fluid
                        color="transparent"
                        disabled={1}
                        tooltip={dataTooltip}
                      >
                        {dataText}
                      </Button>
                    </Stack.Item>
                  ),
                )}
              </Stack>
            </Collapsible>
          ))}
        </Stack.Item>
      </Stack>
    </Section>
  );
}

export function PlantAnalyzerSeedChems(props) {
  const { data } = useBackend<PlantAnalyzerData>();
  const { seed_data } = data;

  if (!seed_data) {
    // This shouldn't be rendered if seed data is null
    return null;
  }

  const totalPercentage = seed_data.reagents.reduce(
    (sum, reagent) => sum + reagent.rate * 100,
    0,
  );

  const totalVolume =
    seed_data.reagents.reduce(
      (sum, reagent) => sum + expectedReagentVolume(reagent, seed_data),
      0,
    ) || 0;

  return (
    <Section title={capitalizeFirst(`${seed_data.name} Genes`)}>
      <Stack>
        <Stack.Item width="100%">
          {seed_data.reagents.length === 0 ? (
            <NoticeBox color="green" align="center">
              No reagent genes
            </NoticeBox>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Reagent</Table.Cell>
                <Table.Cell>Percentage</Table.Cell>
                <Table.Cell>
                  <Tooltip
                    content={
                      'Assuming the plant does not exceed its maximum capacity, \
                        this is what you can expect to obtain from consuming \
                        or grinding the product of the seed.'
                    }
                  >
                    <Box
                      inline
                      style={{
                        borderBottom: '2px dotted rgba(255, 255, 255, 0.8)',
                      }}
                    >
                      Expected Volume
                    </Box>
                  </Tooltip>
                </Table.Cell>
              </Table.Row>
              {seed_data.reagents.map((reagent) => (
                <Table.Row key={reagent.name} className="candystripe">
                  <Table.Cell py={0.2} pl={1}>
                    {reagent.name}
                  </Table.Cell>
                  <Table.Cell>{reagent.rate * 100}%</Table.Cell>
                  <Table.Cell>
                    ~{expectedReagentVolume(reagent, seed_data)}u
                  </Table.Cell>
                </Table.Row>
              ))}
              <Table.Row
                className="candystripe"
                style={{ borderTop: '2px dotted gray' }}
              >
                <Table.Cell py={1} pl={1}>
                  Total
                </Table.Cell>
                <Table.Cell>
                  {totalPercentage}%
                  {totalPercentage > 100 && (
                    <Blink>
                      <Button
                        icon="exclamation-triangle"
                        ml={1}
                        disabled={1}
                        color="transparent"
                        tooltip="Exceeds 100% - each reagent
                        will be proportionally reduced in the product."
                      />
                    </Blink>
                  )}
                </Table.Cell>
                <Table.Cell>~{totalVolume}u</Table.Cell>
              </Table.Row>
              <Table.Row
                className="candystripe"
                style={{ borderTop: '2px dotted gray' }}
              >
                <Table.Cell py={1} pl={1}>
                  Cap
                </Table.Cell>
                <Table.Cell>100%</Table.Cell>
                <Table.Cell>
                  ~{seed_data.volume_mod * seed_data.volume_units}u
                </Table.Cell>
              </Table.Row>
              {seed_data.grind_results.length > 0 && (
                <Table.Row
                  className="candystripe"
                  style={{ borderTop: '2px dotted gray' }}
                >
                  <Table.Cell py={0.5} pl={1} colSpan={2}>
                    <i>Grinds nutriments into:</i>
                  </Table.Cell>
                  <Table.Cell>{seed_data.grind_results.join(', ')}</Table.Cell>
                </Table.Row>
              )}
              {seed_data.juice_name && (
                <Table.Row
                  className="candystripe"
                  style={{ borderTop: '2px dotted gray' }}
                >
                  <Table.Cell py={0.5} pl={1} colSpan={2}>
                    <i>Juices into:</i>
                  </Table.Cell>
                  <Table.Cell>{seed_data.juice_name}</Table.Cell>
                </Table.Row>
              )}
              {seed_data.distill_reagent && (
                <Table.Row
                  className="candystripe"
                  style={{ borderTop: '2px dotted gray' }}
                >
                  <Table.Cell py={0.5} pl={1} colSpan={2}>
                    <i>Distills into:</i>
                  </Table.Cell>
                  <Table.Cell>{seed_data.distill_reagent}</Table.Cell>
                </Table.Row>
              )}
            </Table>
          )}
        </Stack.Item>
      </Stack>
    </Section>
  );
}

export function PlantAnalyzerPlantChems(props) {
  const { data } = useBackend<PlantAnalyzerData>();
  const { seed_data, plant_data } = data;

  if (!seed_data || !plant_data) {
    // This shouldn't be rendered if seed or plant data is null
    return null;
  }

  return (
    <Section title={capitalizeFirst(`${seed_data.name} Contents`)}>
      <Stack>
        <Stack.Item width="100%">
          {plant_data.reagents.length === 0 ? (
            <NoticeBox color="green" align="center">
              No reagent genes
            </NoticeBox>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell colSpan={2}>Reagent</Table.Cell>
                <Table.Cell>Volume</Table.Cell>
              </Table.Row>
              {plant_data.reagents.map((reagent) => (
                <Table.Row key={reagent.name} className="candystripe">
                  <Table.Cell py={0.2} pl={1} colSpan={2}>
                    {reagent.name}
                  </Table.Cell>
                  <Table.Cell>{reagent.volume}</Table.Cell>
                </Table.Row>
              ))}
              <Table.Row
                className="candystripe"
                style={{ borderTop: '2px dotted gray' }}
              >
                <Table.Cell py={1} pl={1} colSpan={2}>
                  Total
                </Table.Cell>
                <Table.Cell>
                  {plant_data.reagents.reduce(
                    (sum, reagent) => sum + reagent.volume,
                    0,
                  )}
                  u
                </Table.Cell>
              </Table.Row>
            </Table>
          )}
        </Stack.Item>
      </Stack>
    </Section>
  );
}

function expectedReagentVolume(
  reagent: ReagentData,
  seed_data: SeedData,
): number {
  const baseVolume = seed_data.volume_units * seed_data.volume_mod;
  return Math.round(reagent.rate * baseVolume * (seed_data.potency / 100)) || 0;
}

export function GrowthTimeBar(props: {
  value: number;
  maxValue: number;
  cycleSeconds: number;
}) {
  const { value, maxValue, cycleSeconds } = props;
  return (
    <ProgressBar value={value} maxValue={maxValue} color="blue">
      {formatGrowthTime(value, cycleSeconds)}
    </ProgressBar>
  );
}

function formatGrowthTime(cycles: number, cycleSeconds: number) {
  if (cycles < 0) {
    return '—';
  }
  const seconds = Math.round(cycles * cycleSeconds);
  if (seconds < 60) {
    return `${seconds} с`;
  }
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return remainingSeconds
    ? `${minutes} мин ${remainingSeconds} с`
    : `${minutes} мин`;
}

function getTraitInfo(trait: string, trait_db: PlantAnalyzerData['trait_db']) {
  const traitData = trait_db.find((t) => t.path === trait);
  return traitData;
}
