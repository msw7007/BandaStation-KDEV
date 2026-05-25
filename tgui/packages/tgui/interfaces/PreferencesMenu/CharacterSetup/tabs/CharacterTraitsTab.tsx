import { useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { CharacterPreview } from 'tgui/interfaces/common/CharacterPreview';

import type { Personality, PreferencesMenuData, Quirk } from '../../types';
import { useServerPrefs } from '../../useServerPrefs';
import { CyberButton, CyberSearch } from '../components/CyberInput';
import { CyberPanel, CyberSectionHeader } from '../components/CyberPanel';
import { QuirkCard } from '../components/QuirkCard';
import { TraitCard } from '../components/TraitCard';

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

  const personalities = useMemo(() => {
    const query = personalitySearch.toLowerCase();
    return (serverData?.personality.personalities || []).filter((personality) =>
      `${personality.name} ${personality.description}`.toLowerCase().includes(query),
    );
  }, [personalitySearch, serverData]);

  const quirks = serverData?.quirks.quirk_info || {};
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

  const maxPositive = serverData?.quirks.max_positive_quirks ?? 2;
  const positiveSelected = selectedQuirks.filter((key) => quirks[key]?.value > 0).length;
  let quirkBalance = -data.default_quirk_balance;
  for (const key of selectedQuirks) {
    quirkBalance += quirks[key]?.value || 0;
  }

  function canAddQuirk(key: string) {
    const quirk = quirks[key];
    if (!quirk) {
      return 'Неизвестная черта.';
    }
    if (quirk.value > 0 && maxPositive !== -1 && positiveSelected >= maxPositive) {
      return 'Лимит положительных quirks: 2.';
    }
    if (serverData?.quirks.points_enabled && quirkBalance + quirk.value > 0) {
      return 'Нужна отрицательная черта для баланса очков.';
    }
    if (data.species_disallowed_quirks.includes(quirk.name)) {
      return 'Несовместимо с выбранным видом.';
    }
    return null;
  }

  return (
    <div className="CharacterSetup__layout">
      <CyberPanel title="A. Личностные черты" scrollable>
        <CyberSearch
          placeholder="Поиск черты..."
          value={personalitySearch}
          onChange={setPersonalitySearch}
        />
        {personalities.map((personality) => {
          const selected = selectedPersonalities.includes(personality.path);
          const disabled =
            !selected &&
            data.max_personalities !== -1 &&
            selectedPersonalities.length >= data.max_personalities;
          return (
            <TraitCard
              key={personality.path}
              disabled={disabled}
              icon={personalityIcon(personality)}
              name={personality.name}
              description={personality.description}
              selected={selected}
              positive={personality.pos_gameplay_description}
              negative={personality.neg_gameplay_description}
              onClick={() =>
                act('handle_personality', {
                  personality_type: personality.path,
                })
              }
            />
          );
        })}
        <CyberButton danger icon="rotate-left" onClick={() => act('clear_personalities')}>
          Сбросить все личностные черты
        </CyberButton>
      </CyberPanel>

      <CyberPanel className="CharacterSetup__centerPanel" title="Сводка персонажа" scrollable>
        <div className="CharacterSetup__summary">
          <CharacterPreview height="240px" id={data.character_preview_view} />
          <div>
            <h2>{data.character_profiles[data.active_slot - 1] || 'Новый персонаж'}</h2>
            <span>Возраст: {String(data.character_preferences.non_contextual.age || '')}</span>
            <span>Личностные черты: {selectedPersonalities.length}/{data.max_personalities}</span>
            <span>Quirks: {selectedQuirks.length}</span>
            <span>Положительные quirks: {positiveSelected}/{maxPositive}</span>
            <span>Баланс quirks: {quirkBalance}</span>
          </div>
        </div>
        <CyberSectionHeader>Выбранные личностные черты</CyberSectionHeader>
        <div className="CharacterSetup__chipList">
          {selectedPersonalities.map((path) => {
            const personality = serverData?.personality.personalities.find(
              (entry) => entry.path === path,
            );
            return <span key={path}>{personality?.name || path}</span>;
          })}
        </div>
        <CyberSectionHeader>Выбранные TG quirks</CyberSectionHeader>
        <div className="CharacterSetup__chipList">
          {selectedQuirks.map((key) => (
            <span key={key} className={quirks[key] && quirkValueClass(quirks[key])}>
              {quirks[key]?.name || key}
            </span>
          ))}
        </div>
        <div className="CharacterSetup__summaryActions">
          <CyberButton disabled icon="dice">
            Случайный характер
          </CyberButton>
          <CyberButton disabled icon="check">
            Применить характер
          </CyberButton>
        </div>
      </CyberPanel>

      <CyberPanel title="B. Браузер quirks (TG)" scrollable>
        <CyberSearch
          placeholder="Поиск quirks..."
          value={quirkSearch}
          onChange={setQuirkSearch}
        />
        <div className="CharacterSetup__quirkCounters">
          <span>Очки: {quirkBalance}</span>
          <span>Положительные: {positiveSelected}/{maxPositive}</span>
          <span>Лимит персонализаций: 3</span>
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
      </CyberPanel>
    </div>
  );
}

