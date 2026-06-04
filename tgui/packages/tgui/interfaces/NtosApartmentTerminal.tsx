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
  history?: string[];
};

type Data = {
  accountName?: string;
  accountBalance: number;
  hasNeural: BooleanLike;
  apartments: Apartment[];
  apartment?: Apartment;
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

  return (
    <NtosWindow width={700} height={620}>
      <NtosWindow.Content scrollable className="CyberpunkPanel">
        <Section title="Apartment terminal">
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
    <Collapsible title="Bind apartment">
      <Stack vertical>
        <Stack.Item>
          <Input
            fluid
            placeholder="Apartment name"
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
            Bind current area to neural interface
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
            {apartment.loadedThisRound ? 'already used' : 'available'}
          </LabeledList.Item>
        </LabeledList>
      </Section>

      <Section title="Persistence">
        <Stack>
          <Stack.Item grow>
            <Button
              fluid
              icon="save"
              disabled={!apartment.canSaveLoad}
              onClick={() => act('save', { id: apartment.id })}
            >
              Save apartment snapshot
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button.Confirm
              fluid
              icon="upload"
              color="bad"
              disabled={
                !apartment.canSaveLoad ||
                apartment.loadedThisRound ||
                apartment.savedObjects <= 0
              }
              onClick={() => act('load', { id: apartment.id })}
            >
              Overwrite area from snapshot
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
