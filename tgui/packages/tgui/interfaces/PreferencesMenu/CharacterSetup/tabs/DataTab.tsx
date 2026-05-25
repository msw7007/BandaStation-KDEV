import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Button, ImageButton, Modal } from 'tgui-core/components';

import { CharacterPreview } from '../../../common/CharacterPreview';
import type { PreferencesMenuData, ServerData, Species } from '../../types';
import { useServerPrefs } from '../../useServerPrefs';
import {
  CharacterPaperdollHub,
  type PaperdollSlot,
} from '../components/CharacterPaperdollHub';
import {
  CyberButton,
  CyberColorButton,
  CyberInput,
  CyberSelect,
  CyberSlider,
  CyberTextarea,
} from '../components/CyberInput';
import { CyberPanel, CyberSectionHeader } from '../components/CyberPanel';
import {
  getChoiceOptions,
  getPreferenceValue,
  setPreference,
} from '../helpers';

type NumericPreferenceData = {
  minimum?: number;
  maximum?: number;
  step?: number;
};

type IconChoiceData = {
  choices?: string[];
  display_names?: Record<string, string>;
  icons?: Record<string, string>;
};

type AppearanceControl = {
  key: string;
  label: string;
  kind: 'choice' | 'color' | 'icons';
  icon?: string;
};

type AppearanceCategory = PaperdollSlot & {
  controls: AppearanceControl[];
};

const bodyControls: AppearanceControl[] = [
  { key: 'skin_tone', label: 'Тон кожи', kind: 'choice', icon: 'palette' },
  { key: 'feature_mcolor', label: 'Цвет шерсти / тела', kind: 'color' },
  { key: 'blindfold_color', label: 'Цвет повязки', kind: 'color' },
  { key: 'paint_color', label: 'Цвет краски', kind: 'color' },
  { key: 'feature_cat_ears', label: 'Кошачьи уши', kind: 'icons' },
  { key: 'feature_cat_tail', label: 'Кошачий хвост', kind: 'icons' },
  { key: 'feature_lizard_horns', label: 'Рога', kind: 'icons' },
  { key: 'feature_lizard_frills', label: 'Жабры / гребни', kind: 'icons' },
  { key: 'feature_lizard_snout', label: 'Морда', kind: 'icons' },
  { key: 'feature_lizard_spines', label: 'Шипы', kind: 'icons' },
  { key: 'feature_lizard_tail', label: 'Хвост', kind: 'icons' },
  { key: 'feature_lizard_legs', label: 'Форма ног', kind: 'icons' },
  { key: 'feature_vulpkanin_tail', label: 'Вульпканин: хвост', kind: 'icons' },
  { key: 'feature_tajaran_tail', label: 'Таяран: хвост', kind: 'icons' },
];

const hairControls: AppearanceControl[] = [
  { key: 'hairstyle_name', label: 'Прическа', kind: 'icons' },
  { key: 'hair_color', label: 'Цвет волос', kind: 'color', icon: 'palette' },
  { key: 'hair_gradient', label: 'Градиент волос', kind: 'choice' },
  {
    key: 'hair_gradient_color',
    label: 'Цвет градиента волос',
    kind: 'color',
    icon: 'palette',
  },
  { key: 'facial_style_name', label: 'Волосы на лице', kind: 'icons' },
  {
    key: 'facial_hair_color',
    label: 'Цвет волос на лице',
    kind: 'color',
    icon: 'palette',
  },
  {
    key: 'facial_hair_gradient',
    label: 'Градиент волос на лице',
    kind: 'choice',
  },
  {
    key: 'facial_hair_gradient_color',
    label: 'Цвет градиента лица',
    kind: 'color',
    icon: 'palette',
  },
  { key: 'feature_vulpkanin_facial_hair', label: 'Вульпканин: лицевой мех', kind: 'icons' },
  {
    key: 'vulpkanin_facial_hair_color',
    label: 'Цвет лицевого меха вульпканина',
    kind: 'color',
  },
  { key: 'feature_tajaran_facial_hair', label: 'Таяран: лицевой мех', kind: 'icons' },
  {
    key: 'tajaran_facial_hair_color',
    label: 'Цвет лицевого меха таярана',
    kind: 'color',
  },
];

