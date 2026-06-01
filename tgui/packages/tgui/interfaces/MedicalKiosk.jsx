import {
  AnimatedNumber,
  Box,
  Button,
  Flex,
  Icon,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend, useSharedState } from '../backend';
import { Window } from '../layouts';

export const MedicalKiosk = (props) => {
  const { act, data } = useBackend();
  const [scanIndex] = useSharedState('scanIndex');
  const { active_status_1, active_status_2, active_status_3, active_status_4 } =
    data;
  return (
    <Window width={660} height={560}>
      <Window.Content scrollable>
        <Flex mb={1}>
          <Flex.Item mr={1}>
            <Section minHeight="100%">
              <MedicalKioskScanButton
                index={1}
                icon="procedures"
                name="General Health Scan"
                description={`
                  Reads back exact values of your general health scan.
                `}
              />
              <MedicalKioskScanButton
                index={2}
                icon="heartbeat"
                name="Symptom Based Checkup"
                description={`
                  Provides information based on various non-obvious symptoms,
                  like blood levels or disease status.
                `}
              />
              <MedicalKioskScanButton
                index={3}
                icon="radiation-alt"
                name="Neurological/Radiological Scan"
                description={`
                  Provides information about brain trauma and radiation.
                `}
              />
              <MedicalKioskScanButton
                index={4}
                icon="mortar-pestle"
                name="Chemical and Psychoactive Scan"
                description={`
                  Provides a list of consumed chemicals, as well as potential
                  side effects.
                `}
              />
            </Section>
          </Flex.Item>
          <Flex.Item grow={1} basis={0}>
            <MedicalKioskInstructions />
          </Flex.Item>
        </Flex>
        {!!active_status_1 && scanIndex === 1 && <MedicalKioskScanResults1 />}
        {!!active_status_2 && scanIndex === 2 && <MedicalKioskScanResults2 />}
        {!!active_status_3 && scanIndex === 3 && <MedicalKioskScanResults3 />}
        {!!active_status_4 && scanIndex === 4 && <MedicalKioskScanResults4 />}
      </Window.Content>
    </Window>
  );
};

const MedicalKioskScanButton = (props) => {
  const { index, name, description, icon } = props;
  const { act, data } = useBackend();
  const [scanIndex, setScanIndex] = useSharedState('scanIndex');
  const paid = data[`active_status_${index}`];
  return (
    <Stack align="baseline">
      <Stack.Item width="16px" textAlign="center">
        <Icon
          name={paid ? 'check' : 'dollar-sign'}
          color={paid ? 'green' : 'grey'}
        />
      </Stack.Item>
      <Stack.Item grow basis="content">
        <Button
          fluid
          icon={icon}
          selected={paid && scanIndex === index}
          tooltip={description}
          tooltipPosition="right"
          content={name}
          onClick={() => {
            if (!paid) {
              act(`beginScan_${index}`);
            }
            setScanIndex(index);
          }}
        />
      </Stack.Item>
    </Stack>
  );
};

const MedicalKioskInstructions = (props) => {
  const { act, data } = useBackend();
  const { kiosk_cost, patient_name } = data;
  return (
    <Section minHeight="100%">
      <Box italic>
        Greetings Valued Employee! Please select a desired automatic health
        check procedure. Diagnosis costs <b>{kiosk_cost} credits.</b>
      </Box>
      <Box mt={1}>
        <Box inline color="label" mr={1}>
          Patient:
        </Box>
        {patient_name}
      </Box>
      <Button
        mt={1}
        tooltip={`
          Resets the current scanning target, cancelling current scans.
        `}
        icon="sync"
        color="average"
        onClick={() => act('clearTarget')}
        content="Reset Scanner"
      />
    </Section>
  );
};

