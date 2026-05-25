import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Button, Dropdown, Icon } from 'tgui-core/components';

import type { PreferencesMenuData } from './types';
import { CyberTabs, type CyberTab } from './CharacterSetup/components/CyberTabs';
import { CharacterTab } from './CharacterSetup/tabs/CharacterTab';
import { CharacterTraitsTab } from './CharacterSetup/tabs/CharacterTraitsTab';
import { DataTab } from './CharacterSetup/tabs/DataTab';
import { EquipmentTab } from './CharacterSetup/tabs/EquipmentTab';
import { RolesTab } from './CharacterSetup/tabs/RolesTab';

const tabs: CyberTab[] = [
  { id: 'data', label: 'Информация', icon: 'user' },
  { id: 'character', label: 'Персонаж', icon: 'person-running' },
  { id: 'equipment', label: 'Снаряжение', icon: 'briefcase' },
  { id: 'roles', label: 'Роли', icon: 'users' },
  { id: 'traits', label: 'Характер', icon: 'heart' },
];

export function CharacterSetupWindow() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const [activeTab, setActiveTab] = useState('data');
  const currentProfile =
    data.character_profiles[data.active_slot - 1] || 'Новый персонаж';

  let content;
  switch (activeTab) {
    case 'data':
      content = <DataTab />;
      break;
    case 'character':
      content = <CharacterTab />;
      break;
    case 'equipment':
      content = <EquipmentTab />;
      break;
    case 'roles':
      content = <RolesTab />;
      break;
    case 'traits':
      content = <CharacterTraitsTab />;
      break;
    default:
      content = <DataTab />;
  }

  return (
    <div className="CharacterSetup">
      <header className="CharacterSetup__topbar">
        <div className="CharacterSetup__brand">
          <Icon name="hexagon-nodes" />
          <div>
            <b>Настройки персонажа</b>
            <span>Space Station 13</span>
          </div>
        </div>
        <CyberTabs activeTab={activeTab} tabs={tabs} onSelect={setActiveTab} />
        <div className="CharacterSetup__topActions">
          <Dropdown
            buttons
            displayText={currentProfile}
            selected={String(data.active_slot)}
            options={data.character_profiles.map((profile, index) => ({
              displayText: profile || `Новый персонаж ${index + 1}`,
              value: String(index + 1),
            }))}
            onSelected={(slot) => act('change_slot', { slot: Number(slot) })}
          />
          <Button icon="cog" onClick={() => act('change_preferences_window')} />
        </div>
      </header>
      <main className="CharacterSetup__content">{content}</main>
    </div>
  );
}