const eyeControls: AppearanceControl[] = [
  { key: 'scarred_eye', label: 'Поврежденный глаз', kind: 'choice' },
  { key: 'eye_color', label: 'Цвет глаз', kind: 'color', icon: 'palette' },
  { key: 'heterochromatic', label: 'Гетерохромия', kind: 'color', icon: 'palette' },
];

const markControls: AppearanceControl[] = [
  { key: 'feature_lizard_body_markings', label: 'Узор тела ящера', kind: 'icons' },
  { key: 'feature_moth_markings', label: 'Марки мотылька', kind: 'icons' },
  { key: 'feature_vulpkanin_head_markings', label: 'Вульпканин: голова', kind: 'icons' },
  { key: 'feature_vulpkanin_limb_markings', label: 'Вульпканин: конечности', kind: 'icons' },
  { key: 'feature_vulpkanin_chest_markings', label: 'Вульпканин: туловище', kind: 'icons' },
  { key: 'feature_vulpkanin_tail_markings', label: 'Вульпканин: хвост', kind: 'icons' },
  {
    key: 'vulpkanin_head_markings_color',
    label: 'Цвет марок головы вульпканина',
    kind: 'color',
  },
  {
    key: 'vulpkanin_body_markings_color',
    label: 'Цвет марок тела вульпканина',
    kind: 'color',
  },
  {
    key: 'vulpkanin_tail_markings_color',
    label: 'Цвет марок хвоста вульпканина',
    kind: 'color',
  },
  { key: 'feature_tajaran_head_markings', label: 'Таяран: голова', kind: 'icons' },
  { key: 'feature_tajaran_limb_markings', label: 'Таяран: конечности', kind: 'icons' },
  { key: 'feature_tajaran_chest_markings', label: 'Таяран: туловище', kind: 'icons' },
  { key: 'feature_tajaran_tail_markings', label: 'Таяран: хвост', kind: 'icons' },
  {
    key: 'tajaran_head_markings_color',
    label: 'Цвет марок головы таярана',
    kind: 'color',
  },
  {
    key: 'tajaran_body_markings_color',
    label: 'Цвет марок тела таярана',
    kind: 'color',
  },
  {
    key: 'tajaran_tail_markings_color',
    label: 'Цвет марок хвоста таярана',
    kind: 'color',
  },
];

const appearanceCategories: AppearanceCategory[] = [
  {
    id: 'body',
    label: 'Тело',
    icon: 'dna',
    controls: bodyControls,
  },
  {
    id: 'sensory',
    label: 'Сенсорика',
    icon: 'eye',
    controls: eyeControls,
  },
  {
    id: 'hair',
    label: 'Волосы',
    icon: 'user',
    controls: hairControls,
  },
  {
    id: 'marks',
    label: 'Татуировки / марки',
    icon: 'stamp',
    controls: markControls,
  },
  {
    id: 'undershirt',
    label: 'Верхнее белье',
    icon: 'shirt',
    controls: [
      { key: 'undershirt', label: 'Верхнее белье', kind: 'icons' },
    ],
  },
  {
    id: 'underwear',
    label: 'Нижнее белье',
    icon: 'person',
    controls: [
      { key: 'underwear', label: 'Нижнее белье', kind: 'icons' },
      {
        key: 'underwear_color',
        label: 'Цвет нижнего белья',
        kind: 'color',
      },
    ],
  },
  {
    id: 'socks',
    label: 'Носки',
    icon: 'socks',
    controls: [{ key: 'socks', label: 'Носки', kind: 'icons' }],
  },
  {
    id: 'genitals',
    label: 'Гениталии',
    icon: 'venus-mars',
    controls: [],
  },
];

function value(data: PreferencesMenuData, key: string) {
  return getPreferenceValue(data, key);
}

function numberValue(data: PreferencesMenuData, key: string, fallback: number) {
  const current = Number(value(data, key));
  return Number.isFinite(current) ? current : fallback;
}

