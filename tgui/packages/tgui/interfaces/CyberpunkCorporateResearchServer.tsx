import {
  Box,
  Button,
  LabeledList,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Technology = {
  id: string;
  name: string;
  tier: number;
  description: string;
};

type TechnologyKey = {
  sourceCorporationId: string;
  sourceCorporationName: string;
  technologyId: string;
  technologyName: string;
  keyCode: string;
  createdBy: string;
};

type Data = {
  serverName: string;
  manufacturer: string;
  status: string;
  working: boolean;
  corporation?: {
    id: string;
    name: string;
    technologies: Technology[];
  };
  disk?: {
    name: string;
    technologyKeys: TechnologyKey[];
    netData: number;
  };
};

export const CyberpunkCorporateResearchServer = () => {
  const { act, data } = useBackend<Data>();
  const { corporation, disk } = data;
  const technologies = corporation?.technologies || [];
  const technologyKeys = disk?.technologyKeys || [];

  return (
    <Window title="Corporate research archive" width={760} height={620}>
      <Window.Content scrollable className="CyberpunkPanel">
        <Section title={data.serverName || 'Research server'}>
          <LabeledList>
            <LabeledList.Item label="Manufacturer">
              {data.manufacturer || 'independent'}
            </LabeledList.Item>
            <LabeledList.Item label="Status">{data.status}</LabeledList.Item>
            <LabeledList.Item label="Corporation">
              {corporation?.name || 'No corporate archive'}
            </LabeledList.Item>
            <LabeledList.Item label="Data disk">
              {disk ? `${disk.name} (${technologyKeys.length} tech keys)` : 'not inserted'}
            </LabeledList.Item>
          </LabeledList>
        </Section>

        <Section title="Unlocked research nodes">
          {!technologies.length ? (
            <Box className="CyberpunkPanel__Muted">
              No unlocked corporate technologies are stored in this archive.
            </Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Node</Table.Cell>
                <Table.Cell collapsing>Tier</Table.Cell>
                <Table.Cell>Description</Table.Cell>
                <Table.Cell collapsing>Download</Table.Cell>
              </Table.Row>
              {technologies.map((technology) => (
                <Table.Row key={technology.id}>
                  <Table.Cell>
                    <Box className="CyberpunkPanel__Title">
                      {technology.name}
                    </Box>
                    <Box className="CyberpunkPanel__Mono CyberpunkPanel__Small">
                      {technology.id}
                    </Box>
                  </Table.Cell>
                  <Table.Cell>T{technology.tier}</Table.Cell>
                  <Table.Cell>{technology.description}</Table.Cell>
                  <Table.Cell>
                    <Stack>
                      <Stack.Item>
                        <Button
                          icon="brain"
                          onClick={() =>
                            act('download_memory', {
                              technology_id: technology.id,
                            })
                          }
                        >
                          Memory
                        </Button>
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          icon="floppy-disk"
                          disabled={!disk}
                          onClick={() =>
                            act('download_disk', {
                              technology_id: technology.id,
                            })
                          }
                        >
                          Disk
                        </Button>
                      </Stack.Item>
                    </Stack>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>

        <Section
          title="Inserted disk keys"
          buttons={
            disk ? (
              <Button icon="eject" onClick={() => act('eject_disk')}>
                Eject
              </Button>
            ) : undefined
          }
        >
          {!disk ? (
            <Box className="CyberpunkPanel__Muted">
              Insert a CP13 data disk to upload or store technology keys.
            </Box>
          ) : !technologyKeys.length ? (
            <Box className="CyberpunkPanel__Muted">
              Disk contains no technology keys.
            </Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Key</Table.Cell>
                <Table.Cell>Source</Table.Cell>
                <Table.Cell collapsing>Code</Table.Cell>
                <Table.Cell collapsing>Action</Table.Cell>
              </Table.Row>
              {technologyKeys.map((key) => (
                <Table.Row key={key.keyCode}>
                  <Table.Cell>{key.technologyName}</Table.Cell>
                  <Table.Cell>{key.sourceCorporationName}</Table.Cell>
                  <Table.Cell>
                    <Box className="CyberpunkPanel__Mono">
                      {key.keyCode}
                    </Box>
                  </Table.Cell>
                  <Table.Cell>
                    <Button
                      icon="upload"
                      onClick={() =>
                        act('upload_disk_key', {
                          key_code: key.keyCode,
                        })
                      }
                    >
                      Upload
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
