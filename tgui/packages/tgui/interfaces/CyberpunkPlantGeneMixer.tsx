import { Button, LabeledList, NoticeBox, Section, Stack } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type MixerData = {
  seed: string | null;
  potential: number | null;
  remaining: number;
  duration: number;
  edictActive: BooleanLike;
  powered: BooleanLike;
  mixing: BooleanLike;
  genes: {
    id: string;
    name: string;
    description: string;
    target: string;
    cost: number;
    compatible: BooleanLike;
  }[];
};

export const CyberpunkPlantGeneMixer = () => {
  const { act, data } = useBackend<MixerData>();
  const { seed, potential, remaining, duration, edictActive, powered, mixing, genes } = data;

  return (
    <Window width={480} height={440}>
      <Window.Content scrollable>
        {!powered && <NoticeBox danger>Нет питания.</NoticeBox>}
        {!!mixing && <NoticeBox>Идёт перенос признака. Оставайся у смешивателя.</NoticeBox>}
        <Section
          title="Семена-получатель"
          buttons={
            <Button
              icon="eject"
              disabled={!seed || !powered || !!mixing}
              onClick={() => act('eject')}
            >
              Извлечь семена
            </Button>
          }
        >
          {seed ? (
            <LabeledList>
              <LabeledList.Item label="Загружено">{seed}</LabeledList.Item>
              <LabeledList.Item label="Шанс закрепления">{potential}%</LabeledList.Item>
              <LabeledList.Item label="Доступно очков">{remaining}</LabeledList.Item>
              <LabeledList.Item label="Время переноса">{duration} с</LabeledList.Item>
              <LabeledList.Item label="Генная комбинаторика">
                {edictActive ? 'действует' : 'не действует'}
              </LabeledList.Item>
            </LabeledList>
          ) : (
            'Возьми пачку семян и примени её к смешивателю.'
          )}
        </Section>
        <Section title="Признаки донора">
          {genes.length === 0 ? (
            'Просканируй растение или семена анализатором, затем примени анализатор к смешивателю.'
          ) : (
            <Stack vertical>
              {genes.map((gene) => (
                <Stack.Item key={gene.id}>
                  <Button
                    fluid
                    icon="dna"
                    tooltip={
                      gene.compatible || !seed
                        ? gene.description
                        : 'Признак уже есть, несовместим с получателем или превышает доступные очки.'
                    }
                    disabled={!powered || !!mixing || !gene.compatible}
                    onClick={() => act('mix', { gene: gene.id })}
                  >
                    {gene.name} · {gene.target} · {gene.cost} очк.
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