function numericData(
  serverData: ServerData | undefined,
  key: string,
  fallback: Required<NumericPreferenceData>,
): Required<NumericPreferenceData> {
  const current = serverData?.[key] as NumericPreferenceData | undefined;
  return {
    minimum: current?.minimum ?? fallback.minimum,
    maximum: current?.maximum ?? fallback.maximum,
    step: current?.step ?? fallback.step,
  };
}

function getIconChoiceData(
  serverData: ServerData | undefined,
  key: string,
): IconChoiceData | undefined {
  return serverData?.[key] as IconChoiceData | undefined;
}

function isControlAvailable(
  data: PreferencesMenuData,
  serverData: ServerData | undefined,
  control: AppearanceControl,
) {
  if (value(data, control.key) === undefined) {
    return false;
  }

  if (control.kind === 'choice' || control.kind === 'icons') {
    return getChoiceOptions(serverData, control.key).length > 0;
  }

  return true;
}

function renderIconChoiceGrid(
  data: PreferencesMenuData,
  serverData: ServerData | undefined,
  act: Parameters<typeof setPreference>[0],
  preference: string,
  label: string,
) {
  const catalog = getIconChoiceData(serverData, preference);
  const icons = catalog?.icons;
  const currentValue = String(value(data, preference) ?? '');

  if (!icons || !Object.keys(icons).length) {
    return renderAppearanceControl(data, serverData, act, {
      key: preference,
      label,
      kind: 'choice',
    });
  }

  const entries = catalog?.choices?.length
    ? catalog.choices.map((choice) => [choice, icons[choice]] as const)
    : (Object.entries(icons) as Array<[string, string]>);

  return (
    <div className="CharacterSetup__iconChoice" key={preference}>
      <b>{label}</b>
      <div className="CharacterSetup__iconChoiceGrid">
        {entries
          .filter(([_choice, icon]) => !!icon)
          .map(([choice, icon]) => (
            <ImageButton
              key={choice}
              asset={['preferences32x32', icon]}
              imageSize={32}
              selected={choice === currentValue}
              tooltip={catalog?.display_names?.[choice] || choice}
              tooltipPosition="right"
              onClick={() => setPreference(act, preference, choice)}
            />
          ))}
      </div>
    </div>
  );
}

function renderAppearanceControl(
  data: PreferencesMenuData,
  serverData: ServerData | undefined,
  act: Parameters<typeof setPreference>[0],
  control: AppearanceControl,
) {
  if (!isControlAvailable(data, serverData, control)) {
    return null;
  }

  if (control.kind === 'icons') {
    return renderIconChoiceGrid(data, serverData, act, control.key, control.label);
  }

  if (control.kind === 'color') {
    return (
      <CyberColorButton
        key={control.key}
        buttonLabel="Выбрать цвет"
        color={String(value(data, control.key) ?? '')}
        icon={control.icon || 'palette'}
        label={control.label}
        onClick={() =>
          act('set_color_preference', {
            preference: control.key,
          })
        }
      />
    );
  }

  return (
    <CyberSelect
      key={control.key}
      icon={control.icon}
      label={control.label}
      value={String(value(data, control.key) ?? '')}
      options={getChoiceOptions(serverData, control.key)}
      onSelected={(newValue) => setPreference(act, control.key, newValue)}
    />
  );
}

