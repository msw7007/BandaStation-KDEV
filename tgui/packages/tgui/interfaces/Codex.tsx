import { useState } from 'react';
import { Box, Button, Section, Stack, Tabs } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { MarkdownRenderer } from './MarkdownViewer';

type CodexSection = {
  title: string;
  body: string;
};

type CodexItem = {
  id: string;
  title: string;
  sections: CodexSection[];
};

type CodexBlock = {
  id: string;
  title: string;
  items: CodexItem[];
};

type CodexData = {
  blocks: CodexBlock[];
};

export const Codex = () => {
  const { data } = useBackend<CodexData>();
  const { blocks } = data;
  const [selectedBlockId, setSelectedBlockId] = useState(blocks[0]?.id);
  const selectedBlock = blocks.find((block) => block.id === selectedBlockId);
  const [selectedItemId, setSelectedItemId] = useState(
    selectedBlock?.items[0]?.id,
  );
  const selectedItem =
    selectedBlock?.items.find((item) => item.id === selectedItemId) ||
    selectedBlock?.items[0];
  const [selectedSectionIndex, setSelectedSectionIndex] = useState(0);
  const selectedSection =
    selectedItem?.sections[selectedSectionIndex] || selectedItem?.sections[0];

  const selectBlock = (block: CodexBlock) => {
    setSelectedBlockId(block.id);
    setSelectedItemId(block.items[0]?.id);
    setSelectedSectionIndex(0);
  };

  const selectItem = (item: CodexItem) => {
    setSelectedItemId(item.id);
    setSelectedSectionIndex(0);
  };

  return (
    <Window title="КОДЕКС" width={760} height={600}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Tabs>
              {blocks.map((block) => (
                <Tabs.Tab
                  key={block.id}
                  selected={block.id === selectedBlock?.id}
                  onClick={() => selectBlock(block)}
                >
                  {block.title}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item width="180px">
                <Section fill scrollable>
                  <Stack vertical>
                    {selectedBlock?.items.map((item) => (
                      <Stack.Item key={item.id}>
                        <Button
                          fluid
                          selected={item.id === selectedItem?.id}
                          onClick={() => selectItem(item)}
                        >
                          {item.title}
                        </Button>
                      </Stack.Item>
                    ))}
                  </Stack>
                </Section>
              </Stack.Item>
              <Stack.Item grow>
                <Section
                  fill
                  scrollable
                  title={selectedItem?.title || 'Раздел не выбран'}
                >
                  {selectedSection ? (
                    <>
                      <Box bold fontSize={1.25} mb={1}>
                        {selectedSection.title}
                      </Box>
                      <MarkdownRenderer content={selectedSection.body} />
                    </>
                  ) : (
                    <Box color="label">Нет данных.</Box>
                  )}
                </Section>
              </Stack.Item>
              <Stack.Item width="165px">
                <Section title="Навигация" fill scrollable>
                  <Stack vertical>
                    {selectedItem?.sections.map((section, index) => (
                      <Stack.Item key={section.title}>
                        <Button
                          fluid
                          selected={index === selectedSectionIndex}
                          onClick={() => setSelectedSectionIndex(index)}
                        >
                          {section.title}
                        </Button>
                      </Stack.Item>
                    ))}
                  </Stack>
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
