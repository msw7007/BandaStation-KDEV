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
                name="Общее сканирование"
                description={`
                  Показывает точные показатели общего состояния пациента.
                `}
              />
              <MedicalKioskScanButton
                index={2}
                icon="heartbeat"
                name="Проверка симптомов"
                description={`
                  Показывает скрытые симптомы: кровь, болезни и сопутствующие
                  риски.
                `}
              />
              <MedicalKioskScanButton
                index={3}
                icon="radiation-alt"
                name="Нейро-/радиоскан"
                description={`
                  Показывает травмы мозга и радиологические отклонения.
                `}
              />
              <MedicalKioskScanButton
                index={4}
                icon="mortar-pestle"
                name="Химический скан"
                description={`
                  Показывает реагенты, передозировки, зависимости и
                  психоактивные эффекты.
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
        Выберите автоматическую диагностическую процедуру. Диагностика стоит{' '}
        <b>{kiosk_cost} кредитов.</b>
      </Box>
      <Box mt={1}>
        <Box inline color="label" mr={1}>
          Пациент:
        </Box>
        {patient_name}
      </Box>
      <Button
        mt={1}
        tooltip={`
          Сбрасывает текущую цель сканирования и отменяет активные сканы.
        `}
        icon="sync"
        color="average"
        onClick={() => act('clearTarget')}
        content="Сбросить сканер"
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
    <Section title="Состояние пациента">
      <Flex>
        <Flex.Item grow basis={0} mr={1}>
          <LabeledList>
            <LabeledList.Item label="Общее здоровье">
              <ProgressBar value={patient_health / 100}>
                <AnimatedNumber value={patient_health} />%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Divider />
            <LabeledList.Item label="Физический урон">
              <ProgressBar value={brute_health / 100} color="bad">
                <AnimatedNumber value={brute_health} />
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Ожоги">
              <ProgressBar value={burn_health / 100} color="bad">
                <AnimatedNumber value={burn_health} />
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Кислородный урон">
              <ProgressBar value={suffocation_health / 100} color="bad">
                <AnimatedNumber value={suffocation_health} />
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Токсины">
              <ProgressBar value={toxin_health / 100} color="bad">
                <AnimatedNumber value={toxin_health} />
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Divider />
            <LabeledList.Item label="Типы физического урона">
              BLUNT <AnimatedNumber value={blunt_damage} />, PIERCE{' '}
              <AnimatedNumber value={pierce_damage} />, SLASH{' '}
              <AnimatedNumber value={slash_damage} />
            </LabeledList.Item>
            <LabeledList.Item label="Типы терм./хим. урона">
              HEAT <AnimatedNumber value={heat_damage} />, COLD{' '}
              <AnimatedNumber value={cold_damage} />, ACID{' '}
              <AnimatedNumber value={acid_damage} />
            </LabeledList.Item>
            <LabeledList.Item label="Кислородонасыщение">
              <ProgressBar value={oxygenation / 100} color="good">
                <AnimatedNumber value={oxygenation} />%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Кровяное давление">
              <AnimatedNumber value={blood_pressure} />%
            </LabeledList.Item>
            <LabeledList.Item label="Боль / инфекция">
              Боль <AnimatedNumber value={pain_total} />, инфекция{' '}
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
        Карта тканей
      </Box>
      {sortedBody.map((part) => (
        <Box key={part.zone} mb={0.5}>
          <Box>
            {part.name}
            {!!part.wounds && (
              <Box inline ml={1} color="average">
                ран: {part.wounds}
              </Box>
            )}
          </Box>
          <ProgressBar
            value={part.integrity / 100}
            color={getBodyPartColor(part)}
          >
            {part.missing ? 'Отсутствует' : `${part.integrity}%`}
          </ProgressBar>
          {!part.missing && (
            <Box color="label" fontSize="10px">
              B {part.blunt || 0} / P {part.pierce || 0} / S{' '}
              {part.slash || 0} | H {part.heat || 0} / C {part.cold || 0} / A{' '}
              {part.acid || 0}
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
                Боль {part.pain || 0}, инфекция {part.infection || 0}%,
                стадия {part.infectionStage || 0}, травмы {part.bluntTrauma || 0}/{part.pierceTrauma || 0}/
                {part.slashTrauma || 0}/{part.heatTrauma || 0}/
                {part.coldTrauma || 0}/{part.acidTrauma || 0}
              </Box>
            )}
        </Box>
      ))}
      <Box mt={1} mb={1} color="label">
        Функция органов
      </Box>
      {organScan.slice(0, 6).map((organ) => (
        <Box key={organ.name} mb={0.5}>
          <Box>{organ.name}</Box>
          <ProgressBar
            value={organ.efficiency / 100}
            color={organ.failing || organ.efficiency <= 30 ? 'bad' : 'good'}
          >
            {organ.failing ? 'Отказ' : `${organ.efficiency}%`}
          </ProgressBar>
          {!!organ.condition && (
            <Box color="average" fontSize="10px">
              {organ.condition}
            </Box>
          )}
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
    <Section title="Проверка симптомов">
      <LabeledList>
        <LabeledList.Item label="Состояние пациента" color="good">
          {patient_status}
        </LabeledList.Item>
        <LabeledList.Divider />
        <LabeledList.Item label="Болезни">
          {patient_illness}
        </LabeledList.Item>
        <LabeledList.Item label="Информация о болезни">
          {illness_info}
        </LabeledList.Item>
        <LabeledList.Divider />
        <LabeledList.Item label={`Уровень ${blood_name}`}>
          <ProgressBar value={blood_levels / 100} color="bad">
            <AnimatedNumber value={blood_levels} />
          </ProgressBar>
          <Box mt={1} color="label">
            {bleed_status}
          </Box>
        </LabeledList.Item>
        <LabeledList.Item label={`Информация: ${blood_name}`}>
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
    <Section title="Неврологическое состояние">
      <LabeledList>
        <LabeledList.Item label="Урон мозгу">
          <ProgressBar value={brain_damage / 100} color="good">
            <AnimatedNumber value={brain_damage} />
          </ProgressBar>
        </LabeledList.Item>
        <LabeledList.Item label="Состояние мозга" color="health-0">
          {brain_health}
        </LabeledList.Item>
        <LabeledList.Item label="Травмы мозга">
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
    <Section title="Химический и психоактивный анализ">
      <LabeledList>
        <LabeledList.Item label="Реагенты">
          {chemical_list.length === 0 && (
            <Box color="average">Реагенты не обнаружены.</Box>
          )}
          {chemical_list.map((chem) => (
            <Box key={chem.id} color="good">
              {chem.volume} ед. {chem.name}
            </Box>
          ))}
        </LabeledList.Item>
        <LabeledList.Item label="Передозировка" color="bad">
          {overdose_list.length === 0 && (
            <Box color="good">Передозировка не обнаружена.</Box>
          )}
          {overdose_list.map((chem) => (
            <Box key={chem.id}>Передозировка: {chem.name}</Box>
          ))}
        </LabeledList.Item>
        <LabeledList.Item label="Зависимости" color="bad">
          {addict_list.length === 0 && (
            <Box color="good">Зависимости не обнаружены.</Box>
          )}
          {addict_list.map((chem) => (
            <Box key={chem.id}>Зависимость: {chem.name}</Box>
          ))}
        </LabeledList.Item>
        <LabeledList.Item label="Психоактивный статус">
          {hallucinating_status}
        </LabeledList.Item>
        <LabeledList.Item label="Алкоголь в крови">
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
