import { Suspense, useEffect, useState } from 'react';
import { Button, Stack } from 'tgui-core/components';
import { exhaustiveCheck } from 'tgui-core/exhaustive';
import { fetchRetry } from 'tgui-core/http';

import { resolveAsset } from '../../assets';
import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { logger } from '../../logging';
import { LoadingScreen } from '../common/LoadingScreen';
import { CharacterPreferenceWindow } from './CharacterPreferences';
import { GamePreferenceWindow } from './GamePreferences';
import {
  GamePreferencesSelectedPage,
  type PreferencesMenuData,
  PrefsWindow,
  type ServerData,
} from './types';
import { RandomToggleState } from './useRandomToggleState';
import { ServerPrefs } from './useServerPrefs';

export function PreferencesMenu() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const { window } = data;

  const [title, setTitle] = useState('Настройки');
  const isCharacterWindow = window === PrefsWindow.Character;

  return (
    <Window
      width={1120}
      height={760}
      title={title}
      theme="ss220"
      buttons={
        <Stack g={0.5} align="center">
          <Stack.Item>
            <Button
              className="PreferencesMenu__WindowSwitch"
              icon={isCharacterWindow ? 'cog' : 'user'}
              tooltip={isCharacterWindow ? 'Настройки игры' : 'Настройки персонажа'}
              tooltipPosition="bottom-start"
              onClick={() => act('change_preferences_window')}
            />
          </Stack.Item>
        </Stack>
      }
    >
      <Window.Content
        fitted
        className="PreferencesMenu PreferencesMenu--BandaCyber"
      >
        <Suspense fallback={<LoadingScreen />}>
          <PrefsWindowInner setTitle={setTitle} />
        </Suspense>
      </Window.Content>
    </Window>
  );
}

/** We're abstracting this by one level to use Suspense */
function PrefsWindowInner(props) {
  const { data } = useBackend<PreferencesMenuData>();
  const { window } = data;

  const [serverData, setServerData] = useState<ServerData>();
  const randomization = useState(false);

  useEffect(() => {
    fetchRetry(resolveAsset('preferences.json'))
      .then((response) => response.json())
      .then((data) => {
        setServerData(data);
      })
      .catch((error) => {
        logger.log('Failed to fetch preferences.json', error);
      });
  }, []);

  let content;
  let title;
  switch (window) {
    case PrefsWindow.Character:
      title = 'Настройки персонажа';
      content = <CharacterPreferenceWindow />;
      break;
    case PrefsWindow.Game:
      title = 'Настройки игры';
      content = <GamePreferenceWindow />;
      break;
    case PrefsWindow.Keybindings:
      title = 'Клавиши управления';
      content = (
        <GamePreferenceWindow
          startingPage={GamePreferencesSelectedPage.Keybindings}
        />
      );
      break;
    default:
      exhaustiveCheck(window);
  }

  useEffect(() => {
    props.setTitle(title);
  }, [window]);

  return (
    <ServerPrefs.Provider value={serverData}>
      <RandomToggleState.Provider value={randomization}>
        {content}
      </RandomToggleState.Provider>
    </ServerPrefs.Provider>
  );
}
