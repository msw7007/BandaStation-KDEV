// CYBERPUNK BUILD - rebuild and delete before release
import { useState } from 'react';
import {
  Box,
  Button,
  Collapsible,
  Input,
  LabeledList,
  Section,
  Stack,
} from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

type Apartment = {
  id: number;
  name: string;
  owner: string;
  apartmentArea: string;
  tileCount: number;
  savedObjects: number;
  savedAt?: string;
  loadedThisRound: BooleanLike;
  canSaveLoad: BooleanLike;
  canRestore: BooleanLike;
  history?: string[];
};

type Data = {
  accountName?: string;
  accountBalance: number;
  hasNeural: BooleanLike;
  apartments: Apartment[];
  apartment?: Apartment;
  testReceiver?: BooleanLike;
  testLoaded?: BooleanLike;
};

export const NtosApartmentTerminal = () => {
  const { act, data } = useBackend<Data>();
  const {
    accountName,
    accountBalance = 0,
    hasNeural,
    apartments = [],
    apartment,
  } = data;

  if (data.testReceiver) {
    return (
      <NtosWindow width={450} height={270}>
        <NtosWindow.Content>
          <Section title="Квартира Б · восстановление">
            <Box mb={1}>
              Загрузит полы и обстановку квартиры А, которые этот персонаж
              сохранил в предыдущем раунде.
            </Box>
            <Button.Confirm
              icon="upload"
              confirmContent="Заменить обстановку квартиры Б"
              disabled={!hasNeural || !!data.testLoaded}
              tooltip={hasNeural ? 'Можно загрузить один раз за раунд.' : 'Подготовь стенд в мастерской на Z1, чтобы получить нейроинтерфейс.'}
              onClick={() => act('restore_test_apartment')}
            >
              {data.testLoaded ? 'Снимок загружен' : 'Восстановить снимок квартиры А'}
            </Button.Confirm>
          </Section>
        </NtosWindow.Content>
      </NtosWindow>
    );
  }

  return (
    <NtosWindow width={700} height={620}>
      <NtosWindow.Content scrollable className="CyberpunkPanel">
        <Section title="Терминал квартиры">
          <LabeledList>
            <LabeledList.Item label="ID account">
              {accountName || 'No ID account'}
            </LabeledList.Item>
            <LabeledList.Item label="Personal balance">
              {formatMoney(accountBalance)} cr
            </LabeledList.Item>
            <LabeledList.Item label="Neural link">
              {hasNeural ? 'online' : 'required for bind/save/load'}
            </LabeledList.Item>
            <LabeledList.Item label="Mode">
              residential area snapshot
            </LabeledList.Item>
          </LabeledList>
        </Section>

        <ApartmentCreation disabled={!hasNeural} />

        <Section title={`Linked apartments (${apartments.length})`}>
          {!apartments.length ? (
            <Box className="CyberpunkPanel__Muted">No linked apartments.</Box>
          ) : (
            <Stack wrap>
              {apartments.map((entry) => (
                <Stack.Item key={entry.id}>
                  <Button
                    icon="home"
                    selected={apartment?.id === entry.id}
                    onClick={() => act('select', { id: entry.id })}
                  >
                    #{entry.id} {entry.name}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          )}
        </Section>

        {!!apartment && <ApartmentPanel apartment={apartment} />}
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const ApartmentCreation = (props: { disabled: boolean }) => {
  const { act } = useBackend<Data>();
  const [name, setName] = useState('');

  return (
    <Collapsible title="Привязать квартиру">
      <Stack vertical>
        <Stack.Item>
          <Input
            fluid
            placeholder="Название квартиры"
            value={name}
            onChange={setName}
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            icon="link"
            disabled={props.disabled}
            onClick={() => act('create', { name })}
          >
            Привязать эту квартиру
          </Button>
        </Stack.Item>
      </Stack>
    </Collapsible>
  );
};

const ApartmentPanel = (props: { apartment: Apartment }) => {
  const { act } = useBackend<Data>();
  const { apartment } = props;

  return (
    <>
      <Section title={`#${apartment.id} ${apartment.name}`}>
        <LabeledList>
          <LabeledList.Item label="Owner">{apartment.owner}</LabeledList.Item>
          <LabeledList.Item label="Area">
            {apartment.apartmentArea} / {apartment.tileCount} tiles
          </LabeledList.Item>
          <LabeledList.Item label="Saved objects">
            {apartment.savedObjects}
          </LabeledList.Item>
          <LabeledList.Item label="Saved">
            {apartment.savedAt || 'never'}
          </LabeledList.Item>
          <LabeledList.Item label="Round load">
            {apartment.loadedThisRound
              ? 'already used'
              : apartment.canRestore
                ? 'available'
                : 'requires a snapshot from an earlier round'}
          </LabeledList.Item>
        </LabeledList>
      </Section>

      <Section title="Сохранение обстановки">
        <Stack>
          <Stack.Item grow>
            <Button
              fluid
              icon="save"
              disabled={!apartment.canSaveLoad}
              onClick={() => act('save', { id: apartment.id })}
            >
              Сохранить снимок квартиры
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button.Confirm
              fluid
              icon="upload"
              color="bad"
              disabled={!apartment.canRestore}
              onClick={() => act('load', { id: apartment.id })}
            >
              Восстановить эту квартиру из снимка
            </Button.Confirm>
          </Stack.Item>
        </Stack>
      </Section>

      <Collapsible title="History">
        {!apartment.history?.length ? (
          <Box className="CyberpunkPanel__Muted">No history.</Box>
        ) : (
          apartment.history.map((line, index) => (
            <Box key={index}>{line}</Box>
          ))
        )}
      </Collapsible>
    </>
  );
};