function SpeciesPickerModal(props: {
  currentSpeciesKey: string;
  species: Record<string, Species>;
  previewId: string;
  onClose: () => void;
  onSelect: (species: string) => void;
}) {
  const speciesEntries = Object.entries(props.species);
  const currentSpecies = props.species[props.currentSpeciesKey];

  return (
    <Modal className="CharacterSetup__speciesModal" width="760px">
      <div className="CharacterSetup__speciesModalHeader">
        <b>Выбор вида / типа тела</b>
        <Button icon="xmark" onClick={props.onClose} />
      </div>
      <div className="CharacterSetup__speciesModalBody">
        <div className="CharacterSetup__speciesList">
          {speciesEntries.map(([speciesKey, species]) => (
            <button
              key={speciesKey}
              className={
                speciesKey === props.currentSpeciesKey
                  ? 'CharacterSetup__speciesOption selected'
                  : 'CharacterSetup__speciesOption'
              }
              onClick={() => props.onSelect(speciesKey)}
            >
              <b>{species.name}</b>
              <span>{species.desc}</span>
            </button>
          ))}
        </div>
        <div className="CharacterSetup__speciesDetails">
          <CharacterPreview height="180px" id={props.previewId} />
          <h3>{currentSpecies?.name || props.currentSpeciesKey}</h3>
          <p>{currentSpecies?.desc || 'Описание вида недоступно.'}</p>
          {!!currentSpecies?.enabled_features?.length && (
            <div>
              <b>Доступные особенности</b>
              <span>{currentSpecies.enabled_features.join(', ')}</span>
            </div>
          )}
          {!!currentSpecies?.lore?.length && (
            <div>
              <b>Описание</b>
              <span>{currentSpecies.lore[0]}</span>
            </div>
          )}
        </div>
      </div>
    </Modal>
  );
}