const MedicalKioskScanResults1 = (props) => {
  const { data } = useBackend();
  const {
    body_scan = [],
    patient_health,
    brute_health,
    burn_health,
    suffocation_health,
    toxin_health,
    chemical_health,
    oxygenation,
    blood_pressure,
    pain_total,
    infection_total,
    blunt_damage,
    pierce_damage,
    slash_damage,
    heat_damage,
    cold_damage,
    acid_damage,
    organ_scan = [],
  } = data;
  return (
    <Section title="Patient Health">
      <Flex>
        <Flex.Item grow basis={0} mr={1}>
          <LabeledList>
            <LabeledList.Item label="Total Health">
              <ProgressBar value={patient_health / 100}>
                <AnimatedNumber value={patient_health} />%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Divider />
            <LabeledList.Item label="Brute Damage">
              <ProgressBar value={brute_health / 100} color="bad">
                <AnimatedNumber value={brute_health} />
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Burn Damage">
              <ProgressBar value={burn_health / 100} color="bad">
                <AnimatedNumber value={burn_health} />
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Oxygen Damage">
              <ProgressBar value={suffocation_health / 100} color="bad">
                <AnimatedNumber value={suffocation_health} />
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Toxin Damage">
              <ProgressBar value={toxin_health / 100} color="bad">
                <AnimatedNumber value={toxin_health} />
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Chemical Damage">
              <ProgressBar value={chemical_health / 100} color="bad">
                <AnimatedNumber value={chemical_health} />
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Divider />
            <LabeledList.Item label="Physical Damage">
              BLUNT <AnimatedNumber value={blunt_damage} />, PIERCE{' '}
              <AnimatedNumber value={pierce_damage} />, SLASH{' '}
              <AnimatedNumber value={slash_damage} />
            </LabeledList.Item>
            <LabeledList.Item label="Thermal Damage">
              HEAT <AnimatedNumber value={heat_damage} />, COLD{' '}
              <AnimatedNumber value={cold_damage} />, ACID{' '}
              <AnimatedNumber value={acid_damage} />
            </LabeledList.Item>
            <LabeledList.Item label="Oxygenation">
              <ProgressBar value={oxygenation / 100} color="good">
                <AnimatedNumber value={oxygenation} />%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Blood Pressure">
              <AnimatedNumber value={blood_pressure} />%
            </LabeledList.Item>
            <LabeledList.Item label="Pain / Infection">
              Pain <AnimatedNumber value={pain_total} />, infection{' '}
              <AnimatedNumber value={infection_total} />%
            </LabeledList.Item>
          </LabeledList>
        </Flex.Item>
        <Flex.Item width="270px">
          <MedicalBodyMap bodyScan={body_scan} organScan={organ_scan} />
        </Flex.Item>
      </Flex>
    </Section>
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

const MedicalBodyMap = (props) => {
  const { bodyScan = [], organScan = [] } = props;
  const sortedBody = [...bodyScan].sort(
    (a, b) => (bodyPriority[a.name] || 99) - (bodyPriority[b.name] || 99),
  );
  return (
    <>
      <Box mb={1} color="label">
        Tissue map
      </Box>
      {sortedBody.map((part) => (
        <Box key={part.zone} mb={0.5}>
          <Box>
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
        </Box>
      ))}
      <Box mt={1} mb={1} color="label">
        Organ function
      </Box>
      {organScan.slice(0, 6).map((organ) => (
        <Box key={organ.name} mb={0.5}>
          <Box>{organ.name}</Box>
          <ProgressBar
            value={organ.efficiency / 100}
            color={organ.failing || organ.efficiency <= 30 ? 'bad' : 'good'}
          >
            {organ.failing ? 'Failing' : `${organ.efficiency}%`}
          </ProgressBar>
        </Box>
      ))}
    </>
  );
};

const MedicalKioskScanResults2 = (props) => {
  const { data } = useBackend();
  const {
    patient_status,
    patient_illness,
    illness_info,
    bleed_status,
    blood_levels,
    blood_name,
    blood_status,
  } = data;
  return (
    <Section title="Symptom Based Checkup">
      <LabeledList>
        <LabeledList.Item label="Patient Status" color="good">
          {patient_status}
        </LabeledList.Item>
        <LabeledList.Divider />
        <LabeledList.Item label="Disease Status">
          {patient_illness}
        </LabeledList.Item>
        <LabeledList.Item label="Disease information">
          {illness_info}
        </LabeledList.Item>
        <LabeledList.Divider />
        <LabeledList.Item label={`${blood_name} Levels`}>
          <ProgressBar value={blood_levels / 100} color="bad">
            <AnimatedNumber value={blood_levels} />
          </ProgressBar>
          <Box mt={1} color="label">
            {bleed_status}
          </Box>
        </LabeledList.Item>
        <LabeledList.Item label={`${blood_name} Information`}>
          {blood_status}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const MedicalKioskScanResults3 = (props) => {
  const { data } = useBackend();
  const { brain_damage, brain_health, trauma_status } = data;
  return (
    <Section title="Patient Neurological Health">
      <LabeledList>
        <LabeledList.Item label="Brain Damage">
          <ProgressBar value={brain_damage / 100} color="good">
            <AnimatedNumber value={brain_damage} />
          </ProgressBar>
        </LabeledList.Item>
        <LabeledList.Item label="Brain Status" color="health-0">
          {brain_health}
        </LabeledList.Item>
        <LabeledList.Item label="Brain Trauma Status">
          {trauma_status}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const MedicalKioskScanResults4 = (props) => {
  const { data } = useBackend();
  const {
    chemical_list = [],
    overdose_list = [],
    addict_list = [],
    hallucinating_status,
    blood_alcohol,
  } = data;
  return (
    <Section title="Chemical and Psychoactive Analysis">
      <LabeledList>
        <LabeledList.Item label="Chemical Contents">
          {chemical_list.length === 0 && (
            <Box color="average">No reagents detected.</Box>
          )}
          {chemical_list.map((chem) => (
            <Box key={chem.id} color="good">
              {chem.volume} units of {chem.name}
            </Box>
          ))}
        </LabeledList.Item>
        <LabeledList.Item label="Overdose Status" color="bad">
          {overdose_list.length === 0 && (
            <Box color="good">Patient is not overdosing.</Box>
          )}
          {overdose_list.map((chem) => (
            <Box key={chem.id}>Overdosing on {chem.name}</Box>
          ))}
        </LabeledList.Item>
        <LabeledList.Item label="Addiction Status" color="bad">
          {addict_list.length === 0 && (
            <Box color="good">Patient has no addictions.</Box>
          )}
          {addict_list.map((chem) => (
            <Box key={chem.id}>Addicted to {chem.name}</Box>
          ))}
        </LabeledList.Item>
        <LabeledList.Item label="Psychoactive Status">
          {hallucinating_status}
        </LabeledList.Item>
        <LabeledList.Item label="Blood Alcohol Content">
          <ProgressBar
            value={blood_alcohol}
            minValue={0}
            maxValue={0.3}
            ranges={{
              blue: [-Infinity, 0.23],
              bad: [0.23, Infinity],
            }}
          >
            <AnimatedNumber value={blood_alcohol} />
          </ProgressBar>
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};
