import { useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { CharacterPreview } from 'tgui/interfaces/common/CharacterPreview';
import { Button, Icon, Tooltip } from 'tgui-core/components';

import {
  type Personality,
  type PreferencesMenuData,
  type Quirk,
  RandomSetting,
} from '../../types';
import { useServerPrefs } from '../../useServerPrefs';
import { PreferenceList } from '../../CharacterPreferences/MainPage';
import { CyberSearch } from '../components/CyberInput';
import { CyberPanel, CyberSectionHeader } from '../components/CyberPanel';
import { QuirkCard } from '../components/QuirkCard';

function personalityIcon(personality: Personality) {
  const text = `${personality.name} ${(personality.groups || []).join(' ')}`.toLowerCase();
  if (/спорт|athlet|body/.test(text)) {
    return 'person-running';
  }
  if (/read|book|чита/.test(text)) {
    return 'book-open';
  }
  if (/food|gourmet|гурман/.test(text)) {
    return 'utensils';
  }
  if (/panic|fear|паник/.test(text)) {
    return 'triangle-exclamation';
  }
  return 'diamond';
}

function quirkValueClass(quirk: Quirk) {
  if (quirk.value > 0) {
    return 'positive';
  }
  if (quirk.value < 0) {
    return 'negative';
  }
  return 'neutral';
}

function getCustomizationPreferences(
  quirk: Quirk,
  preferences: Record<string, unknown>,
) {
  if (!quirk.customizable || !quirk.customization_options?.length) {
    return {};
  }

  return Object.fromEntries(
    Object.entries(preferences).filter(([key]) =>
      quirk.customization_options?.includes(key),
    ),
  );
}

export function CharacterTraitsTab() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const serverData = useServerPrefs();
  const [personalitySearch, setPersonalitySearch] = useState('');
  const [quirkSearch, setQuirkSearch] = useState('');
  const [quirkMode, setQuirkMode] = useState<'available' | 'selected' | 'all'>(
    'available',
  );

  const selectedPersonalities = data.selected_personalities || [];
  const selectedQuirks = data.selected_quirks || [];
  const allPersonalities = serverData?.personality.personalities || [];
  const quirks = serverData?.quirks.quirk_info || {};
  const randomBodyEnabled =
    data.character_preferences.non_contextual.random_body !== RandomSetting.Disabled;

  const personalities = useMemo(() => {
    const query = personalitySearch.toLowerCase();
    return allPersonalities.filter((personality) =>
      [
        personality.name,
        personality.description,
        personality.pos_gameplay_description,
        personality.neg_gameplay_description,
        personality.neut_gameplay_description,
      ]
        .join(' ')
        .toLowerCase()
        .includes(query),
    );
  }, [allPersonalities, personalitySearch]);

  const quirkEntries = Object.entries(quirks).filter(([key, quirk]) => {
    const selected = selectedQuirks.includes(key);
    if (quirkMode === 'available' && selected) {
      return false;
    }
    if (quirkMode === 'selected' && !selected) {
      return false;
    }
    const query = quirkSearch.toLowerCase();
    return `${quirk.name} ${quirk.description}`.toLowerCase().includes(query);
  });

  const selectedPersonalityDetails = selectedPersonalities
    .map((path) => allPersonalities.find((personality) => personality.path === path))
    .filter((personality): personality is Personality => !!personality);

  const maxPositive = serverData?.quirks.max_positive_quirks ?? 2;
  const positiveSelected = selectedQuirks.filter((key) => quirks[key]?.value > 0).length;
  let selectedQuirkCost = 0;
  for (const key of selectedQuirks) {
    selectedQuirkCost += quirks[key]?.value || 0;
  }
  const availableQuirkPoints = data.default_quirk_balance - selectedQuirkCost;
  const displayedQuirkBalance = -selectedQuirkCost;

  function canAddQuirk(key: string) {
    const quirk = quirks[key];
    if (!quirk) {
      return 'Неизвестная черта.';
    }
    if (quirk.value > 0 && maxPositive !== -1 && positiveSelected >= maxPositive) {
      return 'Лимит положительных quirks: 2.';
    }
    if (serverData?.quirks.points_enabled && availableQuirkPoints - quirk.value < 0) {
      return 'Нужна отрицательная черта для баланса очков.';
    }
    if (data.species_disallowed_quirks.includes(quirk.name)) {
      return 'Несовместимо с выбранным видом.';
    }
    return null;
  }

  function canAddPersonality(personality: Personality) {
    if (
      data.max_personalities !== -1 &&
      selectedPersonalities.length >= data.max_personalities
    ) {
      return true;
    }
    const incompatibilities = serverData?.personality.personality_incompatibilities || {};
    for (const group of personality.groups || []) {
      const incompatible = incompatibilities[group] || [];
      if (selectedPersonalities.some((selected) => incompatible.includes(selected))) {
        return true;
      }
    }
    return false;
  }

  function getCustomizationRandomizations(preferences: Record<string, unknown>) {
    if (!randomBodyEnabled || !serverData) {
      return {};
    }

    return Object.fromEntries(
      Object.keys(preferences)
        .filter((key) => serverData.random.randomizable.includes(key))
        .map((key) => [
          key,
          data.character_preferences.randomization[key] || RandomSetting.Disabled,
        ]),
    );
  }

  function personalityTooltip(personality: Personality) {
    return (
      <div className="CharacterSetup__personalityTooltip">
        <b>{personality.name}</b>
        {!!personality.description && <p>{personality.description}</p>}
        {!!personality.pos_gameplay_description && (
          <em className="good">+ {personality.pos_gameplay_description}</em>
        )}
        {!!personality.neg_gameplay_description && (
          <em className="bad">- {personality.neg_gameplay_description}</em>
        )}
        {!!personality.neut_gameplay_description && (
          <em>± {personality.neut_gameplay_description}</em>
        )}
      </div>
    );
  }

  return (
    <div className="CharacterSetup__layout CharacterSetup__traitsLayout">
      <CyberPanel
        className="CharacterSetup__traitsStore CharacterSetup__traitsStore--personalities"
        title="A. Личностные черты"
        buttons={
          <Button
            color="red"
            icon="rotate-left"
            tooltip="Сбросить личностные черты"
            onClick={() => act('clear_personalities')}
          />
        }
        scrollable
      >
        <div className="CharacterSetup__storeTools">
          <CyberSearch
            placeholder="Поиск черты..."
            value={personalitySearch}
            onChange={setPersonalitySearch}
          />
          <span>
            Персонализации: {selectedPersonalities.length}/
            {data.max_personalities === -1 ? '∞' : data.max_personalities}
          </span>
        </div>
        <div className="CharacterSetup__storeList">
          {personalities.map((personality) => {
            const selected = selectedPersonalities.includes(personality.path);
            const disabled = !selected && canAddPersonality(personality);
            return (
              <Tooltip
                key={personality.path}
                content={personalityTooltip(personality)}
                position="bottom"
              >
                <div
                  className={[
                    'CharacterSetup__personalityRow',
                    selected ? 'selected' : '',
                    disabled ? 'disabled' : '',
                  ].join(' ')}
                  role="button"
                  tabIndex={disabled ? -1 : 0}
                  onClick={() =>
                    !disabled && act('handle_personality', {
                      personality_type: personality.path,
                    })
                  }
                  onKeyDown={(event) => {
                    if (disabled || (event.key !== 'Enter' && event.key !== ' ')) {
                      return;
                    }
                    event.preventDefault();
                    act('handle_personality', {
                      personality_type: personality.path,
                    });
                  }}
                >
                  <Icon name={personalityIcon(personality)} />
                  <span>{personality.name}</span>
                </div>
              </Tooltip>
            );
          })}
        </div>
      </CyberPanel>

      <CyberPanel
        className="CharacterSetup__centerPanel CharacterSetup__traitsSummaryPanel"
        title="Сводка персонажа"
      >
        <div className="CharacterSetup__traitsSummary">
          <div className="CharacterSetup__traitsPreview">
            <CharacterPreview
              height="230px"
              id={data.character_preview_view}
              transparent
            />
          </div>
          <div className="CharacterSetup__traitsIdentity">
            <h2>{data.character_profiles[data.active_slot - 1] || 'Новый персонаж'}</h2>
            <span>Возраст: {String(data.character_preferences.non_contextual.age || '')}</span>
            <span>
              Персонализации: {selectedPersonalities.length}/
              {data.max_personalities === -1 ? '∞' : data.max_personalities}
            </span>
            <span>Quirks: {selectedQuirks.length}</span>
            <span>Положительные quirks: {positiveSelected}/{maxPositive}</span>
            <span>Баланс quirks: {displayedQuirkBalance}</span>
          </div>
        </div>

        <div className="CharacterSetup__selectedStacks CharacterSetup__selectedStacks--detailed">
          <section>
            <CyberSectionHeader>Выбранные персонализации</CyberSectionHeader>
            <div className="CharacterSetup__selectedDetailList">
              {selectedPersonalityDetails.length ? (
                selectedPersonalityDetails.map((personality) => (
                  <div
                    key={personality.path}
                    className="CharacterSetup__selectedDetail"
                  >
                    <div className="CharacterSetup__selectedDetailHeader">
                      <Icon name={personalityIcon(personality)} />
                      <b>{personality.name}</b>
                      <button
                        onClick={() =>
                          act('handle_personality', {
                            personality_type: personality.path,
                          })
                        }
                      >
                        ×
                      </button>
                    </div>
                    {!!personality.description && <p>{personality.description}</p>}
                    <div className="CharacterSetup__selectedEffects">
                      {!!personality.pos_gameplay_description && (
                        <em className="good">+ {personality.pos_gameplay_description}</em>
                      )}
                      {!!personality.neg_gameplay_description && (
                        <em className="bad">- {personality.neg_gameplay_description}</em>
                      )}
                      {!!personality.neut_gameplay_description && (
                        <em>± {personality.neut_gameplay_description}</em>
                      )}
                    </div>
                  </div>
                ))
              ) : (
                <em className="CharacterSetup__empty">Пусто</em>
              )}
            </div>
          </section>

          <section>
            <CyberSectionHeader>Выбранные TG quirks</CyberSectionHeader>
            <div className="CharacterSetup__selectedDetailList">
              {selectedQuirks.length ? (
                selectedQuirks.map((key) => {
                  const quirk = quirks[key];
                  if (!quirk) {
                    return (
                      <div key={key} className="CharacterSetup__selectedDetail">
                        <div className="CharacterSetup__selectedDetailHeader">
                          <Icon name="question" />
                          <b>{key}</b>
                          <button onClick={() => act('remove_quirk', { quirk: key })}>
                            ×
                          </button>
                        </div>
                      </div>
                    );
                  }

                  const customizationPreferences = getCustomizationPreferences(
                    quirk,
                    data.character_preferences.manually_rendered_features,
                  );
                  const hasCustomization =
                    Object.entries(customizationPreferences).length > 0;

                  return (
                    <div
                      key={key}
                      className={`CharacterSetup__selectedDetail ${quirkValueClass(quirk)}`}
                    >
                      <div className="CharacterSetup__selectedDetailHeader">
                        <Icon name={quirk.icon || 'diamond'} />
                        <b>{quirk.name}</b>
                        <span>{quirk.value}</span>
                        <button onClick={() => act('remove_quirk', { quirk: quirk.name })}>
                          ×
                        </button>
                      </div>
                      {!!quirk.description && <p>{quirk.description}</p>}
                      {hasCustomization && (
                        <div className="CharacterSetup__quirkCustomization">
                          <CyberSectionHeader>Настройки quirk</CyberSectionHeader>
                          <PreferenceList
                            preferences={customizationPreferences}
                            randomizations={getCustomizationRandomizations(
                              customizationPreferences,
                            )}
                          />
                        </div>
                      )}
                    </div>
                  );
                })
              ) : (
                <em className="CharacterSetup__empty">Пусто</em>
              )}
            </div>
          </section>
        </div>
      </CyberPanel>

      <CyberPanel
        className="CharacterSetup__traitsStore CharacterSetup__traitsStore--quirks"
        title="B. Браузер quirks (TG)"
        scrollable
      >
        <div className="CharacterSetup__storeTools">
          <CyberSearch
            placeholder="Поиск quirks..."
            value={quirkSearch}
            onChange={setQuirkSearch}
          />
        </div>
        <div className="CharacterSetup__quirkCounters">
          <span>Очки: {displayedQuirkBalance}</span>
          <span>Положительные: {positiveSelected}/{maxPositive}</span>
        </div>
        <div className="CharacterSetup__segmented">
          <button
            className={quirkMode === 'available' ? 'active' : ''}
            onClick={() => setQuirkMode('available')}
          >
            Доступные
          </button>
          <button
            className={quirkMode === 'selected' ? 'active' : ''}
            onClick={() => setQuirkMode('selected')}
          >
            Выбранные
          </button>
          <button
            className={quirkMode === 'all' ? 'active' : ''}
            onClick={() => setQuirkMode('all')}
          >
            Все quirks
          </button>
        </div>
        <div className="CharacterSetup__storeList">
          {quirkEntries.map(([key, quirk]) => {
            const selected = selectedQuirks.includes(key);
            const reason = selected ? null : canAddQuirk(key);
            return (
              <QuirkCard
                key={key}
                quirkKey={key}
                quirk={quirk}
                selected={selected}
                disabled={!!reason}
                reason={reason || undefined}
                onClick={() =>
                  selected
                    ? act('remove_quirk', { quirk: quirk.name })
                    : act('give_quirk', { quirk: quirk.name })
                }
              />
            );
          })}
        </div>
      </CyberPanel>
    </div>
  );
}
