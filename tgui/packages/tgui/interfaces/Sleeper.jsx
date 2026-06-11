import {
  Box,
  Button,
  LabeledList,
  ProgressBar,
  Section,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

const damageTypes = [
  {
    label: 'Brute',
    type: 'bruteLoss',
  },
  {
    label: 'Burn',
    type: 'fireLoss',
  },
  {
    label: 'Toxin',
    type: 'toxLoss',
  },
  {
    label: 'Oxygen',
    type: 'oxyLoss',
  },
];

export const Sleeper = (props) => {
  const { act, data } = useBackend();
  const {
    bioscanner,
    bodyScan = [],
    lastBioscan,
    nextBioscan,
    open,
    organScan = [],
    occupant = {},
    occupied,
  } = data;
  const preSortChems = data.chems || [];
  const chems = preSortChems.sort((a, b) => {
    const descA = a.name.toLowerCase();
    const descB = b.name.toLowerCase();
    if (descA < descB) {
      return -1;
    }
    if (descA > descB) {
      return 1;
    }
    return 0;
  });
  return (
    <Window width={bioscanner ? 560 : 310} height={bioscanner ? 620 : 465}>
      <Window.Content scrollable={bioscanner}>
        <Section
          title={occupant.name ? occupant.name : 'No Occupant'}
          minHeight="210px"
          buttons={
            !!occupant.stat && (
              <Box inline bold color={occupant.statstate}>
                {occupant.stat}
              </Box>
            )
          }
        >
          {!!occupied && (
            <>
              <ProgressBar
                value={occupant.health}
                minValue={occupant.minHealth}
                maxValue={occupant.maxHealth}
                ranges={{
                  good: [50, Infinity],
                  average: [0, 50],
                  bad: [-Infinity, 0],
                }}
              />
              <Box mt={1} />
              <LabeledList>
                {damageTypes.map((type) => (
                  <LabeledList.Item key={type.type} label={type.label}>
                    <ProgressBar
                      value={occupant[type.type]}
                      minValue={0}
                      maxValue={occupant.maxHealth}
                      color="bad"
                    />
                  </LabeledList.Item>
                ))}
                <LabeledList.Item
                  label="Brain"
                  color={occupant.brainLoss ? 'bad' : 'good'}
                >
                  {occupant.brainLoss ? 'Abnormal' : 'Healthy'}
                </LabeledList.Item>
              </LabeledList>
            </>
          )}
        </Section>
        {bioscanner ? (
          <>
            <Section
              title="Bio-scan dossier"
              minHeight="255px"
              buttons={
                <>
                  <Box inline mr={1}>
                    Next: {nextBioscan}s
                  </Box>
                  <Button
                    icon={open ? 'door-open' : 'door-closed'}
                    content={open ? 'Open' : 'Closed'}
                    onClick={() => act('door')}
                  />
                </>
              }
            >
              <BodyScanPanel bodyScan={bodyScan} organScan={organScan} />
            </Section>
            <Section title="Bio-scan report" minHeight="210px">
              {lastBioscan ? (
                <Box dangerouslySetInnerHTML={{ __html: lastBioscan }} />
              ) : (
                <Box color="label">No report yet.</Box>
              )}
            </Section>
          </>
        ) : (
          <Section
            title="Medicines"
            minHeight="205px"
            buttons={
              <Button
                icon={open ? 'door-open' : 'door-closed'}
                content={open ? 'Open' : 'Closed'}
                onClick={() => act('door')}
              />
            }
          >
            {chems.map((chem) => (
              <Button
                key={chem.name}
                icon="flask"
                content={chem.name}
                disabled={!occupied || !chem.allowed}
                width="140px"
                onClick={() =>
                  act('inject', {
                    chem: chem.id,
                  })
                }
              />
            ))}
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};

const bodyPriority = {
  Head: 1,
  Chest: 2,
  'Left Arm': 3,
  'Right Arm': 4,
  'Left Leg': 5,
  'Right Leg': 6,
};

const getBodyPartColor = (part) => {
  if (part.missing || part.integrity <= 25) {
    return 'bad';
  }
  if (part.integrity <= 60 || part.wounds || part.infection) {
    return 'average';
  }
  return 'good';
};

const BodyScanPanel = (props) => {
  const { bodyScan = [], organScan = [] } = props;
  const sortedBody = [...bodyScan].sort(
    (a, b) => (bodyPriority[a.name] || 99) - (bodyPriority[b.name] || 99),
  );
  return (
    <>
      <Box mb={1} color="label">
        Tissue map
      </Box>
      <Box
        style={{
          display: 'grid',
          gap: '4px',
          gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
        }}
      >
        {sortedBody.map((part) => (
          <Box key={part.zone}>
            <Box mb={0.5}>
              {part.name}
              {!!part.wounds && (
                <Box inline ml={1} color="average">
                  {part.wounds} wound{part.wounds === 1 ? '' : 's'}
                </Box>
              )}
            </Box>
            <ProgressBar
              value={part.integrity / 100}
              color={getBodyPartColor(part)}
            >
              {part.missing ? 'Missing' : `${part.integrity}%`}
            </ProgressBar>
            {!part.missing && (
              <Box color="label" fontSize="10px">
                B {part.blunt || 0} / P {part.pierce || 0} / S{' '}
                {part.slash || 0} | H {part.heat || 0} / C {part.cold || 0} /
                A {part.acid || 0}
              </Box>
            )}
            {!part.missing &&
              !!(
                part.bluntTrauma ||
                part.pierceTrauma ||
                part.slashTrauma ||
                part.heatTrauma ||
                part.coldTrauma ||
                part.acidTrauma ||
                part.pain ||
                part.infection
              ) && (
                <Box color="average" fontSize="10px">
                  Pain {part.pain || 0}, infection {part.infection || 0}%,
                  trauma {part.bluntTrauma || 0}/{part.pierceTrauma || 0}/
                  {part.slashTrauma || 0}/{part.heatTrauma || 0}/
                  {part.coldTrauma || 0}/{part.acidTrauma || 0}
                </Box>
              )}
          </Box>
        ))}
      </Box>
      <Box mt={1} mb={1} color="label">
        Organ function
      </Box>
      <Box
        style={{
          display: 'grid',
          gap: '4px',
          gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
        }}
      >
        {organScan.map((organ) => (
          <Box key={organ.name}>
            <Box mb={0.5}>{organ.name}</Box>
            <ProgressBar
              value={organ.efficiency / 100}
              color={organ.failing || organ.efficiency <= 30 ? 'bad' : 'good'}
            >
              {organ.failing ? 'Failing' : `${organ.efficiency}%`}
            </ProgressBar>
          </Box>
        ))}
      </Box>
    </>
  );
};