export function DataTab() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const serverData = useServerPrefs();
  const [selectedCategory, setSelectedCategory] = useState('body');
  const [speciesModalOpen, setSpeciesModalOpen] = useState(false);

  const nameKey = data.name_to_use;
  const currentName =
    data.character_preferences.names[nameKey] ||
    data.character_profiles[data.active_slot - 1] ||
    '';
  const ttsSeeds = serverData?.text_to_speech?.seeds || [];
  const currentSpeciesKey = String(data.character_preferences.misc.species ?? '');
  const currentSpeciesName =
    serverData?.species?.[currentSpeciesKey]?.name || currentSpeciesKey || 'Не выбран';
  const selectedAppearanceCategory =
    appearanceCategories.find((category) => category.id === selectedCategory) ||
    appearanceCategories[0];
  const descriptorKeys = [
    'appearance_descriptor_1',
    'appearance_descriptor_2',
    'appearance_descriptor_3',
    'appearance_descriptor_4',
  ];
  const selectedDescriptorCount = descriptorKeys.filter((descriptorKey) =>
    Boolean(value(data, descriptorKey)),
  ).length;
  const ageConfig = numericData(serverData, 'age', {
    minimum: 18,
    maximum: 99,
    step: 1,
  });
  const spriteSizeConfig = numericData(serverData, 'sprite_size', {
    minimum: 0.85,
    maximum: 1.15,
    step: 0.01,
  });
  const spriteHeightConfig = numericData(serverData, 'sprite_height', {
    minimum: 0.9,
    maximum: 1.1,
    step: 0.01,
  });
  const spriteWidthConfig = numericData(serverData, 'sprite_width', {
    minimum: 0.9,
    maximum: 1.1,
    step: 0.01,
  });

  const renderBodyPanel = () => (
    <>
      <CyberSectionHeader>Вид и форма тела</CyberSectionHeader>
      <div className="CharacterSetup__speciesSelect">
        <span>Текущий вид: {currentSpeciesName}</span>
        <CyberButton icon="dna" onClick={() => setSpeciesModalOpen(true)}>
          Выбрать вид / тип тела
        </CyberButton>
      </div>
      <CyberSelect
        icon="person"
        label="Форма тела / телосложение"
        value={String(value(data, 'body_shape') ?? '')}
        options={getChoiceOptions(serverData, 'body_shape')}
        onSelected={(newValue) => setPreference(act, 'body_shape', newValue)}
      />
      <CyberSectionHeader>Кожа и особые части</CyberSectionHeader>
      {renderControls(bodyControls)}
    </>
  );

  const renderVoicePanel = () => (
    <>
      <CyberSectionHeader>Голос</CyberSectionHeader>
      <CyberSelect
        disabled={!data.tts_enabled}
        icon="volume-high"
        label="Голос ТТС"
        value={data.tts_seed}
        options={ttsSeeds.map((seed) => ({
          displayText: seed.name,
          value: seed.name,
        }))}
        onSelected={(newValue) => act('select_voice', { seed: newValue })}
      />
      <CyberColorButton
        buttonLabel="Выбрать цвет"
        color={String(value(data, 'voice_color') ?? 'c8c8c8')}
        icon="palette"
        label="Цвет голоса ТТС"
        onClick={() =>
          act('set_color_preference', {
            preference: 'voice_color',
          })
        }
      />
    </>
  );

  const renderControls = (controls: AppearanceControl[]) => {
    const availableControls = controls
      .map((control) => renderAppearanceControl(data, serverData, act, control))
      .filter(Boolean);

    return availableControls.length ? (
      availableControls
    ) : (
      <div className="CharacterSetup__localNote">
        У текущего вида нет активной настройки для этой визуальной категории.
      </div>
    );
  };

  const renderSelectedCategoryPanel = () => {
    if (selectedAppearanceCategory.id === 'body') {
      return renderBodyPanel();
    }

    if (selectedAppearanceCategory.id === 'sensory') {
      return (
        <>
          {renderVoicePanel()}
          <CyberSectionHeader>Глаза</CyberSectionHeader>
          {renderControls(eyeControls)}
        </>
      );
    }

    return renderControls(selectedAppearanceCategory.controls);
  };

  return (
    <div className="CharacterSetup__layout CharacterSetup__layout--data">
      {speciesModalOpen && serverData?.species && (
        <SpeciesPickerModal
          currentSpeciesKey={currentSpeciesKey}
          previewId={data.character_preview_view}
          species={serverData.species}
          onClose={() => setSpeciesModalOpen(false)}
          onSelect={(newSpecies) => {
            setPreference(act, 'species', newSpecies);
            setSpeciesModalOpen(false);
          }}
        />
      )}

      <CyberPanel
        className="CharacterSetup__dataSidePanel"
        title="A. Личные данные"
        scrollable
      >
        <CyberInput
          icon="user"
          label="Полное имя"
          value={currentName}
          onChange={(newValue) => setPreference(act, nameKey, newValue)}
        />
        <CyberSlider
          icon="calendar"
          label="Возраст"
          max={ageConfig.maximum}
          min={ageConfig.minimum}
          step={ageConfig.step}
          value={numberValue(data, 'age', ageConfig.minimum)}
          onChange={(newValue) => setPreference(act, 'age', newValue)}
        />
        <CyberTextarea
          height={180}
          icon="message"
          label="Flavor / описание"
          value={String(value(data, 'flavor_text') ?? '')}
          onChange={(newValue) => setPreference(act, 'flavor_text', newValue)}
        />
        <CyberTextarea
          disabled
          height={95}
          hint="Доработка"
          icon="comments"
          label="Слухи"
          value="Доработка"
        />

        <div className="CharacterSetup__leftBottom">
          <CyberSectionHeader>Быстрые действия</CyberSectionHeader>
          <div className="CharacterSetup__summaryActions">
            <CyberButton
              icon="dice"
              onClick={() => act('randomize_name', { preference: nameKey })}
            >
              Случайное имя
            </CyberButton>
            <CyberButton icon="wand-magic-sparkles" onClick={() => act('randomize_appearance_only')}>
              Случайная внешность
            </CyberButton>
          </div>
        </div>
      </CyberPanel>

      <CyberPanel
        className="CharacterSetup__centerPanel"
        title="Внешний вид"
        buttons={
          <>
            <Button
              icon="rotate-left"
              tooltip="Повернуть против часовой"
              onClick={() => act('rotate', { rotation: 90 })}
            />
            <Button
              icon="rotate-right"
              tooltip="Повернуть по часовой"
              onClick={() => act('rotate', { rotation: -90 })}
            />
          </>
        }
      >
        <CharacterPaperdollHub
          compact
          key={`${data.character_preview_view}-${currentSpeciesKey}`}
          previewId={data.character_preview_view}
          selectedSlot={selectedCategory}
          slots={appearanceCategories}
          onSelectSlot={setSelectedCategory}
        />
        <div className="CharacterSetup__appearanceEditor">
          <CyberSectionHeader>
            {selectedAppearanceCategory.label}
          </CyberSectionHeader>
          {renderSelectedCategoryPanel()}
        </div>
      </CyberPanel>

      <CyberPanel
        className="CharacterSetup__dataSidePanel"
        title="B. Масштаб и описания"
        scrollable
      >
        <CyberSectionHeader>Масштаб спрайта</CyberSectionHeader>
        <CyberSlider
          icon="expand"
          label="Размер спрайта"
          max={spriteSizeConfig.maximum}
          min={spriteSizeConfig.minimum}
          step={spriteSizeConfig.step}
          value={numberValue(data, 'sprite_size', 1)}
          onChange={(newValue) => setPreference(act, 'sprite_size', newValue)}
        />
        <CyberSlider
          icon="arrows-up-down"
          label="Высота спрайта"
          max={spriteHeightConfig.maximum}
          min={spriteHeightConfig.minimum}
          step={spriteHeightConfig.step}
          value={numberValue(data, 'sprite_height', 1)}
          onChange={(newValue) => setPreference(act, 'sprite_height', newValue)}
        />
        <CyberSlider
          icon="arrows-left-right"
          label="Ширина спрайта"
          max={spriteWidthConfig.maximum}
          min={spriteWidthConfig.minimum}
          step={spriteWidthConfig.step}
          value={numberValue(data, 'sprite_width', 1)}
          onChange={(newValue) => setPreference(act, 'sprite_width', newValue)}
        />

        <CyberSectionHeader>Инкогнито</CyberSectionHeader>
        <CyberSelect
          icon="user-secret"
          label="Описание 1"
          value={String(value(data, 'incognito_adjective') ?? '')}
          options={getChoiceOptions(serverData, 'incognito_adjective')}
          onSelected={(newValue) => setPreference(act, 'incognito_adjective', newValue)}
        />
        <CyberSelect
          icon="user-secret"
          label="Описание 2"
          value={String(value(data, 'incognito_noun') ?? '')}
          options={getChoiceOptions(serverData, 'incognito_noun')}
          onSelected={(newValue) => setPreference(act, 'incognito_noun', newValue)}
        />

        <CyberSectionHeader>Описание голоса</CyberSectionHeader>
        <CyberSelect
          icon="comment-dots"
          label="Голос 1"
          value={String(value(data, 'voice_adjective') ?? '')}
          options={getChoiceOptions(serverData, 'voice_adjective')}
          onSelected={(newValue) => setPreference(act, 'voice_adjective', newValue)}
        />
        <CyberSelect
          icon="comment-dots"
          label="Голос 2"
          value={String(value(data, 'voice_noun') ?? '')}
          options={getChoiceOptions(serverData, 'voice_noun')}
          onSelected={(newValue) => setPreference(act, 'voice_noun', newValue)}
        />

        <CyberSectionHeader>
          Дескрипторы куклы {selectedDescriptorCount}/4
        </CyberSectionHeader>
        {selectedDescriptorCount < 4 && (
          <div className="CharacterSetup__warning">
            Нужно выбрать четыре определения.
          </div>
        )}
        {descriptorKeys.map((descriptorKey) => (
          <CyberSelect
            key={descriptorKey}
            icon="tag"
            label="Дескриптор"
            value={String(value(data, descriptorKey) ?? '')}
            options={getChoiceOptions(serverData, descriptorKey)}
            onSelected={(newValue) => setPreference(act, descriptorKey, newValue)}
          />
        ))}

        <div className="CharacterSetup__rightBottom">
          <CyberSectionHeader>Нейроинтерфейс</CyberSectionHeader>
          <CyberSelect
            icon="network-wired"
            label="Корпорация"
            value={String(value(data, 'corp_align') ?? 'none')}
            options={getChoiceOptions(serverData, 'corp_align')}
            onSelected={(newValue) => setPreference(act, 'corp_align', newValue)}
          />
        </div>
      </CyberPanel>
    </div>
  );
}
